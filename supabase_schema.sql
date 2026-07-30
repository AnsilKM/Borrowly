-- ============================================================
-- BORROWLY SUPABASE DATABASE SCHEMA & MIGRATION SCRIPT
-- ============================================================

-- 1. ENABLE POSTGIS SPATIAL EXTENSION FOR HYPER-LOCAL RADIUS SEARCH
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  location GEOGRAPHY(POINT, 4326),
  location_name TEXT,
  search_radius_km INT DEFAULT 5,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ITEMS TABLE & SPATIAL GIST INDEX
CREATE TABLE IF NOT EXISTS public.items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  owner_name TEXT NOT NULL,
  owner_avatar TEXT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'tools',
  daily_price NUMERIC(10, 2) DEFAULT 0.00,
  is_free BOOLEAN DEFAULT FALSE,
  deposit_amount NUMERIC(10, 2) DEFAULT 0.00,
  images TEXT[] NOT NULL DEFAULT '{}',
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  location_name TEXT NOT NULL,
  distance_km NUMERIC(5, 2) DEFAULT 1.0,
  is_available BOOLEAN DEFAULT TRUE,
  rating_score NUMERIC(3, 2) DEFAULT 5.00,
  review_count INT DEFAULT 0,
  owner_response_rate TEXT DEFAULT '< 30 mins',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fast Spatial Radius Search Index (< 5ms response time)
CREATE INDEX IF NOT EXISTS items_geo_idx ON public.items USING GIST (location);

-- 4. POSTGIS HYPER-LOCAL RADIUS SEARCH FUNCTION
CREATE OR REPLACE FUNCTION get_nearby_items(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION
)
RETURNS SETOF public.items AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.items
  WHERE ST_DWithin(
    location,
    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
    radius_km * 1000
  )
  AND is_available = TRUE
  ORDER BY ST_Distance(
    location,
    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
  ) ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. BORROW REQUESTS TABLE (PHYSICAL CASH HANDOVER)
CREATE TABLE IF NOT EXISTS public.borrow_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES public.items(id) ON DELETE CASCADE,
  item_title TEXT NOT NULL,
  item_image TEXT NOT NULL,
  borrower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  borrower_name TEXT NOT NULL,
  borrower_avatar TEXT,
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  owner_name TEXT NOT NULL,
  owner_avatar TEXT,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  total_price NUMERIC(10, 2) DEFAULT 0.00,
  deposit_amount NUMERIC(10, 2) DEFAULT 0.00,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, accepted, active, completed, cancelled
  handover_location TEXT NOT NULL,
  payment_type TEXT NOT NULL DEFAULT 'physical_cash',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. CONVERSATIONS & MESSAGES TABLES
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
  item_title TEXT NOT NULL,
  item_image TEXT NOT NULL,
  other_participant_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  other_participant_name TEXT NOT NULL,
  other_participant_avatar TEXT,
  last_message TEXT DEFAULT '',
  last_message_time TIMESTAMPTZ DEFAULT NOW(),
  unread_count INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  text TEXT NOT NULL,
  image_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Realtime WebSockets for Messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

-- 7. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'system',
  is_read BOOLEAN DEFAULT FALSE,
  target_route TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
