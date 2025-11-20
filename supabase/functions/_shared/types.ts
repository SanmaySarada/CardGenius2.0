// ====================================================
// CardGenius Backend: TypeScript Types
// ====================================================

export interface ApiResponse<T = any> {
  data?: T;
  error?: {
    message: string;
    code?: string;
  };
}

export interface User {
  id: string;
  email?: string;
  full_name?: string;
}

export interface Card {
  id: string;
  user_id: string;
  institution_id?: string;
  issuer: string;
  nickname?: string;
  last4: string;
  network: 'visa' | 'mastercard' | 'amex' | 'discover' | 'other';
  card_type: 'credit' | 'debit' | 'charge' | 'prepaid' | 'other';
  card_style?: string;
  status: 'active' | 'paused' | 'expired' | 'closed';
  credit_limit?: number;
  current_balance?: number;
  current_month_spend: number;
  is_included_in_optimization: boolean;
  routing_priority: number;
  image_name?: string;
  created_at: string;
  updated_at: string;
}

export interface RewardCategory {
  id: string;
  card_id: string;
  name: string;
  multiplier: number;
  description?: string;
  category_code?: string;
  created_at: string;
}

export interface Institution {
  id: string;
  name: string;
  logo_url?: string;
  provider?: string;
  provider_institution_id?: string;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface UserInstitution {
  id: string;
  user_id: string;
  institution_id: string;
  status: 'not_linked' | 'linking' | 'linked' | 'error';
  external_access_token?: string;
  external_item_id?: string;
  created_at: string;
  updated_at: string;
}

export interface Merchant {
  id: string;
  name: string;
  category: 'dining' | 'groceries' | 'gas' | 'travel' | 'shopping' | 'entertainment' | 'online' | 'other';
  address?: string;
  latitude?: number;
  longitude?: number;
  icon_name?: string;
  created_at: string;
  updated_at: string;
}

export interface Transaction {
  id: string;
  user_id: string;
  card_id?: string;
  merchant_id?: string;
  amount: number;
  currency: string;
  transacted_at: string;
  mcc?: string;
  category?: 'dining' | 'groceries' | 'gas' | 'travel' | 'shopping' | 'entertainment' | 'online' | 'other';
  points_earned?: number;
  multiplier_used?: number;
  created_at: string;
}

export interface RewardsSummary {
  id: string;
  user_id: string;
  period_start: string;
  period_end: string;
  current_month_points: number;
  current_month_value: number;
  previous_month_points?: number;
  created_at: string;
  updated_at: string;
}

export interface MonthlyReward {
  id: string;
  rewards_summary_id: string;
  month: string;
  points?: number;
  value?: number;
  created_at: string;
}

export interface CategoryReward {
  id: string;
  rewards_summary_id: string;
  category: 'dining' | 'groceries' | 'gas' | 'travel' | 'shopping' | 'entertainment' | 'online' | 'other';
  points?: number;
  percentage?: number;
  created_at: string;
}

export interface CardContribution {
  id: string;
  rewards_summary_id: string;
  card_id?: string;
  points?: number;
  tagline?: string;
  created_at: string;
}

export interface OptimizationWin {
  id: string;
  user_id: string;
  title: string;
  description?: string;
  points_earned?: number;
  occurred_at: string;
  created_at: string;
}

export interface CardRecommendation {
  id: string;
  user_id: string;
  issuer: string;
  card_name: string;
  logo_asset_name?: string;
  category_focus: string[];
  estimated_yearly_benefit?: number;
  explanation?: string;
  tags: string[];
  sign_up_bonus?: string;
  apr_range?: string;
  why_we_recommend: string[];
  is_dismissed: boolean;
  created_at: string;
  updated_at: string;
}

export interface CardRewardMatrix {
  id: string;
  card_name: string;
  category_name: string;
  multiplier: number;
  created_at: string;
  updated_at: string;
}

