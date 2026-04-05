# Run-Jin Environment Variables
# This file is a template for 1Password secret injection.
# Usage: op inject -i .env.tpl -o .env
# Or use: make env

# Supabase
SUPABASE_URL=op://run-jin/supabase/url
SUPABASE_ANON_KEY=op://run-jin/supabase/anon-key
SUPABASE_SERVICE_ROLE_KEY=op://run-jin/supabase/service-role-key
SUPABASE_DB_PASSWORD=op://run-jin/supabase/db-password

# Supabase Auth (Apple Sign-In)
SUPABASE_AUTH_APPLE_SECRET=op://run-jin/supabase/apple-auth-secret

# Firebase — configured via GoogleService-Info.plist (gitignored)
# Download from Firebase Console and place at run-jin/GoogleService-Info.plist

# AdMob (Phase 6)
# ADMOB_APP_ID=op://run-jin/admob/app-id
# ADMOB_BANNER_ID=op://run-jin/admob/banner-id
