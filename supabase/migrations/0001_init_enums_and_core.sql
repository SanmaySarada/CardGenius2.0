-- ====================================================
-- CardGenius Backend: Initial Schema
-- Migration: 0001_init_enums_and_core.sql
-- ====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ====================================================
-- ENUMS
-- ====================================================

-- Card status enum
DO $$ BEGIN
    CREATE TYPE card_status AS ENUM ('active', 'paused', 'expired', 'closed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Card network enum
DO $$ BEGIN
    CREATE TYPE card_network AS ENUM ('visa', 'mastercard', 'amex', 'discover', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Card type enum
DO $$ BEGIN
    CREATE TYPE card_type AS ENUM ('credit', 'debit', 'charge', 'prepaid', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Merchant category enum
DO $$ BEGIN
    CREATE TYPE merchant_category AS ENUM (
        'dining', 
        'groceries', 
        'gas', 
        'travel', 
        'shopping', 
        'entertainment', 
        'online', 
        'other'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ====================================================
-- PROFILES
-- ====================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ====================================================
-- INSTITUTIONS
-- ====================================================

CREATE TABLE IF NOT EXISTS public.institutions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    logo_url TEXT,
    provider TEXT, -- e.g., 'plaid', 'mx', 'yodlee'
    provider_institution_id TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_institutions_provider ON public.institutions(provider);

-- ====================================================
-- USER INSTITUTIONS (Connection Links)
-- ====================================================

CREATE TABLE IF NOT EXISTS public.user_institutions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    institution_id UUID NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'linking' CHECK (status IN ('not_linked', 'linking', 'linked', 'error')),
    external_access_token TEXT, -- TODO: encrypt this in production
    external_item_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, institution_id)
);

CREATE INDEX IF NOT EXISTS idx_user_institutions_user_id ON public.user_institutions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_institutions_institution_id ON public.user_institutions(institution_id);

CREATE TRIGGER update_user_institutions_updated_at
    BEFORE UPDATE ON public.user_institutions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ====================================================
-- CARDS
-- ====================================================

CREATE TABLE IF NOT EXISTS public.cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    institution_id UUID REFERENCES public.institutions(id) ON DELETE SET NULL,
    issuer TEXT NOT NULL,
    nickname TEXT,
    last4 TEXT CHECK (LENGTH(last4) = 4),
    network card_network,
    card_type card_type,
    card_style TEXT, -- e.g., 'gold', 'black', 'blue', 'gradient'
    status card_status DEFAULT 'active' NOT NULL,
    credit_limit NUMERIC,
    current_balance NUMERIC,
    current_month_spend NUMERIC DEFAULT 0,
    is_included_in_optimization BOOLEAN DEFAULT true NOT NULL,
    routing_priority INTEGER DEFAULT 0 NOT NULL,
    image_name TEXT, -- path/key for card art in Storage
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cards_user_id ON public.cards(user_id);
CREATE INDEX IF NOT EXISTS idx_cards_institution_id ON public.cards(institution_id);
CREATE INDEX IF NOT EXISTS idx_cards_user_status ON public.cards(user_id, status);

CREATE TRIGGER update_cards_updated_at
    BEFORE UPDATE ON public.cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ====================================================
-- REWARD CATEGORIES (Per-Card Reward Rules)
-- ====================================================

CREATE TABLE IF NOT EXISTS public.reward_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- e.g., 'Dining', 'Travel'
    multiplier NUMERIC NOT NULL, -- e.g., 4.0 for 4x points
    description TEXT,
    category_code TEXT, -- optional fine-grained key (matches MCC / CSV)
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(card_id, name)
);

CREATE INDEX IF NOT EXISTS idx_reward_categories_card_id ON public.reward_categories(card_id);
CREATE INDEX IF NOT EXISTS idx_reward_categories_name ON public.reward_categories(name);

