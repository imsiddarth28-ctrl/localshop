-- ==============================================================================
-- THE LOCAL SHOP: 04 - STORAGE BUCKETS & POLICIES
-- ==============================================================================

-- Create buckets if they do not exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('chat-media', 'chat-media', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'audio/m4a', 'audio/aac', 'audio/mp4', 'audio/mpeg', 'audio/ogg']),
    ('shop-photos', 'shop-photos', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
    ('avatars', 'avatars', true, 3145728, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ==============================================================================
-- STORAGE POLICIES: chat-media (Private bucket)
-- ==============================================================================
DROP POLICY IF EXISTS "Authenticated users can upload chat media" ON storage.objects;
CREATE POLICY "Authenticated users can upload chat media"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'chat-media' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Authenticated users can read chat media" ON storage.objects;
CREATE POLICY "Authenticated users can read chat media"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (bucket_id = 'chat-media');

-- ==============================================================================
-- STORAGE POLICIES: shop-photos (Public read, owner write)
-- ==============================================================================
DROP POLICY IF EXISTS "Anyone can view shop photos" ON storage.objects;
CREATE POLICY "Anyone can view shop photos"
    ON storage.objects
    FOR SELECT
    TO public
    USING (bucket_id = 'shop-photos');

DROP POLICY IF EXISTS "Shop owners and admin can upload shop photos" ON storage.objects;
CREATE POLICY "Shop owners and admin can upload shop photos"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'shop-photos');

DROP POLICY IF EXISTS "Shop owners and admin can update shop photos" ON storage.objects;
CREATE POLICY "Shop owners and admin can update shop photos"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (bucket_id = 'shop-photos');

-- ==============================================================================
-- STORAGE POLICIES: avatars (Public read, user write)
-- ==============================================================================
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Anyone can view avatars"
    ON storage.objects
    FOR SELECT
    TO public
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
CREATE POLICY "Users can upload their own avatar"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'avatars' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
CREATE POLICY "Users can update their own avatar"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'avatars' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

