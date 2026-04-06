-- Function to calculate a user's current consecutive run streak (days).
-- Returns the number of consecutive days ending today (or yesterday)
-- on which the user completed at least one run session.
CREATE OR REPLACE FUNCTION calculate_streak(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    streak INTEGER := 0;
    check_date DATE := CURRENT_DATE;
    has_run BOOLEAN;
BEGIN
    LOOP
        SELECT EXISTS (
            SELECT 1 FROM run_sessions
            WHERE user_id = p_user_id
              AND DATE(started_at AT TIME ZONE 'Asia/Tokyo') = check_date
              AND ended_at IS NOT NULL
        ) INTO has_run;

        IF has_run THEN
            streak := streak + 1;
            check_date := check_date - INTERVAL '1 day';
        ELSIF streak = 0 AND check_date = CURRENT_DATE THEN
            -- Allow checking yesterday if no run today yet
            check_date := check_date - INTERVAL '1 day';
        ELSE
            EXIT;
        END IF;
    END LOOP;

    RETURN streak;
END;
$$;
