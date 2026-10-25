-- ==============================================================================
-- THE LOCAL SHOP: SEED DATA
-- 1 Colony, 3 Approved Shops, 5 Customers, 1 Admin, Sample Orders & Items
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------------------------
-- 1. SEED COLONY
-- ------------------------------------------------------------------------------
INSERT INTO public.colonies (id, name, join_code, max_shops)
VALUES 
    ('c0000000-0000-0000-0000-000000000001', 'Greenwood Heights', 'GRN101', 3)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 2. SEED AUTH USERS & PROFILES
-- Helper block to insert auth.users and profiles
-- ------------------------------------------------------------------------------
DO $$
DECLARE
    v_admin_id UUID := 'a0000000-0000-0000-0000-000000000001';
    v_owner1_id UUID := 'b0000000-0000-0000-0000-000000000001';
    v_owner2_id UUID := 'b0000000-0000-0000-0000-000000000002';
    v_owner3_id UUID := 'b0000000-0000-0000-0000-000000000003';
    v_cust1_id  UUID := 'd0000000-0000-0000-0000-000000000001';
    v_cust2_id  UUID := 'd0000000-0000-0000-0000-000000000002';
    v_cust3_id  UUID := 'd0000000-0000-0000-0000-000000000003';
    v_cust4_id  UUID := 'd0000000-0000-0000-0000-000000000004';
    v_cust5_id  UUID := 'd0000000-0000-0000-0000-000000000005';
    v_colony_id UUID := 'c0000000-0000-0000-0000-000000000001';
    v_password_hash TEXT;
