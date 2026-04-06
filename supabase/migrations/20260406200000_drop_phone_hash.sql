-- Remove phone_hash column as phone authentication has been dropped
ALTER TABLE users DROP COLUMN IF EXISTS phone_hash;
