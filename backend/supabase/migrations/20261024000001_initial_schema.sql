-- ==============================================================================
-- THE LOCAL SHOP: 01 - INITIAL DATABASE SCHEMA
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Role enum
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('customer', 'shop_owner', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Shop Status enum
DO $$ BEGIN
    CREATE TYPE shop_status AS ENUM ('pending', 'approved', 'rejected', 'suspended');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Order Slot Type enum
DO $$ BEGIN
    CREATE TYPE delivery_slot_type AS ENUM ('instant', 'morning', 'evening');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Order Status enum
DO $$ BEGIN
    CREATE TYPE order_status AS ENUM (
        'placed', 
        'accepted', 
        'preparing', 
        'out_for_delivery', 
        'delivered', 
        'cancelled', 
        'partially_unavailable'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Payment Status enum
DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('unpaid', 'paid_cod', 'paid_upi');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Message Type enum
DO $$ BEGIN
    CREATE TYPE message_type AS ENUM ('text', 'voice', 'image', 'bill');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Password Reset Request Status enum
DO $$ BEGIN
    CREATE TYPE reset_request_status AS ENUM ('pending', 'completed', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 1. COLONIES TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.colonies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    join_code VARCHAR(12) NOT NULL UNIQUE,
    max_shops INTEGER NOT NULL DEFAULT 3,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index on join_code
CREATE INDEX IF NOT EXISTS idx_colonies_join_code ON public.colonies(join_code);

-- ==============================================================================
-- 2. PROFILES TABLE (Mirrors auth.users)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'customer',
    phone VARCHAR(20) NOT NULL UNIQUE,
    name TEXT NOT NULL,
    colony_id UUID REFERENCES public.colonies(id) ON DELETE SET NULL,
    address TEXT, -- block / flat number
    avatar_url TEXT,
    must_change_password BOOLEAN NOT NULL DEFAULT FALSE,
    suspended BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone);
CREATE INDEX IF NOT EXISTS idx_profiles_colony_id ON public.profiles(colony_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- ==============================================================================
-- 3. SHOPS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.shops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    colony_id UUID NOT NULL REFERENCES public.colonies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- Grocery, Dairy, Vegetables, Medical, Stationery, Bakery, Other
    photo_url TEXT,
    hours TEXT NOT NULL DEFAULT '7:00 AM - 9:00 PM',
    slots JSONB NOT NULL DEFAULT '{"instant": true, "morning": true, "evening": true}'::jsonb,
    instant_fee NUMERIC(6,2) NOT NULL DEFAULT 10.00,
    slot_fee NUMERIC(6,2) NOT NULL DEFAULT 5.00,
    cutoffs JSONB NOT NULL DEFAULT '{"morning_cutoff": "22:00", "evening_cutoff": "16:00"}'::jsonb,
    upi_id TEXT,
    upi_qr_url TEXT,
    status shop_status NOT NULL DEFAULT 'pending',
    rating NUMERIC(3,2) NOT NULL DEFAULT 5.00,
    total_reviews INTEGER NOT NULL DEFAULT 0,
    is_open BOOLEAN NOT NULL DEFAULT TRUE,
    holiday_mode BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shops_colony_id ON public.shops(colony_id);
CREATE INDEX IF NOT EXISTS idx_shops_owner_id ON public.shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_shops_status ON public.shops(status);

-- ==============================================================================
-- 4. ORDERS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number BIGSERIAL,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    slot_type delivery_slot_type NOT NULL DEFAULT 'instant',
    delivery_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status order_status NOT NULL DEFAULT 'placed',
    delivery_fee NUMERIC(6,2) NOT NULL DEFAULT 10.00,
    subtotal NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    total NUMERIC(10,2) NOT NULL DEFAULT 10.00,
    payment_status payment_status NOT NULL DEFAULT 'unpaid',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_shop_id ON public.orders(shop_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_slot_type ON public.orders(slot_type);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_date ON public.orders(delivery_date);

-- ==============================================================================
-- 5. MESSAGES TABLE (WhatsApp-style order chat)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type message_type NOT NULL DEFAULT 'text',
    body TEXT,
    media_url TEXT,
    media_duration_seconds INTEGER,
    bill JSONB, -- { items: [...], subtotal: 150, delivery_fee: 10, total: 160 }
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_order_id ON public.messages(order_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);

-- ==============================================================================
-- 6. ORDER ITEMS TABLE (Itemized bill line items)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    qty NUMERIC(6,2) NOT NULL DEFAULT 1.0,
    unit TEXT NOT NULL DEFAULT 'kg', -- kg, gm, packet, liter, piece
    price NUMERIC(8,2) NOT NULL DEFAULT 0.00,
    available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);

-- ==============================================================================
-- 7. FREQUENT ITEMS TABLE (Shop items catalog / quick add)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.frequent_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT 'kg',
    price NUMERIC(8,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_frequent_items_shop_id ON public.frequent_items(shop_id);

-- ==============================================================================
-- 8. REVIEWS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
    shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    stars INTEGER NOT NULL CHECK (stars >= 1 AND stars <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reviews_shop_id ON public.reviews(shop_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON public.reviews(customer_id);

-- ==============================================================================
-- 9. DEVICE TOKENS TABLE (FCM push notification tokens)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.device_tokens (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, token)
);

-- ==============================================================================
-- 10. PASSWORD RESET REQUESTS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.password_reset_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    phone VARCHAR(20) NOT NULL,
    status reset_request_status NOT NULL DEFAULT 'pending',
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_reset_requests_status ON public.password_reset_requests(status);
CREATE INDEX IF NOT EXISTS idx_reset_requests_user_id ON public.password_reset_requests(user_id);

-- ==============================================================================
-- 11. RATE LIMIT TABLE (5 wrong attempts -> 15 min lock)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.login_rate_limits (
    phone VARCHAR(20) PRIMARY KEY,
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    last_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    locked_until TIMESTAMPTZ
);
