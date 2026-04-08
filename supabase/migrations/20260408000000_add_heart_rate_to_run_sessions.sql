-- Add heart rate columns to run_sessions for HealthKit integration.
-- Both columns are optional; legacy rows remain NULL.

ALTER TABLE public.run_sessions
    ADD COLUMN IF NOT EXISTS avg_heart_rate SMALLINT,
    ADD COLUMN IF NOT EXISTS max_heart_rate SMALLINT;
