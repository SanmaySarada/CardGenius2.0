// ====================================================
// CardGenius Backend: Merchants Edge Function
// ====================================================

import { corsHeaders } from '../_shared/cors.ts';
import { getUserFromRequest, createAuthErrorResponse } from '../_shared/auth.ts';
import { getSupabaseClient, getSupabaseAdminClient } from '../_shared/db.ts';
import { getRecommendedCardForMerchant } from '../_shared/optimizer.ts';

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
    const adminSupabase = getSupabaseAdminClient();

    // GET /functions/v1/merchants/nearby - Get nearby merchants
    if (req.method === 'GET' && url.pathname.endsWith('/nearby')) {
      const lat = parseFloat(url.searchParams.get('lat') || '0');
      const lng = parseFloat(url.searchParams.get('lng') || '0');
      const radius = parseFloat(url.searchParams.get('radius') || '5000'); // default 5km

      if (!lat || !lng) {
        return new Response(
          JSON.stringify({ error: { message: 'lat and lng query parameters are required', code: 'VALIDATION_ERROR' } }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
      }

      // Simple radius filter (using haversine approximation)
      // For production, use PostGIS with proper spatial indexing
      const { data: merchants, error } = await adminSupabase
        .from('merchants')
        .select('*')
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);

      if (error) {
        throw error;
      }

      // Filter by distance (simple haversine)
      const nearbyMerchants = merchants?.filter((merchant) => {
        if (!merchant.latitude || !merchant.longitude) return false;
        const distance = calculateDistance(
          lat,
          lng,
          merchant.latitude,
          merchant.longitude
        );
        return distance <= radius;
      }).slice(0, 20) || []; // Limit to 20 results

      return new Response(
        JSON.stringify({ data: nearbyMerchants }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // GET /functions/v1/merchants/current - Get current merchant (nearest to location)
    if (req.method === 'GET' && url.pathname.endsWith('/current')) {
      const lat = parseFloat(url.searchParams.get('lat') || '0');
      const lng = parseFloat(url.searchParams.get('lng') || '0');

      if (!lat || !lng) {
        return new Response(
          JSON.stringify({ error: { message: 'lat and lng query parameters are required', code: 'VALIDATION_ERROR' } }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
      }

      // Get nearest merchant
      const { data: merchants, error } = await adminSupabase
        .from('merchants')
        .select('*')
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);

      if (error) {
        throw error;
      }

      let nearestMerchant = null;
      let minDistance = Infinity;

      merchants?.forEach((merchant) => {
        if (!merchant.latitude || !merchant.longitude) return;
        const distance = calculateDistance(
          lat,
          lng,
          merchant.latitude,
          merchant.longitude
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearestMerchant = merchant;
        }
      });

      return new Response(
        JSON.stringify({ data: nearestMerchant }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // POST /functions/v1/merchants/recommend-card - Get recommended card for merchant
    if (req.method === 'POST' && url.pathname.endsWith('/recommend-card')) {
      const body = await req.json();
      const { merchant_id, lat, lng, mcc, category } = body;

      let merchantContext: any = {
        mcc,
        category,
        latitude: lat,
        longitude: lng,
      };

      // Load merchant if merchant_id provided
      if (merchant_id) {
        const { data: merchant, error: merchantError } = await adminSupabase
          .from('merchants')
          .select('*')
          .eq('id', merchant_id)
          .single();

        if (merchantError) {
          throw merchantError;
        }

        merchantContext = {
          ...merchantContext,
          merchantId: merchant.id,
          merchantName: merchant.name,
          category: merchant.category || category,
          latitude: merchant.latitude || lat,
          longitude: merchant.longitude || lng,
        };
      }

      // Get recommended card using optimizer
      const result = await getRecommendedCardForMerchant(user.userId, merchantContext);

      // Fetch full card objects if IDs are present
      let recommendedCard = null;
      let alternativeCard = null;

      if (result.recommendedCardId) {
        const { data: card } = await adminSupabase
          .from('cards')
          .select('*, reward_categories(*)')
          .eq('id', result.recommendedCardId)
          .single();
        recommendedCard = card;
      }

      if (result.alternativeCardId) {
        const { data: card } = await adminSupabase
          .from('cards')
          .select('*, reward_categories(*)')
          .eq('id', result.alternativeCardId)
          .single();
        alternativeCard = card;
      }

      return new Response(
        JSON.stringify({
          data: {
            recommended_card: recommendedCard,
            alternative_card: alternativeCard,
            reasoning: result.reasoning,
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
    console.error('Error in merchants function:', error);
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

// Simple haversine distance calculation (in meters)
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000; // Earth radius in meters
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) *
      Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

