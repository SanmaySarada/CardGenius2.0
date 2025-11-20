-- ====================================================
-- CardGenius Backend: Merchants, Transactions, Rewards
-- Migration: 0002_merchants_transactions_rewards.sql
-- ====================================================

-- ====================================================
-- MERCHANTS (Global)
-- ====================================================

CREATE TABLE IF NOT EXISTS public.merchants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category merchant_category,
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    icon_name TEXT, -- for UI
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_merchants_category ON public.merchants(category);
CREATE INDEX IF NOT EXISTS idx_merchants_location ON public.merchants USING GIST (
    ll_to_earth(latitude, longitude)
) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

CREATE TRIGGER update_merchants_updated_at
    BEFORE UPDATE ON public.merchants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable PostGIS extension for location queries (if available)
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- ====================================================
-- TRANSACTIONS
-- ====================================================

CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    card_id UUID REFERENCES public.cards(id) ON DELETE SET NULL,
    merchant_id UUID REFERENCES public.merchants(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL,
    currency TEXT DEFAULT 'USD' NOT NULL,
    transacted_at TIMESTAMPTZ NOT NULL,
    mcc TEXT, -- raw MCC string
    category merchant_category, -- mapped category
    points_earned NUMERIC,
    multiplier_used NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_transacted_at ON public.transactions(user_id, transacted_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_card_id ON public.transactions(card_id);
CREATE INDEX IF NOT EXISTS idx_transactions_merchant_id ON public.transactions(merchant_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON public.transactions(category);

-- ====================================================
-- REWARDS SUMMARIES
-- ====================================================

CREATE TABLE IF NOT EXISTS public.rewards_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    current_month_points NUMERIC DEFAULT 0 NOT NULL,
    current_month_value NUMERIC DEFAULT 0 NOT NULL,
    previous_month_points NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, period_start, period_end)
);

CREATE INDEX IF NOT EXISTS idx_rewards_summaries_user_id ON public.rewards_summaries(user_id);
CREATE INDEX IF NOT EXISTS idx_rewards_summaries_period ON public.rewards_summaries(user_id, period_start DESC);

CREATE TRIGGER update_rewards_summaries_updated_at
    BEFORE UPDATE ON public.rewards_summaries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ====================================================
-- MONTHLY REWARDS
-- ====================================================

CREATE TABLE IF NOT EXISTS public.monthly_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rewards_summary_id UUID NOT NULL REFERENCES public.rewards_summaries(id) ON DELETE CASCADE,
    month DATE NOT NULL,
    points NUMERIC,
    value NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_monthly_rewards_summary_id ON public.monthly_rewards(rewards_summary_id);

-- ====================================================
-- CATEGORY REWARDS
-- ====================================================

CREATE TABLE IF NOT EXISTS public.category_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rewards_summary_id UUID NOT NULL REFERENCES public.rewards_summaries(id) ON DELETE CASCADE,
    category merchant_category NOT NULL,
    points NUMERIC,
    percentage NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_category_rewards_summary_id ON public.category_rewards(rewards_summary_id);

-- ====================================================
-- CARD CONTRIBUTIONS
-- ====================================================

CREATE TABLE IF NOT EXISTS public.card_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rewards_summary_id UUID NOT NULL REFERENCES public.rewards_summaries(id) ON DELETE CASCADE,
    card_id UUID REFERENCES public.cards(id) ON DELETE SET NULL,
    points NUMERIC,
    tagline TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_card_contributions_summary_id ON public.card_contributions(rewards_summary_id);
CREATE INDEX IF NOT EXISTS idx_card_contributions_card_id ON public.card_contributions(card_id);

-- ====================================================
-- OPTIMIZATION WINS
-- ====================================================

CREATE TABLE IF NOT EXISTS public.optimization_wins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    points_earned NUMERIC,
    occurred_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_optimization_wins_user_id ON public.optimization_wins(user_id);
CREATE INDEX IF NOT EXISTS idx_optimization_wins_occurred_at ON public.optimization_wins(user_id, occurred_at DESC);

