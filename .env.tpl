# Run-Jin Environment Variables
# This file is a template for 1Password secret injection.
# Usage: op inject -i .env.tpl -o .env
# Or use: make env

# Supabase
SUPABASE_URL=op://run-jin/supabase/url
SUPABASE_ANON_KEY=op://run-jin/supabase/anon-key
SUPABASE_SERVICE_ROLE_KEY=op://run-jin/supabase/service-role-key
SUPABASE_DB_PASSWORD=op://run-jin/supabase/db-password

# Firebase
FIREBASE_API_KEY=op://run-jin/firebase/api-key
FIREBASE_PROJECT_ID=op://run-jin/firebase/project-id

# AdMob (Phase 6)
# ADMOB_APP_ID=op://run-jin/admob/app-id
# ADMOB_BANNER_ID=op://run-jin/admob/banner-id
