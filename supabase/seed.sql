-- ====================================================
-- CardGenius Backend: Seed Data
-- ====================================================

-- ====================================================
-- SAMPLE INSTITUTIONS
-- ====================================================

INSERT INTO public.institutions (id, name, logo_url, provider, description) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'Chase', NULL, 'plaid', 'Chase Bank - Credit cards and banking services'),
    ('550e8400-e29b-41d4-a716-446655440002', 'American Express', NULL, 'plaid', 'American Express - Credit cards and financial services'),
    ('550e8400-e29b-41d4-a716-446655440003', 'Bank of America', NULL, 'plaid', 'Bank of America - Full-service banking'),
    ('550e8400-e29b-41d4-a716-446655440004', 'Citi', NULL, 'plaid', 'Citibank - Global banking services'),
    ('550e8400-e29b-41d4-a716-446655440005', 'Capital One', NULL, 'plaid', 'Capital One - Banking and credit cards'),
    ('550e8400-e29b-41d4-a716-446655440006', 'Wells Fargo', NULL, 'plaid', 'Wells Fargo - Banking and financial services')
ON CONFLICT DO NOTHING;

-- ====================================================
-- SAMPLE MERCHANTS
-- ====================================================

INSERT INTO public.merchants (id, name, category, address, latitude, longitude, icon_name) VALUES
    ('660e8400-e29b-41d4-a716-446655440001', 'Starbucks', 'dining', '123 Campus Blvd, San Francisco, CA', 37.7749, -122.4194, 'cup.and.saucer.fill'),
    ('660e8400-e29b-41d4-a716-446655440002', 'Trader Joe''s', 'groceries', '321 Oak Ave, San Francisco, CA', 37.7849, -122.4094, 'cart.fill'),
    ('660e8400-e29b-41d4-a716-446655440003', 'Chevron', 'gas', '789 Main St, San Francisco, CA', 37.7649, -122.4294, 'fuelpump.fill'),
    ('660e8400-e29b-41d4-a716-446655440004', 'Target', 'shopping', '456 Market St, San Francisco, CA', 37.7549, -122.4394, 'bag.fill'),
    ('660e8400-e29b-41d4-a716-446655440005', 'Whole Foods Market', 'groceries', '100 Market St, San Francisco, CA', 37.7849, -122.4094, 'cart.fill'),
    ('660e8400-e29b-41d4-a716-446655440006', 'Shell', 'gas', '200 Mission St, San Francisco, CA', 37.7749, -122.4194, 'fuelpump.fill'),
    ('660e8400-e29b-41d4-a716-446655440007', 'McDonald''s', 'dining', '50 3rd St, San Francisco, CA', 37.7849, -122.4094, 'cup.and.saucer.fill'),
    ('660e8400-e29b-41d4-a716-446655440008', 'Amazon', 'online', 'Online', NULL, NULL, 'bag.fill'),
    ('660e8400-e29b-41d4-a716-446655440009', 'United Airlines', 'travel', 'Airport', 37.6213, -122.3789, 'airplane'),
    ('660e8400-e29b-41d4-a716-446655440010', 'AMC Theaters', 'entertainment', '100 Van Ness Ave, San Francisco, CA', 37.7749, -122.4194, 'tv.fill')
ON CONFLICT DO NOTHING;

-- ====================================================
-- SAMPLE CARD REWARD MATRIX (Common Cards)
-- ====================================================

INSERT INTO public.card_reward_matrix (card_name, category_name, multiplier) VALUES
    -- Chase Sapphire Reserve
    ('Chase Sapphire Reserve', 'Travel', 3.0),
    ('Chase Sapphire Reserve', 'Dining', 3.0),
    ('Chase Sapphire Reserve', 'Everywhere', 1.0),
    
    -- American Express Gold
    ('American Express Gold', 'Dining', 4.0),
    ('American Express Gold', 'Groceries', 4.0),
    ('American Express Gold', 'Travel', 3.0),
    ('American Express Gold', 'Everywhere', 1.0),
    
    -- Bank of America Customized Cash
    ('Bank of America Customized Cash', 'Groceries', 3.0),
    ('Bank of America Customized Cash', 'Gas', 2.0),
    ('Bank of America Customized Cash', 'Everywhere', 1.0),
    
    -- Citi Double Cash
    ('Citi Double Cash', 'Everywhere', 2.0),
    
    -- Capital One Venture X
    ('Capital One Venture X', 'Travel', 10.0),
    ('Capital One Venture X', 'Everywhere', 2.0),
    
    -- Chase Freedom Flex
    ('Chase Freedom Flex', 'Groceries', 5.0),
    ('Chase Freedom Flex', 'Shopping', 5.0),
    ('Chase Freedom Flex', 'Everywhere', 1.0),
    
    -- American Express Platinum
    ('American Express Platinum', 'Travel', 5.0),
    ('American Express Platinum', 'Everywhere', 1.0)
ON CONFLICT (card_name, category_name) DO UPDATE SET multiplier = EXCLUDED.multiplier;

