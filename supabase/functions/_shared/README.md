# CardGenius Backend Documentation

## Overview

This is the complete Supabase backend for the CardGenius iOS app. It provides a production-ready API layer with:

- **PostgreSQL Database**: Full schema with RLS (Row Level Security)
- **Edge Functions**: TypeScript/Deno functions for complex business logic
- **Authentication**: JWT-based auth via Supabase Auth
- **Storage**: Pre-configured buckets for card images and issuer assets

## Architecture

```
CardGenius Backend
├── supabase/
│   ├── migrations/          # SQL migrations (schema + RLS)
│   ├── functions/           # Edge Functions (TypeScript/Deno)
│   │   ├── cards/
│   │   ├── institutions/
│   │   ├── merchants/
│   │   ├── rewards/
│   │   ├── recommendations/
│   │   └── admin-tools/
│   └── seed.sql            # Sample data
└── backend/
    ├── auth.ts             # Authentication utilities
    ├── db.ts               # Database client helpers
    ├── types.ts            # TypeScript type definitions
    ├── cors.ts             # CORS headers
    └── optimizer.ts        # Stub for MCC + optimizer integration
```

## Database Schema

### Core Tables

- **profiles**: User profile data (1:1 with auth.users)
- **institutions**: Supported financial institutions (global)
- **user_institutions**: User ↔ institution connection links
- **cards**: User's credit/debit cards
- **reward_categories**: Per-card reward rules (multipliers by category)
- **merchants**: Global merchant database with locations
- **transactions**: User transaction history
- **rewards_summaries**: Monthly rewards summaries
- **monthly_rewards**: Historical monthly breakdown
- **category_rewards**: Category-based reward breakdown
- **card_contributions**: Per-card contribution to rewards
- **optimization_wins**: Optimization achievements
- **card_reward_matrix**: Normalized CSV reward matrix data
- **card_recommendations**: Personalized card recommendations
- **user_settings**: User preferences

### Enums

- `card_status`: `active`, `paused`, `expired`, `closed`
- `card_network`: `visa`, `mastercard`, `amex`, `discover`, `other`
- `card_type`: `credit`, `debit`, `charge`, `prepaid`, `other`
- `merchant_category`: `dining`, `groceries`, `gas`, `travel`, `shopping`, `entertainment`, `online`, `other`

## API Endpoints

### Base URL

- **Production**: `https://uinktvfzuetcahywoeok.supabase.co`
- **Local**: `http://localhost:54321` (when running `supabase start`)

### Authentication

All endpoints (except public read endpoints) require a JWT token in the `Authorization` header:

```
Authorization: Bearer <jwt_token>
```

---

## Service Protocol Mapping

### A. CardServiceProtocol

#### `fetchCards() -> [Card]`

**Endpoint**: `GET /functions/v1/cards`

**Response**:
```json
{
  "data": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "issuer": "Chase Sapphire Reserve",
      "nickname": "Travel Card",
      "last4": "1234",
      "network": "visa",
      "card_type": "credit",
      "status": "active",
      "reward_categories": [...]
    }
  ]
}
```

#### `refreshCards() -> [Card]`

**Endpoint**: `POST /functions/v1/cards/refresh`

**Response**: Same as `fetchCards()`

**Note**: Currently stubbed. TODO: Integrate with Plaid/Yodlee to sync cards.

#### `updateCard(Card) -> Card`

**Endpoint**: `PUT /functions/v1/cards/:id`

**Request Body**:
```json
{
  "nickname": "Updated Name",
  "is_included_in_optimization": true,
  "routing_priority": 5,
  "status": "active"
}
```

**Response**: Updated card object

#### `getCard(id: String) -> Card?`

**Endpoint**: `GET /functions/v1/cards/:id`

**Response**: Single card object or 404 if not found

---

### B. RewardsServiceProtocol

#### `fetchRewardsSummary() -> RewardsSummary`

**Endpoint**: `GET /functions/v1/rewards/summary`

**Response**:
```json
{
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "current_month_points": 12450,
    "current_month_value": 124.50,
    "previous_month_points": 10550,
    "monthly_breakdown": [...],
    "category_breakdown": [...],
    "card_contributions": [...],
    "optimizations": [...]
  }
}
```

