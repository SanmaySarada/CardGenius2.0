// ====================================================
// CardGenius Backend: Admin Tools Edge Function
// ====================================================
// Protected endpoint for importing card reward matrix from CSV
// ====================================================

import { corsHeaders } from '../_shared/cors.ts';
import { getSupabaseAdminClient } from '../_shared/db.ts';

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Verify service role key or API key
    const authHeader = req.headers.get('Authorization');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    
    if (!authHeader || !authHeader.includes(serviceRoleKey || '')) {
      return new Response(
        JSON.stringify({ error: { message: 'Unauthorized', code: 'UNAUTHORIZED' } }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      );
    }

    const url = new URL(req.url);
    const supabase = getSupabaseAdminClient();

    // POST /functions/v1/admin-tools/import-card-reward-matrix - Import CSV data
    if (req.method === 'POST' && url.pathname.endsWith('/import-card-reward-matrix')) {
      const body = await req.json();
      const { csv_data, csv_text } = body;

      if (!csv_data && !csv_text) {
        return new Response(
          JSON.stringify({ error: { message: 'csv_data or csv_text is required', code: 'VALIDATION_ERROR' } }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
      }

      // Parse CSV
      const csvContent = csv_text || (Array.isArray(csv_data) ? csv_data.join('\n') : csv_data);
      const lines = csvContent.split('\n').filter((line: string) => line.trim());

      if (lines.length < 2) {
        return new Response(
          JSON.stringify({ error: { message: 'CSV must have at least a header and one data row', code: 'VALIDATION_ERROR' } }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
      }

      // Parse header (first line)
      const header = lines[0].split(',').map((h: string) => h.trim());
      const cardNameIndex = 0; // First column is card name

      // Parse data rows
      const matrixRows: Array<{ card_name: string; category_name: string; multiplier: number }> = [];

      for (let i = 1; i < lines.length; i++) {
        const values = lines[i].split(',').map((v: string) => v.trim());
        const cardName = values[cardNameIndex];

        if (!cardName) continue;

        // Process each category column
        for (let j = 1; j < header.length && j < values.length; j++) {
          const categoryName = header[j];
          const multiplierStr = values[j];

          if (!categoryName || !multiplierStr) continue;

          const multiplier = parseFloat(multiplierStr);
          if (isNaN(multiplier) || multiplier < 0) continue;

          matrixRows.push({
            card_name: cardName,
            category_name: categoryName,
            multiplier: multiplier,
          });
        }
      }

      if (matrixRows.length === 0) {
        return new Response(
          JSON.stringify({ error: { message: 'No valid data rows found in CSV', code: 'VALIDATION_ERROR' } }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
      }

      // Insert/update matrix rows
      const { data, error } = await supabase
        .from('card_reward_matrix')
        .upsert(matrixRows, {
          onConflict: 'card_name,category_name',
        })
        .select();

      if (error) {
        throw error;
      }

      return new Response(
        JSON.stringify({
          data: {
            message: `Imported ${matrixRows.length} reward matrix entries`,
            imported_count: matrixRows.length,
            entries: data,
          },
        }),
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
    console.error('Error in admin-tools function:', error);
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

