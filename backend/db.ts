// ====================================================
// CardGenius Backend: Database Client Utilities
// ====================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

/**
 * Get a Supabase client with service role key (for admin operations)
 * Use this for operations that need to bypass RLS
 */
export function getSupabaseAdminClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

/**
 * Get a Supabase client with user's JWT token (respects RLS)
 * Use this for user-scoped operations
 */
export function getSupabaseClient(authToken: string) {
  return createClient(SUPABASE_URL, Deno.env.get('SUPABASE_ANON_KEY') || '', {
    global: {
      headers: {
        Authorization: `Bearer ${authToken}`,
      },
    },
  });
}

