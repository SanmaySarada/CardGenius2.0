// ====================================================
// CardGenius Backend: Institutions Edge Function
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

    // GET /functions/v1/institutions/supported - Get all supported institutions
    if (req.method === 'GET' && url.pathname.endsWith('/supported')) {
      const { data: institutions, error } = await adminSupabase
        .from('institutions')
        .select('*')
        .order('name');

      if (error) {
        throw error;
      }

      return new Response(
        JSON.stringify({ data: institutions }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // GET /functions/v1/institutions/linked - Get user's linked institutions
    if (req.method === 'GET' && url.pathname.endsWith('/linked')) {
      const { data: userInstitutions, error } = await supabase
        .from('user_institutions')
        .select(`
          *,
          institutions (*)
        `)
        .eq('user_id', user.userId)
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      return new Response(
        JSON.stringify({ data: userInstitutions }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // POST /functions/v1/institutions/link - Link an institution
    if (req.method === 'POST' && url.pathname.endsWith('/link')) {
      const body = await req.json();
      const { institution_id } = body;

      if (!institution_id) {
        return new Response(
          JSON.stringify({ error: { message: 'institution_id is required', code: 'VALIDATION_ERROR' } }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
      }

      // TODO: Integrate with Plaid link token exchange
      // For now, create/update user_institution with status 'linked'
      const { data: userInstitution, error } = await supabase
        .from('user_institutions')
        .upsert({
          user_id: user.userId,
          institution_id,
          status: 'linked',
        }, {
          onConflict: 'user_id,institution_id',
        })
        .select(`
          *,
          institutions (*)
        `)
        .single();

      if (error) {
        throw error;
      }

      // TODO: Trigger card sync from institution
      // For now, just return the linked institution

      return new Response(
        JSON.stringify({ data: userInstitution }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // POST /functions/v1/institutions/unlink - Unlink an institution
    if (req.method === 'POST' && url.pathname.endsWith('/unlink')) {
      const body = await req.json();
      const { user_institution_id } = body;

      if (!user_institution_id) {
        return new Response(
          JSON.stringify({ error: { message: 'user_institution_id is required', code: 'VALIDATION_ERROR' } }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
      }

      // TODO: Revoke access token with Plaid
      // For now, update status to 'not_linked' and clear token
      const { data: userInstitution, error } = await supabase
        .from('user_institutions')
        .update({
          status: 'not_linked',
          external_access_token: null,
        })
        .eq('id', user_institution_id)
        .eq('user_id', user.userId)
        .select(`
          *,
          institutions (*)
        `)
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          return new Response(
            JSON.stringify({ error: { message: 'Institution link not found', code: 'NOT_FOUND' } }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 404,
            }
          );
        }
        throw error;
      }

      return new Response(
        JSON.stringify({ data: userInstitution }),
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
    console.error('Error in institutions function:', error);
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