---

### C. InstitutionServiceProtocol

#### `fetchSupportedInstitutions() -> [Institution]`

**Endpoint**: `GET /functions/v1/institutions/supported`

**Response**:
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Chase",
      "logo_url": "...",
      "provider": "plaid",
      "description": "..."
    }
  ]
}
```

#### `linkInstitution(Institution) -> Void`

**Endpoint**: `POST /functions/v1/institutions/link`

**Request Body**:
```json
{
  "institution_id": "uuid"
}
```

**Response**: Linked institution object

**Note**: Currently stubbed. TODO: Integrate with Plaid link token exchange.

#### `unlinkInstitution(Institution) -> Void`

**Endpoint**: `POST /functions/v1/institutions/unlink`

**Request Body**:
```json
{
  "user_institution_id": "uuid"
}
```

**Response**: Unlinked institution object

#### `getLinkedInstitutions() -> [Institution]`

**Endpoint**: `GET /functions/v1/institutions/linked`

**Response**: Array of linked institutions with full institution details

---

### D. MerchantServiceProtocol

#### `getCurrentMerchant() -> Merchant?`

**Endpoint**: `GET /functions/v1/merchants/current?lat=37.7749&lng=-122.4194`

**Query Parameters**:
- `lat` (required): Latitude
- `lng` (required): Longitude

**Response**:
```json
{
  "data": {
    "id": "uuid",
    "name": "Starbucks",
    "category": "dining",
    "latitude": 37.7749,
    "longitude": -122.4194
  }
}
```

#### `getNearbyMerchants() -> [Merchant]`

**Endpoint**: `GET /functions/v1/merchants/nearby?lat=37.7749&lng=-122.4194&radius=5000`

**Query Parameters**:
- `lat` (required): Latitude
- `lng` (required): Longitude
- `radius` (optional): Radius in meters (default: 5000)

**Response**: Array of nearby merchants

#### `getRecommendedCard(for: Merchant) -> Card?`

**Endpoint**: `POST /functions/v1/merchants/recommend-card`

**Request Body**:
```json
{
  "merchant_id": "uuid",
  "lat": 37.7749,
  "lng": -122.4194,
  "mcc": "5812",
  "category": "dining"
}
```

**Response**:
```json
{
  "data": {
    "recommended_card": { /* Card object */ },
    "alternative_card": { /* Card object */ },
    "reasoning": [
      "Recommended: Amex Gold (4x rewards for dining)",
      "Alternative: Chase Sapphire Reserve (3x rewards)"
    ]
  }
}
```

**Note**: Currently uses stub optimizer. TODO: Integrate external MCC + optimizer logic.

---

### E. RecommendationServiceProtocol

#### `fetchCardRecommendations() -> [CardRecommendation]`

**Endpoint**: `GET /functions/v1/recommendations`

**Response**:
```json
{
  "data": [
    {
      "id": "uuid",
      "issuer": "Chase",
      "card_name": "Chase Freedom Flex",
      "category_focus": ["Groceries", "Online Shopping"],
      "estimated_yearly_benefit": 180.0,
      "tags": ["noAnnualFee", "beginnerFriendly"],
      "is_dismissed": false
    }
  ]
}
```

#### `dismissRecommendation(CardRecommendation) -> Void`

**Endpoint**: `POST /functions/v1/recommendations/:id/dismiss`

**Response**: Updated recommendation object with `is_dismissed: true`

#### `getEstimatedYearlyGain() -> Double`

**Endpoint**: `GET /functions/v1/recommendations/estimated-gain`

**Response**:
```json
{
  "data": {
    "yearlyGain": 320.0,
    "explanation": ["Based on your spending patterns..."]
  }
}
```

**Note**: Currently stubbed. TODO: Integrate external optimizer.

---

## Admin Endpoints

### Import Card Reward Matrix

**Endpoint**: `POST /functions/v1/admin-tools/import-card-reward-matrix`

**Authentication**: Requires service role key in Authorization header

**Request Body**:
```json
{
  "csv_text": "Card Name,Category,Multiplier\nChase Sapphire Reserve,Travel,3.0\n..."
}
```

**Response**:
```json
{
  "data": {
    "message": "Imported 150 reward matrix entries",
    "imported_count": 150
  }
}
```

---

## Environment Variables

Create a `.env` file in the `backend/` directory (or use Supabase CLI environment):

```bash
SUPABASE_URL=https://uinktvfzuetcahywoeok.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Important**: Never commit actual keys to version control. Use environment variables or Supabase CLI secrets.

