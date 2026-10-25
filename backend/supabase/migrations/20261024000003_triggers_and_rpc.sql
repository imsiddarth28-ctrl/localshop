-- ==============================================================================
-- THE LOCAL SHOP: 03 - TRIGGERS, RPC FUNCTIONS & REALTIME
-- ==============================================================================

-- ==============================================================================
-- 1. TRIGGER: REJECT APPROVING SHOP IF COLONY MAX_SHOPS REACHED
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.check_colony_max_shops()
RETURNS TRIGGER AS $$
DECLARE
    v_max_shops INTEGER;
    v_approved_count INTEGER;
BEGIN
    -- Check only when a shop is being approved or inserted as approved
    IF NEW.status = 'approved' AND (TG_OP = 'INSERT' OR OLD.status != 'approved') THEN
        -- Fetch max allowed shops for this colony
        SELECT max_shops INTO v_max_shops
        FROM public.colonies
        WHERE id = NEW.colony_id;

        IF v_max_shops IS NULL THEN
            RAISE EXCEPTION 'Colony not found: %', NEW.colony_id;
        END IF;

        -- Count existing approved shops in this colony
        SELECT COUNT(*) INTO v_approved_count
        FROM public.shops
        WHERE colony_id = NEW.colony_id 
          AND status = 'approved'
          AND id != NEW.id;

        IF v_approved_count >= v_max_shops THEN
            RAISE EXCEPTION 'Cannot approve shop: Colony % already has % approved shops (maximum allowed is %)', 
                NEW.colony_id, v_approved_count, v_max_shops;
        END IF;
    END IF;

    -- Prevent non-admins from changing shop status or colony_id
    IF TG_OP = 'UPDATE' AND NOT public.is_admin() THEN
        IF NEW.status != OLD.status THEN
            RAISE EXCEPTION 'Only an administrator can change shop approval status';
        END IF;
        IF NEW.colony_id != OLD.colony_id THEN
            RAISE EXCEPTION 'Shop colony assignment cannot be altered';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_check_colony_max_shops ON public.shops;
CREATE TRIGGER trg_check_colony_max_shops
    BEFORE INSERT OR UPDATE ON public.shops
    FOR EACH ROW
    EXECUTE FUNCTION public.check_colony_max_shops();

-- ==============================================================================
-- 2. RPC: JOIN CODE VALIDATION (Server-side only, never exposes join code list)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.validate_colony_join_code(p_join_code TEXT)
RETURNS TABLE (
    colony_id UUID,
    colony_name TEXT,
    max_shops INTEGER,
    approved_shops_count BIGINT
) AS $$
DECLARE
    v_normalized_code TEXT;
BEGIN
    v_normalized_code := UPPER(TRIM(p_join_code));

    RETURN QUERY
    SELECT 
        c.id AS colony_id,
        c.name AS colony_name,
        c.max_shops,
        COUNT(s.id) FILTER (WHERE s.status = 'approved') AS approved_shops_count
    FROM public.colonies c
    LEFT JOIN public.shops s ON s.colony_id = c.id
    WHERE c.join_code = v_normalized_code
    GROUP BY c.id, c.name, c.max_shops;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.validate_colony_join_code(TEXT) TO anon, authenticated;

-- ==============================================================================
-- 3. RATE LIMITING RPCs (5 failed attempts -> 15 min lock)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.check_login_rate_limit(p_phone TEXT)
RETURNS TABLE (
    is_locked BOOLEAN,
    minutes_remaining INTEGER,
    failed_attempts INTEGER
) AS $$
DECLARE
    v_record public.login_rate_limits%ROWTYPE;
    v_rem INTEGER := 0;
