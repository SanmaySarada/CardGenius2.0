-- ====================================================
-- CardGenius Backend: Recommendations, Reward Matrix, Settings
-- Migration: 0003_recommendations_matrix_settings.sql
-- ====================================================

-- ====================================================
-- CARD REWARD MATRIX (Normalized CSV Data)
-- ====================================================

CREATE TABLE IF NOT EXISTS public.card_reward_matrix (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_name TEXT NOT NULL,
    category_name TEXT NOT NULL,
    multiplier NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(card_name, category_name)
);

CREATE INDEX IF NOT EXISTS idx_card_reward_matrix_card_name ON public.card_reward_matrix(card_name);
CREATE INDEX IF NOT EXISTS idx_card_reward_matrix_category_name ON public.card_reward_matrix(category_name);

CREATE TRIGGER update_card_reward_matrix_updated_at
    BEFORE UPDATE ON public.card_reward_matrix
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ====================================================
-- CARD RECOMMENDATIONS
-- ====================================================

CREATE TABLE IF NOT EXISTS public.card_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    issuer TEXT NOT NULL,
    card_name TEXT NOT NULL,
    logo_asset_name TEXT,
    category_focus JSONB, -- e.g., ["Dining", "Groceries"]
    estimated_yearly_benefit NUMERIC,
    explanation TEXT,
    tags JSONB, -- e.g., ["preApprovalLikely", "beginnerFriendly"]
    sign_up_bonus TEXT,
    apr_range TEXT,
    why_we_recommend JSONB, -- array of strings
    is_dismissed BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_card_recommendations_user_id ON public.card_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_card_recommendations_user_dismissed ON public.card_recommendations(user_id, is_dismissed);
CREATE INDEX IF NOT EXISTS idx_card_recommendations_created_at ON public.card_recommendations(created_at DESC);

CREATE TRIGGER update_card_recommendations_updated_at
    BEFORE UPDATE ON public.card_recommendations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ====================================================
-- USER SETTINGS
-- ====================================================

CREATE TABLE IF NOT EXISTS public.user_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    require_biometric BOOLEAN DEFAULT false NOT NULL,
    hide_balances_by_default BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

