// ====================================================
// CardGenius Backend: Rewards Edge Function
// ====================================================

import { corsHeaders } from '../_shared/cors.ts';
import { getUserFromRequest, createAuthErrorResponse } from '../_shared/auth.ts';
import { getSupabaseClient, getSupabaseAdminClient } from '../_shared/db.ts';

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const user = await getUserFromRequest(req);
    if (!user) {
      return createAuthErrorResponse();
    }

    const url = new URL(req.url);
    const supabase = getSupabaseClient(req.headers.get('Authorization')?.replace('Bearer ', '') || '');
    const adminSupabase = getSupabaseAdminClient();

    // GET /functions/v1/rewards/summary - Get rewards summary for current user
    if (req.method === 'GET' && url.pathname.endsWith('/summary')) {
      // Get or create current month summary
      const now = new Date();
      const periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
      const periodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);

      // Get current month summary
      let { data: summary, error: summaryError } = await supabase
        .from('rewards_summaries')
        .select('*')
        .eq('user_id', user.userId)
        .eq('period_start', periodStart.toISOString().split('T')[0])
        .eq('period_end', periodEnd.toISOString().split('T')[0])
        .single();

      // If no summary exists, calculate it
      if (summaryError && summaryError.code === 'PGRST116') {
        // Calculate from transactions
        await calculateRewardsSummary(adminSupabase, user.userId, periodStart, periodEnd);
        
        // Fetch the created summary
        const { data: newSummary } = await supabase
          .from('rewards_summaries')
          .select('*')
          .eq('user_id', user.userId)
          .eq('period_start', periodStart.toISOString().split('T')[0])
          .eq('period_end', periodEnd.toISOString().split('T')[0])
          .single();
        summary = newSummary;
      }

      if (!summary) {
        return new Response(
          JSON.stringify({ error: { message: 'Summary not found', code: 'NOT_FOUND' } }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 404,
          }
        );
      }

      // Get monthly breakdown (last 6 months)
      const { data: monthlyRewards } = await supabase
        .from('monthly_rewards')
        .select('*')
        .eq('rewards_summary_id', summary.id)
        .order('month', { ascending: false })
        .limit(6);

      // Get category breakdown
      const { data: categoryRewards } = await supabase
        .from('category_rewards')
        .select('*')
        .eq('rewards_summary_id', summary.id);

      // Get card contributions
      const { data: cardContributions } = await supabase
        .from('card_contributions')
        .select(`
          *,
          cards (*)
        `)
        .eq('rewards_summary_id', summary.id);

      // Get optimization wins
      const { data: optimizationWins } = await supabase
        .from('optimization_wins')
        .select('*')
        .eq('user_id', user.userId)
        .order('occurred_at', { ascending: false })
        .limit(10);

      // Get previous month points for percentage calculation
      const previousMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const previousMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0);
      
      const { data: previousSummary } = await supabase
        .from('rewards_summaries')
        .select('current_month_points')
        .eq('user_id', user.userId)
        .eq('period_start', previousMonthStart.toISOString().split('T')[0])
        .eq('period_end', previousMonthEnd.toISOString().split('T')[0])
        .single();

      const response = {
        ...summary,
        monthly_breakdown: monthlyRewards || [],
        category_breakdown: categoryRewards || [],
        card_contributions: cardContributions || [],
        optimizations: optimizationWins || [],
        previous_month_points: previousSummary?.current_month_points || 0,
      };

      return new Response(
        JSON.stringify({ data: response }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // GET /functions/v1/rewards/history - Get historical rewards
    if (req.method === 'GET' && url.pathname.endsWith('/history')) {
      const { data: summaries, error } = await supabase
        .from('rewards_summaries')
        .select('*')
        .eq('user_id', user.userId)
        .order('period_start', { ascending: false })
        .limit(12);

      if (error) {
        throw error;
      }

      return new Response(
        JSON.stringify({ data: summaries }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // POST /functions/v1/rewards/recalculate - Recalculate rewards
    if (req.method === 'POST' && url.pathname.endsWith('/recalculate')) {
      const now = new Date();
      const periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
      const periodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);

      await calculateRewardsSummary(adminSupabase, user.userId, periodStart, periodEnd);

      return new Response(
        JSON.stringify({ data: { message: 'Rewards recalculated' } }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    return new Response(
      JSON.stringify({ error: { message: 'Method not allowed', code: 'METHOD_NOT_ALLOWED' } }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 405,
      }
    );
  } catch (error) {
    console.error('Error in rewards function:', error);
    return new Response(
      JSON.stringify({
        error: {
          message: error instanceof Error ? error.message : 'Internal server error',
          code: 'INTERNAL_ERROR',
        },
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

// Helper function to calculate rewards summary from transactions
async function calculateRewardsSummary(
  supabase: any,
  userId: string,
  periodStart: Date,
  periodEnd: Date
) {
  // Get all transactions for the period
  const { data: transactions, error: txError } = await supabase
    .from('transactions')
    .select('*, cards(*, reward_categories(*))')
    .eq('user_id', userId)
    .gte('transacted_at', periodStart.toISOString())
    .lte('transacted_at', periodEnd.toISOString());

  if (txError) {
    throw txError;
  }

  let totalPoints = 0;
  let totalValue = 0;
  const categoryPoints: Record<string, number> = {};
  const cardPoints: Record<string, { points: number; tagline: string }> = {};

  // Calculate points from transactions
  transactions?.forEach((tx: any) => {
    if (tx.points_earned) {
      totalPoints += Number(tx.points_earned) || 0;
      totalValue += (Number(tx.points_earned) || 0) * 0.01; // Assume 1 point = $0.01

      // Category breakdown
      if (tx.category) {
        categoryPoints[tx.category] = (categoryPoints[tx.category] || 0) + (Number(tx.points_earned) || 0);
      }

      // Card contributions
      if (tx.card_id) {
        if (!cardPoints[tx.card_id]) {
          cardPoints[tx.card_id] = { points: 0, tagline: tx.cards?.issuer || 'Card' };
        }
        cardPoints[tx.card_id].points += Number(tx.points_earned) || 0;
      }
    }
  });

  // Upsert summary
  const { data: summary, error: summaryError } = await supabase
    .from('rewards_summaries')
    .upsert({
      user_id: userId,
      period_start: periodStart.toISOString().split('T')[0],
      period_end: periodEnd.toISOString().split('T')[0],
      current_month_points: totalPoints,
      current_month_value: totalValue,
    }, {
      onConflict: 'user_id,period_start,period_end',
    })
    .select()
    .single();

  if (summaryError) {
    throw summaryError;
  }

  // Insert category rewards
  const categoryRewards = Object.entries(categoryPoints).map(([category, points]) => ({
    rewards_summary_id: summary.id,
    category,
    points,
    percentage: totalPoints > 0 ? (points / totalPoints) * 100 : 0,
  }));

  if (categoryRewards.length > 0) {
    await supabase.from('category_rewards').delete().eq('rewards_summary_id', summary.id);
    await supabase.from('category_rewards').insert(categoryRewards);
  }

  // Insert card contributions
  const contributions = Object.entries(cardPoints).map(([cardId, data]) => ({
    rewards_summary_id: summary.id,
    card_id: cardId,
    points: data.points,
    tagline: data.tagline,
  }));

  if (contributions.length > 0) {
    await supabase.from('card_contributions').delete().eq('rewards_summary_id', summary.id);
    await supabase.from('card_contributions').insert(contributions);
  }

  // Insert monthly reward entry
  await supabase.from('monthly_rewards').upsert({
    rewards_summary_id: summary.id,
    month: periodStart.toISOString().split('T')[0],
    points: totalPoints,
    value: totalValue,
  }, {
    onConflict: 'rewards_summary_id,month',
  });
}

