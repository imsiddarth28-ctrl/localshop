# The Local Shop — Backend Setup Guide (Supabase)

This repository contains the database schema, Row-Level Security (RLS) policies, triggers, RPC procedures, storage bucket policies, Edge Functions, and seed dataset for **The Local Shop**.

---

## 1. Prerequisites

- A Supabase account ([supabase.com](https://supabase.com)) or local Supabase CLI instance.
- Supabase CLI installed (`npm install -g supabase` or via brew/scoop).
- Deno installed (optional, for local Edge Function testing).
- Firebase Console project (for FCM push notifications).

---

## 2. Supabase Project Configuration

### Step A: Disable Email Confirmation (MANDATORY)
The app uses phone numbers for authentication (+91 Indian numbers) mapped internally to synthetic emails:
```
<91XXXXXXXXXX>@thelocalshop.app
```
Because no SMS/OTP gateway is used in this MVP, users verify and log in directly using Phone + Password. Therefore, email confirmation must be turned off:
1. Open your Supabase Dashboard: **Authentication > Providers > Email**.
2. Toggle **Confirm email** to **OFF** (Disabled).
3. Set **Minimum password length** to **6**.
4. Click **Save**.

---

## 3. Applying Database Migrations

Run the SQL migration scripts in order using the Supabase SQL Editor or CLI:

```bash
cd backend
supabase db reset --linked
# OR run the files sequentially in the Supabase Dashboard SQL Editor:
# 1. supabase/migrations/20261024000001_initial_schema.sql
# 2. supabase/migrations/20261024000002_rls_policies.sql
# 3. supabase/migrations/20261024000003_triggers_and_rpc.sql
# 4. supabase/migrations/20261024000004_storage_setup.sql
```

### Key Security Features Implemented in Migrations:
- **Strict Postgres RLS on every table**:
  - Customers can only read and manage their own orders, messages, and reviews.
  - Shop Owners can only manage orders, items, and settings belonging to their own shop.
  - Colony Join Codes are **never exposed** directly via client queries; join codes are validated solely via the secure `validate_colony_join_code` RPC function.
  - Shop approvals are protected by a Postgres trigger ensuring colonies never exceed `max_shops` approved shops.
  - Rate limiting table and RPC (`check_login_rate_limit` & `record_login_attempt`) lock login attempts for 15 minutes after 5 consecutive failures.

---

## 4. Seeding Demo Data

Execute `supabase/seed.sql` in the Supabase SQL Editor:
```bash
supabase db push
# OR paste backend/supabase/seed.sql into the Supabase Dashboard SQL Editor
```

### Pre-Configured Demo Accounts (Password: `password123` for all)

| Role | Phone | Name | Colony | Notes |
|---|---|---|---|---|
| **Admin** | `+919000000000` | App Admin | Greenwood Heights | Full administrative access |
| **Shop Owner** | `+919111111111` | Balaji Sharma | Greenwood Heights | Sri Balaji Kirana & General Store (Grocery) |
| **Shop Owner** | `+919222222222` | Venkat Reddy | Greenwood Heights | Vijaya Dairy & Fresh Sweets (Dairy) |
| **Shop Owner** | `+919333333333` | Ramesh Kumar | Greenwood Heights | Fresh Veggies & Fruits Corner (Vegetables) |
| **Customer 1** | `+919444444441` | Sita Devi | Greenwood Heights (GRN101) | Flat A-102 |
| **Customer 2** | `+919444444442` | Srinivasa Rao | Greenwood Heights (GRN101) | Flat B-304 |
| **Customer 3** | `+919444444443` | Lakshmi Kumari | Greenwood Heights (GRN101) | Flat C-201 |
| **Customer 4** | `+919444444444` | Rajesh Varma | Greenwood Heights (GRN101) | Flat A-405 |
| **Customer 5** | `+919444444445` | Ananya Rao | Greenwood Heights (GRN101) | Flat D-103 |

**Colony Join Code**: `GRN101` (Greenwood Heights).

---

## 5. Deploying Supabase Edge Functions

Deploy the three micro-functions:

```bash
# 1. Admin Password Reset
supabase functions deploy admin-password-reset --no-verify-jwt

# 2. Push Notification Dispatcher
supabase functions deploy fcm-sender --no-verify-jwt

# 3. Batch Delivery Slot Reminder
supabase functions deploy slot-reminder --no-verify-jwt
```

### Setting Environment Secrets
In your Supabase project dashboard or CLI:
```bash
supabase secrets set FCM_SERVER_KEY="your-firebase-server-key-or-oauth-key"
```

---

## 6. Configuring Database Webhooks for FCM

To automatically trigger push notifications when orders and messages are created or updated:
1. Go to **Database > Webhooks** in the Supabase Dashboard.
2. Create Webhook **Order Status Changes**:
   - Table: `public.orders`
   - Events: `INSERT`, `UPDATE`
   - Target: Supabase Edge Function `fcm-sender`
3. Create Webhook **New Chat Message / Bill**:
   - Table: `public.messages`
   - Events: `INSERT`
   - Target: Supabase Edge Function `fcm-sender`

---

## 7. Storage Bucket Verification

Check **Storage** in the Supabase Dashboard. The migration automatically creates:
1. `chat-media` (Private): Encrypted chat photos and voice notes.
2. `shop-photos` (Public): High-resolution shop storefront images.
3. `avatars` (Public): User profile avatars.
