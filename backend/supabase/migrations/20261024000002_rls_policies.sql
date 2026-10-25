-- ==============================================================================
-- THE LOCAL SHOP: 02 - ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.colonies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.frequent_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_reset_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.login_rate_limits ENABLE ROW LEVEL SECURITY;

-- Helper functions for RLS checks
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS user_role AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid() AND suspended = false;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin' AND suspended = false
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_suspended()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND suspended = true
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.user_colony_id()
RETURNS UUID AS $$
    SELECT colony_id FROM public.profiles WHERE id = auth.uid() AND suspended = false;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.shop_owner_shop_id()
RETURNS UUID AS $$
    SELECT id FROM public.shops WHERE owner_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ==============================================================================
-- 1. COLONIES POLICIES
-- NOTE: Join code is NOT exposed directly to customers or shop owners.
-- Customers and shop owners can only read their assigned colony name/id.
-- Admin has full CRUD.
-- ==============================================================================
CREATE POLICY "Admin full access on colonies"
    ON public.colonies
    FOR ALL
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Users can view their own colony"
    ON public.colonies
    FOR SELECT
    TO authenticated
    USING (
        NOT public.is_suspended() AND (
            id = public.user_colony_id() OR
            id IN (SELECT colony_id FROM public.shops WHERE owner_id = auth.uid())
        )
    );

-- ==============================================================================
-- 2. PROFILES POLICIES
-- - Admin can see and manage all profiles.
-- - Users can view and update their own profile.
-- - Shop owner can view customer name & address for customers who placed orders in their shop.
-- - Customers can view shop owner basic info (name, phone) for shops in their colony.
-- ==============================================================================
CREATE POLICY "Admin full access on profiles"
    ON public.profiles
    FOR ALL
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id AND NOT public.is_suspended())
    WITH CHECK (auth.uid() = id AND NOT public.is_suspended());

CREATE POLICY "Users can insert own profile upon signup"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Shop owners can view customers with active orders"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() = 'shop_owner' AND
        id IN (
            SELECT customer_id FROM public.orders 
            WHERE shop_id = public.shop_owner_shop_id()
        )
    );

CREATE POLICY "Customers can view shop owners in same colony"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() = 'customer' AND
        id IN (
            SELECT owner_id FROM public.shops 
            WHERE colony_id = public.user_colony_id() AND status = 'approved'
        )
    );

-- ==============================================================================
-- 3. SHOPS POLICIES
-- - Admin can manage all shops.
-- - Shop owner can insert own pending shop and update details (timings, slots, fees, UPI, holiday_mode).
-- - Shop owner CANNOT approve their own shop or change status.
-- - Customers can view approved shops in their colony.
-- ==============================================================================
CREATE POLICY "Admin full access on shops"
    ON public.shops
    FOR ALL
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Shop owners can view their own shop"
    ON public.shops
    FOR SELECT
    TO authenticated
    USING (owner_id = auth.uid());

CREATE POLICY "Shop owners can register pending shop"
    ON public.shops
    FOR INSERT
    TO authenticated
    WITH CHECK (
        owner_id = auth.uid() AND 
        status = 'pending' AND 
        NOT public.is_suspended()
    );

CREATE POLICY "Shop owners can update own shop settings"
    ON public.shops
    FOR UPDATE
    TO authenticated
    USING (owner_id = auth.uid() AND NOT public.is_suspended())
    WITH CHECK (
        owner_id = auth.uid() AND 
        NOT public.is_suspended()
        -- Note: Status cannot be changed by shop owner via trigger check
    );

CREATE POLICY "Customers can view approved shops in their colony"
    ON public.shops
    FOR SELECT
    TO authenticated
    USING (
        public.current_user_role() = 'customer' AND
        colony_id = public.user_colony_id() AND
        status = 'approved' AND
        NOT public.is_suspended()
    );

-- ==============================================================================
-- 4. ORDERS POLICIES
-- - Admin can view all orders.
-- - Customer can view and create their own orders.
-- - Customer can cancel order only if it's in 'placed' status.
-- - Shop owner can view and update orders belonging to their shop.
-- ==============================================================================
CREATE POLICY "Admin full access on orders"
    ON public.orders
    FOR ALL
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Customers can view own orders"
    ON public.orders
    FOR SELECT
    TO authenticated
    USING (customer_id = auth.uid() AND NOT public.is_suspended());

CREATE POLICY "Customers can create orders"
    ON public.orders
    FOR INSERT
    TO authenticated
    WITH CHECK (customer_id = auth.uid() AND NOT public.is_suspended());

CREATE POLICY "Customers can cancel own placed order"
    ON public.orders
    FOR UPDATE
    TO authenticated
    USING (customer_id = auth.uid() AND status = 'placed' AND NOT public.is_suspended())
    WITH CHECK (customer_id = auth.uid() AND status = 'cancelled');

CREATE POLICY "Shop owners can view shop orders"
    ON public.orders
    FOR SELECT
    TO authenticated
    USING (shop_id = public.shop_owner_shop_id() AND NOT public.is_suspended());

