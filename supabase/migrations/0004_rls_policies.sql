-- ====================================================
-- CardGenius Backend: Row Level Security Policies
-- Migration: 0004_rls_policies.sql
-- ====================================================

-- ====================================================
-- PROFILES RLS
-- ====================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own profile"
    ON public.profiles FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "Users can delete their own profile"
    ON public.profiles FOR DELETE
    USING (id = auth.uid());

-- ====================================================
-- USER INSTITUTIONS RLS
-- ====================================================

ALTER TABLE public.user_institutions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own institutions"
    ON public.user_institutions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own institutions"
    ON public.user_institutions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own institutions"
    ON public.user_institutions FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own institutions"
    ON public.user_institutions FOR DELETE
    USING (user_id = auth.uid());

-- ====================================================
-- CARDS RLS
-- ====================================================

ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own cards"
    ON public.cards FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own cards"
    ON public.cards FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own cards"
    ON public.cards FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own cards"
    ON public.cards FOR DELETE
    USING (user_id = auth.uid());

-- ====================================================
-- REWARD CATEGORIES RLS
-- ====================================================

ALTER TABLE public.reward_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select reward categories for their cards"
    ON public.reward_categories FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.cards
            WHERE cards.id = reward_categories.card_id
            AND cards.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert reward categories for their cards"
    ON public.reward_categories FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.cards
            WHERE cards.id = reward_categories.card_id
            AND cards.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update reward categories for their cards"
    ON public.reward_categories FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.cards
            WHERE cards.id = reward_categories.card_id
            AND cards.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.cards
            WHERE cards.id = reward_categories.card_id
            AND cards.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete reward categories for their cards"
    ON public.reward_categories FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.cards
            WHERE cards.id = reward_categories.card_id
            AND cards.user_id = auth.uid()
        )
    );

-- ====================================================
-- TRANSACTIONS RLS
-- ====================================================

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own transactions"
    ON public.transactions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own transactions"
    ON public.transactions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own transactions"
    ON public.transactions FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own transactions"
    ON public.transactions FOR DELETE
    USING (user_id = auth.uid());

-- ====================================================
-- REWARDS SUMMARIES RLS
-- ====================================================

ALTER TABLE public.rewards_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own rewards summaries"
    ON public.rewards_summaries FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own rewards summaries"
    ON public.rewards_summaries FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own rewards summaries"
    ON public.rewards_summaries FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own rewards summaries"
    ON public.rewards_summaries FOR DELETE
    USING (user_id = auth.uid());

-- ====================================================
-- MONTHLY REWARDS RLS
-- ====================================================

ALTER TABLE public.monthly_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own monthly rewards"
    ON public.monthly_rewards FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.rewards_summaries
            WHERE rewards_summaries.id = monthly_rewards.rewards_summary_id
            AND rewards_summaries.user_id = auth.uid()
        )
    );

-- ====================================================
-- CATEGORY REWARDS RLS
-- ====================================================

ALTER TABLE public.category_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own category rewards"
    ON public.category_rewards FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.rewards_summaries
            WHERE rewards_summaries.id = category_rewards.rewards_summary_id
            AND rewards_summaries.user_id = auth.uid()
        )
    );

-- ====================================================
-- CARD CONTRIBUTIONS RLS
-- ====================================================

ALTER TABLE public.card_contributions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own card contributions"
    ON public.card_contributions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.rewards_summaries
            WHERE rewards_summaries.id = card_contributions.rewards_summary_id
            AND rewards_summaries.user_id = auth.uid()
        )
    );

-- ====================================================
-- OPTIMIZATION WINS RLS
-- ====================================================

ALTER TABLE public.optimization_wins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own optimization wins"
    ON public.optimization_wins FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own optimization wins"
    ON public.optimization_wins FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- ====================================================
-- CARD RECOMMENDATIONS RLS
-- ====================================================

ALTER TABLE public.card_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own recommendations"
    ON public.card_recommendations FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own recommendations"
    ON public.card_recommendations FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own recommendations"
    ON public.card_recommendations FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ====================================================
-- USER SETTINGS RLS
-- ====================================================

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select their own settings"
    ON public.user_settings FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own settings"
    ON public.user_settings FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own settings"
    ON public.user_settings FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ====================================================
-- GLOBAL TABLES RLS (Read-Only for All Users)
-- ====================================================

-- INSTITUTIONS
ALTER TABLE public.institutions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read institutions"
    ON public.institutions FOR SELECT
    USING (true);

-- MERCHANTS
ALTER TABLE public.merchants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read merchants"
    ON public.merchants FOR SELECT
    USING (true);

-- CARD REWARD MATRIX
ALTER TABLE public.card_reward_matrix ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read card reward matrix"
    ON public.card_reward_matrix FOR SELECT
    USING (true);