BEGIN
    SELECT * INTO v_record FROM public.login_rate_limits WHERE phone = p_phone;

    IF FOUND THEN
        IF v_record.locked_until IS NOT NULL AND v_record.locked_until > NOW() THEN
            v_rem := CEIL(EXTRACT(EPOCH FROM (v_record.locked_until - NOW())) / 60.0)::INTEGER;
            RETURN QUERY SELECT TRUE, v_rem, v_record.failed_attempts;
            RETURN;
        ELSE
            -- Lock expired; reset attempts if lock passed
            IF v_record.locked_until IS NOT NULL AND v_record.locked_until <= NOW() THEN
                UPDATE public.login_rate_limits
                SET failed_attempts = 0, locked_until = NULL
                WHERE phone = p_phone;
                RETURN QUERY SELECT FALSE, 0, 0;
                RETURN;
            END IF;
            RETURN QUERY SELECT FALSE, 0, v_record.failed_attempts;
            RETURN;
        END IF;
    ELSE
        RETURN QUERY SELECT FALSE, 0, 0;
        RETURN;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.check_login_rate_limit(TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.record_login_attempt(
    p_phone TEXT,
    p_success BOOLEAN
)
RETURNS TABLE (
    is_locked BOOLEAN,
    minutes_remaining INTEGER,
    current_failed_attempts INTEGER
) AS $$
DECLARE
    v_record public.login_rate_limits%ROWTYPE;
    v_new_attempts INTEGER := 0;
    v_locked_until TIMESTAMPTZ := NULL;
    v_rem INTEGER := 0;
BEGIN
    IF p_success THEN
        -- Clear rate limits on successful login
        DELETE FROM public.login_rate_limits WHERE phone = p_phone;
        RETURN QUERY SELECT FALSE, 0, 0;
        RETURN;
    END IF;

    -- Failed attempt:
    SELECT * INTO v_record FROM public.login_rate_limits WHERE phone = p_phone;

    IF NOT FOUND THEN
        v_new_attempts := 1;
        INSERT INTO public.login_rate_limits (phone, failed_attempts, last_attempt_at)
        VALUES (p_phone, 1, NOW());
        RETURN QUERY SELECT FALSE, 0, 1;
        RETURN;
    END IF;

    -- If already locked, keep locked
    IF v_record.locked_until IS NOT NULL AND v_record.locked_until > NOW() THEN
        v_rem := CEIL(EXTRACT(EPOCH FROM (v_record.locked_until - NOW())) / 60.0)::INTEGER;
        RETURN QUERY SELECT TRUE, v_rem, v_record.failed_attempts;
        RETURN;
    END IF;

    -- Increment attempts
    v_new_attempts := v_record.failed_attempts + 1;
    IF v_new_attempts >= 5 THEN
        v_locked_until := NOW() + INTERVAL '15 minutes';
        UPDATE public.login_rate_limits
        SET failed_attempts = v_new_attempts,
            last_attempt_at = NOW(),
            locked_until = v_locked_until
        WHERE phone = p_phone;

        RETURN QUERY SELECT TRUE, 15, v_new_attempts;
        RETURN;
    ELSE
        UPDATE public.login_rate_limits
        SET failed_attempts = v_new_attempts,
            last_attempt_at = NOW()
        WHERE phone = p_phone;

        RETURN QUERY SELECT FALSE, 0, v_new_attempts;
        RETURN;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.record_login_attempt(TEXT, BOOLEAN) TO anon, authenticated;

-- ==============================================================================
-- 4. TRIGGER: UPDATE SHOP RATING ON NEW REVIEW
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.update_shop_rating()
RETURNS TRIGGER AS $$
DECLARE
    v_avg NUMERIC(3,2);
    v_count INTEGER;
BEGIN
    SELECT COALESCE(AVG(stars), 5.0)::NUMERIC(3,2), COUNT(*)
    INTO v_avg, v_count
    FROM public.reviews
    WHERE shop_id = NEW.shop_id;

    UPDATE public.shops
    SET rating = v_avg,
        total_reviews = v_count,
        updated_at = NOW()
    WHERE id = NEW.shop_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_update_shop_rating ON public.reviews;
CREATE TRIGGER trg_update_shop_rating
    AFTER INSERT OR UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.update_shop_rating();

-- ==============================================================================
-- 5. REALTIME SETUP
-- Enable Realtime on Orders and Messages
-- ==============================================================================
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Set replica identity to full so that realtime events have full payload
ALTER TABLE public.orders REPLICA IDENTITY FULL;
ALTER TABLE public.messages REPLICA IDENTITY FULL;

-- ==============================================================================
-- 6. PG_CRON: 30-DAY CHAT MEDIA CLEANUP (If pg_cron enabled)
-- ==============================================================================
DO $do$ BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    -- Run daily at 3:00 AM UTC
    PERFORM cron.schedule(
        'delete-old-chat-media',
        '0 3 * * *',
        $cron$
        DELETE FROM public.messages 
        WHERE media_url IS NOT NULL 
          AND created_at < NOW() - INTERVAL '30 days';
        $cron$
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'pg_cron not available or not permitted in this environment; skipping automated cron schedule.';
END $do$;