BEGIN
    v_password_hash := crypt('password123', gen_salt('bf'));

    -- Admin Auth User
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES (v_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '919000000000@thelocalshop.app', v_password_hash, NOW(), '{"provider":"email","providers":["email"]}', '{"role":"admin","phone":"+919000000000","name":"App Admin"}', NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;

    -- Shop Owner 1 (Kirana)
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES (v_owner1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '919111111111@thelocalshop.app', v_password_hash, NOW(), '{"provider":"email","providers":["email"]}', '{"role":"shop_owner","phone":"+919111111111","name":"Balaji Sharma"}', NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;

    -- Shop Owner 2 (Dairy)
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES (v_owner2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '919222222222@thelocalshop.app', v_password_hash, NOW(), '{"provider":"email","providers":["email"]}', '{"role":"shop_owner","phone":"+919222222222","name":"Venkat Reddy"}', NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;

    -- Shop Owner 3 (Vegetables)
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES (v_owner3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '919333333333@thelocalshop.app', v_password_hash, NOW(), '{"provider":"email","providers":["email"]}', '{"role":"shop_owner","phone":"+919333333333","name":"Ramesh Kumar"}', NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;

    -- Customers 1 to 5
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES 
    (v_cust1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '919444444441@thelocalshop.app', v_password_hash, NOW(), '{"provider":"email","providers":["email"]}', '{"role":"customer","phone":"+919444444441","name":"Sita Devi"}', NOW(), NOW()),
    (v_cust2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '919444444442@thelocalshop.app', v_password_hash, NOW(), '{"provider":"email","providers":["email"]}', '{"role":"customer","phone":"+919444444442","name":"Srinivasa Rao"}', NOW(), NOW()),
    (v_cust3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '919444444443@thelocalshop.app', v_password_hash, NOW(), '{"provider":"email","providers":["email"]}', '{"role":"customer","phone":"+919444444443","name":"Lakshmi Kumari"}', NOW(), NOW()),
    (v_cust4_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '919444444444@thelocalshop.app', v_password_hash, NOW(), '{"provider":"email","providers":["email"]}', '{"role":"customer","phone":"+919444444444","name":"Rajesh Varma"}', NOW(), NOW()),
    (v_cust5_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '919444444445@thelocalshop.app', v_password_hash, NOW(), '{"provider":"email","providers":["email"]}', '{"role":"customer","phone":"+919444444445","name":"Ananya Rao"}', NOW(), NOW())
    ON CONFLICT (id) DO NOTHING;

    -- Profiles
    INSERT INTO public.profiles (id, role, phone, name, colony_id, address, must_change_password, suspended)
    VALUES 
    (v_admin_id, 'admin', '+919000000000', 'App Admin', v_colony_id, 'Admin Office', false, false),
    (v_owner1_id, 'shop_owner', '+919111111111', 'Balaji Sharma', v_colony_id, 'Shop 1, Community Center', false, false),
    (v_owner2_id, 'shop_owner', '+919222222222', 'Venkat Reddy', v_colony_id, 'Shop 2, Community Center', false, false),
    (v_owner3_id, 'shop_owner', '+919333333333', 'Ramesh Kumar', v_colony_id, 'Shop 3, Community Center', false, false),
    (v_cust1_id, 'customer', '+919444444441', 'Sita Devi', v_colony_id, 'Flat A-102', false, false),
    (v_cust2_id, 'customer', '+919444444442', 'Srinivasa Rao', v_colony_id, 'Flat B-304', false, false),
    (v_cust3_id, 'customer', '+919444444443', 'Lakshmi Kumari', v_colony_id, 'Flat C-201', false, false),
    (v_cust4_id, 'customer', '+919444444444', 'Rajesh Varma', v_colony_id, 'Flat A-405', false, false),
    (v_cust5_id, 'customer', '+919444444445', 'Ananya Rao', v_colony_id, 'Flat D-103', false, false)
    ON CONFLICT (id) DO NOTHING;
END $$;

-- ------------------------------------------------------------------------------
-- 3. SEED SHOPS (3 approved shops in Greenwood Heights)
-- ------------------------------------------------------------------------------
INSERT INTO public.shops (
    id, owner_id, colony_id, name, category, photo_url, hours, slots, 
    instant_fee, slot_fee, cutoffs, upi_id, status, rating, total_reviews, is_open
)
VALUES 
(
    'e0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    'Sri Balaji Kirana & General Store',
    'Grocery',
    'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&auto=format&fit=crop&q=80',
    '6:30 AM - 10:00 PM',
    '{"instant": true, "morning": true, "evening": true}'::jsonb,
    10.00,
    5.00,
    '{"morning_cutoff": "22:00", "evening_cutoff": "16:00"}'::jsonb,
    'balajikirana@okhdfcbank',
    'approved',
    4.90,
    12,
    true
),
(
    'e0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    'Vijaya Dairy & Fresh Sweets',
    'Dairy',
    'https://images.unsplash.com/photo-1528750997573-59b89d56f4f7?w=500&auto=format&fit=crop&q=80',
    '6:00 AM - 9:30 PM',
    '{"instant": true, "morning": true, "evening": true}'::jsonb,
    10.00,
    5.00,
    '{"morning_cutoff": "22:00", "evening_cutoff": "16:00"}'::jsonb,
    'vijayadairy@icici',
    'approved',
    4.80,
    8,
    true
),
(
    'e0000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000001',
    'Fresh Veggies & Fruits Corner',
    'Vegetables',
    'https://images.unsplash.com/photo-1610348725531-843dff563e2c?w=500&auto=format&fit=crop&q=80',
    '7:00 AM - 9:00 PM',
    '{"instant": true, "morning": true, "evening": true}'::jsonb,
    10.00,
    5.00,
    '{"morning_cutoff": "22:00", "evening_cutoff": "16:00"}'::jsonb,
    'freshveggies@ybl',
    'approved',
    4.75,
    15,
    true
)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 4. FREQUENT ITEMS (Quick catalog for customers)
-- ------------------------------------------------------------------------------
INSERT INTO public.frequent_items (shop_id, name, unit, price)
VALUES
    -- Balaji Kirana
    ('e0000000-0000-0000-0000-000000000001', 'Aashirvaad Shudh Chakki Atta', '5kg', 245.00),
    ('e0000000-0000-0000-0000-000000000001', 'Tata Salt Vacuum Evaporated', '1kg', 28.00),
    ('e0000000-0000-0000-0000-000000000001', 'Fortune Sunlite Sunflower Oil', '1L', 135.00),
    ('e0000000-0000-0000-0000-000000000001', 'Toor Dal Premium Desi', '1kg', 165.00),
    ('e0000000-0000-0000-0000-000000000001', 'Sugar (Madhu / Crystal)', '1kg', 48.00),
    -- Vijaya Dairy
    ('e0000000-0000-0000-0000-000000000002', 'Heritage Toned Milk', '500ml', 29.00),
    ('e0000000-0000-0000-0000-000000000002', 'Vijaya Standardized Milk', '500ml', 32.00),
    ('e0000000-0000-0000-0000-000000000002', 'Fresh Malai Paneer', '200gm', 90.00),
    ('e0000000-0000-0000-0000-000000000002', 'Fresh Pouch Curd', '500gm', 38.00),
    -- Fresh Veggies
    ('e0000000-0000-0000-0000-000000000003', 'Country Tomatoes (Nattu)', '1kg', 35.00),
    ('e0000000-0000-0000-0000-000000000003', 'Onions Grade A', '1kg', 40.00),
    ('e0000000-0000-0000-0000-000000000003', 'Fresh Potatoes', '1kg', 30.00),
    ('e0000000-0000-0000-0000-000000000003', 'Green Chillies & Coriander Bunch', 'pack', 20.00)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------------------------
-- 5. SAMPLE ORDERS & CHATS
-- ------------------------------------------------------------------------------
INSERT INTO public.orders (
    id, customer_id, shop_id, slot_type, delivery_date, status, 
    delivery_fee, subtotal, total, payment_status, notes
)
VALUES
(
    'f0000000-0000-0000-0000-000000000001',
    'd0000000-0000-0000-0000-000000000001', -- Sita Devi
    'e0000000-0000-0000-0000-000000000001', -- Balaji Kirana
    'morning',
    CURRENT_DATE,
    'delivered',
    5.00,
    308.00,
    313.00,
    'paid_cod',
    'Please leave at door if doorbell not answered'
),
(
    'f0000000-0000-0000-0000-000000000002',
    'd0000000-0000-0000-0000-000000000002', -- Srinivasa Rao
    'e0000000-0000-0000-0000-000000000002', -- Vijaya Dairy
    'instant',
    CURRENT_DATE,
    'out_for_delivery',
    10.00,
    148.00,
    158.00,
    'unpaid',
    'Immediate need for morning pooja'
)
ON CONFLICT (id) DO NOTHING;

-- Order Items for Delivered Order
INSERT INTO public.order_items (order_id, name, qty, unit, price, available)
VALUES
    ('f0000000-0000-0000-0000-000000000001', 'Aashirvaad Shudh Chakki Atta', 1, '5kg', 245.00, true),
    ('f0000000-0000-0000-0000-000000000001', 'Tata Salt Vacuum Evaporated', 1, '1kg', 28.00, true),
    ('f0000000-0000-0000-0000-000000000001', 'Fresh Pouch Curd', 1, '500gm', 35.00, true);

-- Messages on Delivered Order
INSERT INTO public.messages (id, order_id, sender_id, type, body, created_at)
VALUES
    (
        '10000000-0000-0000-0000-000000000001',
        'f0000000-0000-0000-0000-000000000001',
        'd0000000-0000-0000-0000-000000000001',
        'text',
        'Namaste Balaji garu, please send 1 pack 5kg Atta, 1 packet Tata salt, and 1 curd packet in morning 7 AM slot.',
        NOW() - INTERVAL '3 hours'
    ),
    (
        '10000000-0000-0000-0000-000000000002',
        'f0000000-0000-0000-0000-000000000001',
        'b0000000-0000-0000-0000-000000000001',
        'bill',
        'Here is your itemized bill. Total: ₹313 (includes ₹5 morning delivery)',
        NOW() - INTERVAL '2 hours'
    ),
    (
        '10000000-0000-0000-0000-000000000003',
        'f0000000-0000-0000-0000-000000000001',
        'd0000000-0000-0000-0000-000000000001',
        'text',
        'Confirmed. Please bring change for ₹500.',
        NOW() - INTERVAL '1 hour 50 minutes'
    );

-- Review for Delivered Order
INSERT INTO public.reviews (order_id, shop_id, customer_id, stars, comment)
VALUES (
    'f0000000-0000-0000-0000-000000000001',
    'e0000000-0000-0000-0000-000000000001',
    'd0000000-0000-0000-0000-000000000001',
    5,
    'Always punctual at 7:00 AM! Excellent fresh goods.'
)
ON CONFLICT (order_id) DO NOTHING;