---

## Local Development

### Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- Docker Desktop running (for local Supabase)

### Setup

1. **Start local Supabase**:
   ```bash
   cd supabase
   supabase start
   ```

2. **Run migrations**:
   ```bash
   supabase db reset  # Runs all migrations + seed data
   ```

3. **Deploy Edge Functions locally**:
   ```bash
   supabase functions serve cards
   supabase functions serve institutions
   # ... etc
   ```

4. **Or serve all functions**:
   ```bash
   supabase functions serve
   ```

### Testing

Use the Supabase Studio (http://localhost:54323) to:
- View database tables
- Test RLS policies
- Inspect Edge Function logs

---

## Production Deployment

### Deploy Migrations

```bash
supabase db push
```

### Deploy Edge Functions

```bash
supabase functions deploy cards
supabase functions deploy institutions
supabase functions deploy merchants
supabase functions deploy rewards
supabase functions deploy recommendations
supabase functions deploy admin-tools
```

### Set Environment Variables

```bash
supabase secrets set SUPABASE_URL=https://uinktvfzuetcahywoeok.supabase.co
supabase secrets set SUPABASE_ANON_KEY=your_anon_key
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

---

## Integration Points for External Code

### 1. MCC → Category Mapping

**Location**: `backend/optimizer.ts`

**Function**: `getRecommendedCardForMerchant()`

**TODO**: Replace stub logic with your MCC mapping service.

### 2. Card Optimizer Engine

**Location**: `backend/optimizer.ts`

**Functions**:
- `getRecommendedCardForMerchant()` - Merchant-based card selection
- `getEstimatedYearlyGain()` - Yearly benefit calculation

**TODO**: Integrate your external optimizer repository.

### 3. Institution Integration (Plaid/MX/Yodlee)

**Locations**:
- `supabase/functions/institutions/index.ts` - `linkInstitution()` function
- `supabase/functions/cards/index.ts` - `refreshCards()` function

**TODO**: 
- Implement Plaid link token exchange
- Implement card sync from Plaid
- Store and refresh access tokens securely

### 4. Transaction Import

**Location**: Background job (not yet implemented)

**TODO**: Create a scheduled Edge Function or external service to:
- Fetch transactions from Plaid
- Categorize using MCC mapping
- Calculate rewards
- Update rewards summaries

---

## Error Handling

All endpoints return errors in this format:

```json
{
  "error": {
    "message": "Human-readable error message",
    "code": "ERROR_CODE"
  }
}
```

Common error codes:
- `UNAUTHORIZED`: Missing or invalid JWT token
- `NOT_FOUND`: Resource not found
- `VALIDATION_ERROR`: Invalid request parameters
- `INTERNAL_ERROR`: Server error

---

## Security Notes

1. **RLS Policies**: All user-owned tables have RLS enabled. Users can only access their own data.

2. **JWT Validation**: All Edge Functions validate JWT tokens from the Authorization header.

3. **Service Role Key**: Only used in admin functions and for operations that need to bypass RLS (e.g., reward calculations).

4. **Access Tokens**: Institution access tokens are stored in `user_institutions.external_access_token`. TODO: Encrypt these in production.

---

## Next Steps

1. **Integrate Plaid**: Implement institution linking and card syncing
2. **Import CSV**: Use admin endpoint to import full card reward matrix
3. **Connect Optimizer**: Replace stubs in `optimizer.ts` with your external code
4. **Transaction Sync**: Build background job to import transactions
5. **Recommendation Engine**: Implement personalized card recommendations
6. **Testing**: Add integration tests for Edge Functions

---

## Support

For issues or questions, refer to:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Edge Functions Guide](https://supabase.com/docs/guides/functions)

