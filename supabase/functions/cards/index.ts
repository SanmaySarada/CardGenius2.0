// ====================================================
// CardGenius Backend: Cards Edge Function
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
    const pathParts = url.pathname.split('/').filter(Boolean);
    const cardId = pathParts[pathParts.length - 1];

    const supabase = getSupabaseClient(req.headers.get('Authorization')?.replace('Bearer ', '') || '');

    // GET /functions/v1/cards - Fetch all cards for user
    if (req.method === 'GET' && !cardId) {
      const { data: cards, error } = await supabase
        .from('cards')
        .select(`
          *,
          reward_categories (*)
        `)
        .eq('user_id', user.userId)
        .order('routing_priority', { ascending: false })
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      return new Response(
        JSON.stringify({ data: cards }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // GET /functions/v1/cards/:id - Fetch single card
    if (req.method === 'GET' && cardId) {
      const { data: card, error } = await supabase
        .from('cards')
        .select(`
          *,
          reward_categories (*)
        `)
        .eq('id', cardId)
        .eq('user_id', user.userId)
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          return new Response(
            JSON.stringify({ error: { message: 'Card not found', code: 'NOT_FOUND' } }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 404,
            }
          );
        }
        throw error;
      }

      return new Response(
        JSON.stringify({ data: card }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // POST /functions/v1/cards/refresh - Refresh cards from institution
    if (req.method === 'POST' && url.pathname.endsWith('/refresh')) {
      // TODO: Integrate with Plaid/Yodlee to sync cards
      // For now, just return current cards
      const { data: cards, error } = await supabase
        .from('cards')
        .select(`
          *,
          reward_categories (*)
        `)
        .eq('user_id', user.userId)
        .order('updated_at', { ascending: false });

      if (error) {
        throw error;
      }

      return new Response(
        JSON.stringify({ data: cards }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // PUT /functions/v1/cards/:id - Update card
    if (req.method === 'PUT' && cardId) {
      const body = await req.json();

      // Only allow updating specific fields
      const allowedFields = [
        'nickname',
        'is_included_in_optimization',
        'routing_priority',
        'status',
      ];

      const updateData: any = {};
      for (const field of allowedFields) {
        if (body[field] !== undefined) {
          updateData[field] = body[field];
        }
      }

      const { data: card, error } = await supabase
        .from('cards')
        .update(updateData)
        .eq('id', cardId)
        .eq('user_id', user.userId)
        .select(`
          *,
          reward_categories (*)
        `)
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          return new Response(
            JSON.stringify({ error: { message: 'Card not found', code: 'NOT_FOUND' } }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 404,
            }
          );
        }
        throw error;
      }

      return new Response(
        JSON.stringify({ data: card }),
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
    console.error('Error in cards function:', error);
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

