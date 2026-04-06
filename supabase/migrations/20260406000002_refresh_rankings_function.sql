-- RPC function to refresh the rankings materialized view
-- Called by the refresh-rankings Edge Function (cron)
CREATE OR REPLACE FUNCTION refresh_rankings_territory()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY rankings_territory;
END;
$$;

-- Only service_role can call this function
REVOKE ALL ON FUNCTION refresh_rankings_territory() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION refresh_rankings_territory() TO service_role;
