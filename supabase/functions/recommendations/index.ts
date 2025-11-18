// ====================================================
// CardGenius Backend: Recommendations Edge Function
// ====================================================

import { corsHeaders } from '../_shared/cors.ts';
import { getUserFromRequest, createAuthErrorResponse } from '../_shared/auth.ts';
import { getSupabaseClient, getSupabaseAdminClient } from '../_shared/db.ts';
import { getEstimatedYearlyGain } from '../_shared/optimizer.ts';

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
    const pathParts = url.pathname.split('/').filter(Boolean);
    const recommendationId = pathParts[pathParts.length - 1];
    const supabase = getSupabaseClient(req.headers.get('Authorization')?.replace('Bearer ', '') || '');

    // GET /functions/v1/recommendations - Get all non-dismissed recommendations
    if (req.method === 'GET' && !recommendationId) {
      const { data: recommendations, error } = await supabase
        .from('card_recommendations')
        .select('*')
        .eq('user_id', user.userId)
        .eq('is_dismissed', false)
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      return new Response(
        JSON.stringify({ data: recommendations || [] }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // GET /functions/v1/recommendations/estimated-gain - Get estimated yearly gain
    if (req.method === 'GET' && url.pathname.endsWith('/estimated-gain')) {
      const result = await getEstimatedYearlyGain(user.userId);

      return new Response(
        JSON.stringify({
          data: {
            yearlyGain: result.yearlyGain,
            explanation: result.explanation,
          },
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // POST /functions/v1/recommendations/:id/dismiss - Dismiss a recommendation
    if (req.method === 'POST' && recommendationId && url.pathname.endsWith('/dismiss')) {
      const { data: recommendation, error } = await supabase
        .from('card_recommendations')
        .update({ is_dismissed: true })
        .eq('id', recommendationId)
        .eq('user_id', user.userId)
        .select()
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          return new Response(
            JSON.stringify({ error: { message: 'Recommendation not found', code: 'NOT_FOUND' } }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 404,
            }
          );
        }
        throw error;
      }

      return new Response(
        JSON.stringify({ data: recommendation }),
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
    console.error('Error in recommendations function:', error);
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

