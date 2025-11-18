# CardGenius Backend - Quick Start Guide

## ✅ What's Been Built

A complete production-ready Supabase backend with:

- ✅ **4 SQL Migrations**: Complete database schema with RLS policies
- ✅ **6 Edge Functions**: Full API implementation matching frontend protocols
- ✅ **Shared Utilities**: Auth, DB, CORS, and optimizer stubs
- ✅ **Seed Data**: Sample institutions, merchants, and reward matrix
- ✅ **Documentation**: Complete API reference in `backend/README.md`

## 🚀 Quick Setup

### 1. Install Supabase CLI

```bash
brew install supabase/tap/supabase
# or
npm install -g supabase
```

### 2. Link to Your Project

```bash
cd supabase
supabase link --project-ref uinktvfzuetcahywoeok
```

### 3. Run Migrations

```bash
supabase db push
```

This will:
- Create all tables, enums, and RLS policies
- Load seed data (institutions, merchants, sample reward matrix)

### 4. Deploy Edge Functions

```bash
supabase functions deploy cards
supabase functions deploy institutions
supabase functions deploy merchants
supabase functions deploy rewards
supabase functions deploy recommendations
supabase functions deploy admin-tools
```

### 5. Set Environment Variables

The functions need these environment variables (set via Supabase Dashboard or CLI):

```bash
supabase secrets set SUPABASE_URL=https://uinktvfzuetcahywoeok.supabase.co
supabase secrets set SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 📱 iOS Integration

Your SwiftUI app can now call these endpoints:

### Base URL
```
https://uinktvfzuetcahywoeok.supabase.co/functions/v1/
```

### Example: Fetch Cards

```swift
let url = URL(string: "https://uinktvfzuetcahywoeok.supabase.co/functions/v1/cards")!
var request = URLRequest(url: url)
request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")

let (data, _) = try await URLSession.shared.data(for: request)
let cards = try JSONDecoder().decode([Card].self, from: data)
```

See `backend/README.md` for complete API documentation.

## 🔧 Next Steps

1. **Import Full Reward Matrix**: Use the admin endpoint to import your CSV
2. **Integrate Plaid**: Replace stubs in `institutions` and `cards` functions
3. **Connect Optimizer**: Replace stubs in `optimizer.ts` with your external code
4. **Test Endpoints**: Use Supabase Studio or Postman to test

## 📚 Documentation

- **Full API Docs**: `backend/README.md`
- **Database Schema**: See migrations in `supabase/migrations/`
- **Edge Functions**: See `supabase/functions/`

## 🔐 Security Notes

- All user data is protected by RLS (Row Level Security)
- JWT tokens are validated on every request
- Service role key is only used for admin operations
- API keys are stored as environment variables (never in code)

## 🐛 Troubleshooting

**Functions not working?**
- Check environment variables are set: `supabase secrets list`
- Check function logs: `supabase functions logs <function-name>`

**RLS blocking queries?**
- Ensure JWT token is valid and includes user ID
- Check RLS policies in `supabase/migrations/0004_rls_policies.sql`

**Import paths not working?**
- Shared code is in `supabase/functions/_shared/`
- Functions import from `../_shared/`

