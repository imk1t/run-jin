-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- ──────────────────────────────────────
-- users
-- ──────────────────────────────────────
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_hash TEXT,
    display_name TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    team_id UUID,
    prefecture_code SMALLINT,
    municipality_code INTEGER,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    total_distance_meters DOUBLE PRECISION NOT NULL DEFAULT 0,
    total_cells_owned INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_own" ON users
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "users_insert_own" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "users_update_own" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Public read for display_name and avatar (non-anonymous)
CREATE POLICY "users_select_public" ON users
    FOR SELECT USING (is_anonymous = FALSE);

-- ──────────────────────────────────────
-- teams
-- ──────────────────────────────────────
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    color TEXT NOT NULL DEFAULT '#007AFF',
    invite_code TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(6), 'hex'),
    member_count INTEGER NOT NULL DEFAULT 0,
    total_cells_owned INTEGER NOT NULL DEFAULT 0,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teams_select_all" ON teams
    FOR SELECT USING (TRUE);
CREATE POLICY "teams_insert_auth" ON teams
    FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "teams_update_member" ON teams
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.team_id = teams.id)
    );

-- Add FK after teams table exists
ALTER TABLE users ADD CONSTRAINT users_team_fk FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL;

-- ──────────────────────────────────────
-- run_sessions
-- ──────────────────────────────────────
CREATE TABLE run_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    distance_meters DOUBLE PRECISION NOT NULL DEFAULT 0,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    avg_pace_seconds_per_km DOUBLE PRECISION,
    calories INTEGER,
    route GEOGRAPHY(LINESTRING, 4326),
    cells_captured INTEGER NOT NULL DEFAULT 0,
    cells_overridden INTEGER NOT NULL DEFAULT 0,
    idempotency_key TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE run_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "run_sessions_select_own" ON run_sessions
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "run_sessions_insert_own" ON run_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_run_sessions_user_id ON run_sessions(user_id);
CREATE INDEX idx_run_sessions_started_at ON run_sessions(started_at DESC);

-- ──────────────────────────────────────
-- territory_cells
-- ──────────────────────────────────────
CREATE TABLE territory_cells (
    h3_index TEXT PRIMARY KEY,
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    total_distance_meters DOUBLE PRECISION NOT NULL DEFAULT 0,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE territory_cells ENABLE ROW LEVEL SECURITY;

-- Everyone can read territory (public map)
CREATE POLICY "territory_cells_select_all" ON territory_cells
    FOR SELECT USING (TRUE);
-- Write only via Edge Functions (service_role)
CREATE POLICY "territory_cells_insert_service" ON territory_cells
    FOR INSERT WITH CHECK (auth.role() = 'service_role');
CREATE POLICY "territory_cells_update_service" ON territory_cells
    FOR UPDATE USING (auth.role() = 'service_role');

CREATE INDEX idx_territory_cells_owner_id ON territory_cells(owner_id);
CREATE INDEX idx_territory_cells_team_id ON territory_cells(team_id);

-- ──────────────────────────────────────
-- territory_captures (log)
-- ──────────────────────────────────────
CREATE TABLE territory_captures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_session_id UUID NOT NULL REFERENCES run_sessions(id) ON DELETE CASCADE,
    h3_index TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    previous_owner_id UUID REFERENCES users(id),
    distance_meters DOUBLE PRECISION NOT NULL,
    capture_type TEXT NOT NULL CHECK (capture_type IN ('new', 'override')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE territory_captures ENABLE ROW LEVEL SECURITY;

CREATE POLICY "territory_captures_select_own" ON territory_captures
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "territory_captures_insert_service" ON territory_captures
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE INDEX idx_territory_captures_run_session ON territory_captures(run_session_id);
CREATE INDEX idx_territory_captures_h3_index ON territory_captures(h3_index);

-- ──────────────────────────────────────
-- privacy_zones
-- ──────────────────────────────────────
CREATE TABLE privacy_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label TEXT NOT NULL DEFAULT '',
    center GEOGRAPHY(POINT, 4326) NOT NULL,
    radius_meters INTEGER NOT NULL DEFAULT 500,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE privacy_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "privacy_zones_select_own" ON privacy_zones
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "privacy_zones_insert_own" ON privacy_zones
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "privacy_zones_update_own" ON privacy_zones
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "privacy_zones_delete_own" ON privacy_zones
    FOR DELETE USING (auth.uid() = user_id);

-- Max 3 zones per user
CREATE UNIQUE INDEX idx_privacy_zones_user_limit ON privacy_zones(user_id, id);

-- ──────────────────────────────────────
-- achievements (master)
-- ──────────────────────────────────────
CREATE TABLE achievements (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('territory', 'streak', 'distance', 'social')),
    icon TEXT NOT NULL DEFAULT 'star.fill',
    threshold_value DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "achievements_select_all" ON achievements
    FOR SELECT USING (TRUE);

-- ──────────────────────────────────────
-- user_achievements
-- ──────────────────────────────────────
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id TEXT NOT NULL REFERENCES achievements(id),
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, achievement_id)
);

ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_achievements_select_own" ON user_achievements
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_achievements_insert_service" ON user_achievements
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- ──────────────────────────────────────
-- landmarks
-- ──────────────────────────────────────
CREATE TABLE landmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('shrine', 'park', 'station', 'landmark')),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    h3_index TEXT NOT NULL,
    bonus_multiplier DOUBLE PRECISION NOT NULL DEFAULT 2.0,
    prefecture_code SMALLINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE landmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "landmarks_select_all" ON landmarks
    FOR SELECT USING (TRUE);

CREATE INDEX idx_landmarks_h3_index ON landmarks(h3_index);
CREATE INDEX idx_landmarks_location ON landmarks USING gist(location);

-- ──────────────────────────────────────
-- coupons
-- ──────────────────────────────────────
CREATE TABLE coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    store_name TEXT NOT NULL,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    radius_meters INTEGER NOT NULL DEFAULT 500,
    deep_link_url TEXT,
    image_url TEXT,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "coupons_select_active" ON coupons
    FOR SELECT USING (is_active = TRUE AND (expires_at IS NULL OR expires_at > now()));

CREATE INDEX idx_coupons_location ON coupons USING gist(location);

-- ──────────────────────────────────────
-- rankings_territory (materialized view)
-- ──────────────────────────────────────
CREATE MATERIALIZED VIEW rankings_territory AS
SELECT
    u.id AS user_id,
    u.display_name,
    u.prefecture_code,
    u.municipality_code,
    u.team_id,
    COUNT(tc.h3_index) AS cells_owned,
    COALESCE(SUM(tc.total_distance_meters), 0) AS total_distance,
    RANK() OVER (ORDER BY COUNT(tc.h3_index) DESC) AS national_rank
FROM users u
LEFT JOIN territory_cells tc ON tc.owner_id = u.id
WHERE u.is_anonymous = FALSE
GROUP BY u.id, u.display_name, u.prefecture_code, u.municipality_code, u.team_id;

CREATE UNIQUE INDEX idx_rankings_territory_user ON rankings_territory(user_id);
CREATE INDEX idx_rankings_territory_rank ON rankings_territory(national_rank);
CREATE INDEX idx_rankings_territory_prefecture ON rankings_territory(prefecture_code, cells_owned DESC);

-- ──────────────────────────────────────
-- updated_at trigger function
-- ──────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_teams_updated_at BEFORE UPDATE ON teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_territory_cells_updated_at BEFORE UPDATE ON territory_cells
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_privacy_zones_updated_at BEFORE UPDATE ON privacy_zones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
