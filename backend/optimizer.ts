// ====================================================
// CardGenius Backend: Optimizer Stub
// TODO: Integrate external MCC → category mapping and optimizer logic
// ====================================================

import { getSupabaseAdminClient } from './db.ts';
import type { Card, Merchant } from './types.ts';

export interface MerchantContext {
  mcc?: string;
  category?: string;
  latitude?: number;
  longitude?: number;
  merchantName?: string;
  merchantId?: string;
}

export interface OptimizedCardResult {
  recommendedCardId: string | null;
  alternativeCardId: string | null;
  reasoning: string[];
}

export interface EstimatedGain {
  yearlyGain: number;
  explanation: string[];
}

/**
 * Get the recommended card for a merchant
 * TODO: Replace with real MCC + optimizer logic from external repo
 */
export async function getRecommendedCardForMerchant(
  userId: string,
  merchant: MerchantContext
): Promise<OptimizedCardResult> {
  const supabase = getSupabaseAdminClient();

  try {
    // Get user's active cards
    const { data: cards, error: cardsError } = await supabase
      .from('cards')
      .select('*, reward_categories(*)')
      .eq('user_id', userId)
      .eq('status', 'active')
      .eq('is_included_in_optimization', true)
      .order('routing_priority', { ascending: false });

    if (cardsError || !cards || cards.length === 0) {
      return {
        recommendedCardId: null,
        alternativeCardId: null,
        reasoning: ['No active cards found for optimization'],
      };
    }

    // Get merchant category
    let merchantCategory = merchant.category;
    if (merchant.merchantId) {
      const { data: merchantData } = await supabase
        .from('merchants')
        .select('category')
        .eq('id', merchant.merchantId)
        .single();

      if (merchantData) {
        merchantCategory = merchantData.category;
      }
    }

    // Simple stub: find card with highest multiplier for this category
    let bestCard: Card | null = null;
    let bestMultiplier = 0;
    let secondBestCard: Card | null = null;
    let secondBestMultiplier = 0;

    for (const card of cards as any[]) {
      const categories = card.reward_categories || [];
      let maxMultiplier = 0;

      for (const cat of categories) {
        if (
          merchantCategory &&
          cat.name.toLowerCase() === merchantCategory.toLowerCase()
        ) {
          maxMultiplier = Math.max(maxMultiplier, Number(cat.multiplier) || 0);
        }
      }

      // Also check "Everywhere" category as fallback
      const everywhereCat = categories.find(
        (c: any) => c.name.toLowerCase() === 'everywhere'
      );
      if (everywhereCat) {
        maxMultiplier = Math.max(
          maxMultiplier,
          Number(everywhereCat.multiplier) || 0
        );
      }

      if (maxMultiplier > bestMultiplier) {
        secondBestCard = bestCard;
        secondBestMultiplier = bestMultiplier;
        bestCard = card;
        bestMultiplier = maxMultiplier;
      } else if (maxMultiplier > secondBestMultiplier) {
        secondBestCard = card;
        secondBestMultiplier = maxMultiplier;
      }
    }

    const reasoning: string[] = [];
    if (bestCard) {
      reasoning.push(
        `Recommended: ${bestCard.issuer} (${bestMultiplier}x rewards for ${merchantCategory || 'this category'})`
      );
    }
    if (secondBestCard) {
      reasoning.push(
        `Alternative: ${secondBestCard.issuer} (${secondBestMultiplier}x rewards)`
      );
    }

    return {
      recommendedCardId: bestCard?.id || null,
      alternativeCardId: secondBestCard?.id || null,
      reasoning: reasoning.length > 0
        ? reasoning
        : ['Stub: no optimizer connected yet'],
    };
  } catch (error) {
    console.error('Error in getRecommendedCardForMerchant:', error);
    return {
      recommendedCardId: null,
      alternativeCardId: null,
      reasoning: ['Error computing recommendation'],
    };
  }
}

/**
 * Get estimated yearly gain from recommendations
 * TODO: Replace with real optimizer logic from external repo
 */
export async function getEstimatedYearlyGain(
  userId: string
): Promise<EstimatedGain> {
  // Stub implementation
  // TODO: integrate external optimizer to calculate actual yearly gain
  // based on user's spending patterns and recommended cards

  return {
    yearlyGain: 0,
    explanation: ['Stub: yearly gain not computed yet'],
  };
}

