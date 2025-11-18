// ====================================================
// CardGenius Backend: Authentication Utilities
// ====================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { corsHeaders } from './cors.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') || '';

export interface AuthUser {
  userId: string;
  email?: string;
}

/**
 * Get the current user from the Authorization header
 * Returns null if no valid user is found
 */
export async function getUserFromRequest(
  req: Request
): Promise<AuthUser | null> {
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return null;
    }

    const token = authHeader.replace('Bearer ', '');
    if (!token) {
      return null;
    }

    // Create Supabase client to verify JWT
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const {
      data: { user },
      error,
    } = await supabase.auth.getUser(token);

    if (error || !user) {
      return null;
    }

    return {
      userId: user.id,
      email: user.email,
    };
  } catch (error) {
    console.error('Error getting user from request:', error);
    return null;
  }
}

/**
 * Create an error response for authentication failures
 */
export function createAuthErrorResponse(): Response {
  return new Response(
    JSON.stringify({
      error: {
        message: 'Unauthorized',
        code: 'UNAUTHORIZED',
      },
    }),
    {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