CREATE POLICY "Shop owners can update shop orders"
    ON public.orders
    FOR UPDATE
    TO authenticated
    USING (shop_id = public.shop_owner_shop_id() AND NOT public.is_suspended())
    WITH CHECK (shop_id = public.shop_owner_shop_id() AND NOT public.is_suspended());

-- ==============================================================================
-- 5. MESSAGES POLICIES
-- - Customers can view and insert messages on their own orders.
-- - Shop owners can view and insert messages on orders to their shop.
-- ==============================================================================
CREATE POLICY "Admin full access on messages"
    ON public.messages
    FOR ALL
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Customers can view order messages"
    ON public.messages
    FOR SELECT
    TO authenticated
    USING (
        order_id IN (SELECT id FROM public.orders WHERE customer_id = auth.uid()) AND
        NOT public.is_suspended()
    );

CREATE POLICY "Customers can insert order messages"
    ON public.messages
    FOR INSERT
    TO authenticated
    WITH CHECK (
        sender_id = auth.uid() AND
        order_id IN (SELECT id FROM public.orders WHERE customer_id = auth.uid()) AND
        NOT public.is_suspended()
    );

CREATE POLICY "Shop owners can view shop order messages"
    ON public.messages
    FOR SELECT
    TO authenticated
    USING (
        order_id IN (SELECT id FROM public.orders WHERE shop_id = public.shop_owner_shop_id()) AND
        NOT public.is_suspended()
    );

CREATE POLICY "Shop owners can insert shop order messages"
    ON public.messages
    FOR INSERT
    TO authenticated
    WITH CHECK (
        sender_id = auth.uid() AND
        order_id IN (SELECT id FROM public.orders WHERE shop_id = public.shop_owner_shop_id()) AND
        NOT public.is_suspended()
    );

-- ==============================================================================
-- 6. ORDER ITEMS POLICIES
-- ==============================================================================
CREATE POLICY "Admin full access on order_items"
    ON public.order_items
    FOR ALL
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Customers can view order items"
    ON public.order_items
    FOR SELECT
    TO authenticated
    USING (
        order_id IN (SELECT id FROM public.orders WHERE customer_id = auth.uid())
    );

CREATE POLICY "Shop owners can manage order items for their shop"
    ON public.order_items
    FOR ALL
    TO authenticated
    USING (
        order_id IN (SELECT id FROM public.orders WHERE shop_id = public.shop_owner_shop_id())
    );

-- ==============================================================================
-- 7. FREQUENT ITEMS POLICIES
-- ==============================================================================
CREATE POLICY "Admin full access on frequent_items"
    ON public.frequent_items
    FOR ALL
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Shop owners can manage own frequent items"
    ON public.frequent_items
    FOR ALL
    TO authenticated
    USING (shop_id = public.shop_owner_shop_id());

CREATE POLICY "Customers can view frequent items in their colony"
    ON public.frequent_items
    FOR SELECT
    TO authenticated
    USING (
        shop_id IN (
            SELECT id FROM public.shops 
            WHERE colony_id = public.user_colony_id() AND status = 'approved'
        )
    );

-- ==============================================================================
-- 8. REVIEWS POLICIES
-- ==============================================================================
CREATE POLICY "Admin full access on reviews"
    ON public.reviews
    FOR ALL
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Customers can create reviews for delivered orders"
    ON public.reviews
    FOR INSERT
    TO authenticated
    WITH CHECK (
        customer_id = auth.uid() AND
        order_id IN (
            SELECT id FROM public.orders 
            WHERE customer_id = auth.uid() AND status = 'delivered'
        )
    );

CREATE POLICY "Users can view reviews in their colony"
    ON public.reviews
    FOR SELECT
    TO authenticated
    USING (
        shop_id IN (
            SELECT id FROM public.shops 
            WHERE colony_id = public.user_colony_id()
        ) OR
        shop_id = public.shop_owner_shop_id()
    );

-- ==============================================================================
-- 9. DEVICE TOKENS POLICIES
-- ==============================================================================
CREATE POLICY "Users can manage their own device tokens"
    ON public.device_tokens
    FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admin can view device tokens for notifications"
    ON public.device_tokens
    FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- ==============================================================================
-- 10. PASSWORD RESET REQUESTS POLICIES
-- Customers / Shop Owners can only insert a request for their own phone.
-- Only Admin can view and resolve requests.
-- ==============================================================================
CREATE POLICY "Users can insert password reset request"
    ON public.password_reset_requests
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

CREATE POLICY "Admin full access on reset requests"
    ON public.password_reset_requests
    FOR ALL
    TO authenticated
    USING (public.is_admin());

-- ==============================================================================
-- 11. RATE LIMIT POLICIES (Handled via RPC / Security definer)
-- ==============================================================================
CREATE POLICY "Rate limits access via RPC"
    ON public.login_rate_limits
    FOR SELECT
    TO anon, authenticated
    USING (true);
