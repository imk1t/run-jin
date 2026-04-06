-- RPC function to find landmarks within a radius of a given point
-- Used by submit-run Edge Function for landmark bonus calculation
CREATE OR REPLACE FUNCTION find_nearby_landmarks(
    cell_lng DOUBLE PRECISION,
    cell_lat DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 200
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    category TEXT,
    bonus_multiplier DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.category,
        l.bonus_multiplier,
        ST_Distance(
            l.location,
            ST_SetSRID(ST_MakePoint(cell_lng, cell_lat), 4326)::geography
        ) AS distance_meters
    FROM landmarks l
    WHERE ST_DWithin(
        l.location,
        ST_SetSRID(ST_MakePoint(cell_lng, cell_lat), 4326)::geography,
        radius_meters
    )
    ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- RPC function to update user aggregate totals after a run
CREATE OR REPLACE FUNCTION update_user_totals(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET
        total_distance_meters = COALESCE(
            (SELECT SUM(distance_meters) FROM run_sessions WHERE user_id = p_user_id),
            0
        ),
        total_cells_owned = COALESCE(
            (SELECT COUNT(*) FROM territory_cells WHERE owner_id = p_user_id),
            0
        ),
        updated_at = now()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;
