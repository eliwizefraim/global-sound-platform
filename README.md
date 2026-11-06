# Global Sound Platform

Mobile-first music discovery, community and independent-artist MVP.

## Current web MVP
- Supabase email/password sign-up, sign-in and sign-out.
- Browse approved public tracks and play audio with short-lived signed Storage URLs.
- Read and publish community posts.
- Artist Studio: create an artist profile and submit audio for moderation.
- Audio uploads are limited to 30 MB and require confirmation of distribution rights.
- Express API: `GET /health`, `GET /api/v1`, and authenticated `GET /api/v1/me`.

## Supabase connection
The frontend at `frontend/index.html` is configured with the confirmed Global Sound Platform Supabase Project URL and its public publishable key. These are browser-safe public credentials. Never add a Supabase secret or service-role key to frontend code.

## Database setup
In Supabase SQL Editor, run these migrations in order:
1. `001_initial_schema.sql`
2. `002_live_mvp.sql`
3. `003_auth_profile_trigger.sql`

If migrations 001 and 002 have already been run, run only migration 003 next. It creates a listener profile automatically after a new Supabase Auth signup.

Configure Supabase Authentication for email/password sign-in. After deployment, set the correct Site URL and add the deployed website URL to the Redirect URLs list.

## Run locally
Requirements: Node.js 20+.

1. Install dependencies: `npm install`
2. Start the server: `npm start`
3. Open `http://localhost:3000`.

## Deploy on Render
1. Open Render and choose **New → Blueprint**.
2. Connect GitHub and select `eliwizefraim/global-sound-platform`.
3. Render reads `render.yaml`; create the web service.
4. After deployment, open the generated HTTPS URL and check that `/health` returns `{"ok":true}`.
5. In Supabase → Authentication → URL Configuration, set the deployed website as the Site URL and add it to Redirect URLs.
6. Open the website and test account creation, sign-in, community posts and an artist audio submission.

## Not yet production-ready
G.S Coins payments, verified payment webhooks, live streaming, the full AI music-industry assistant, admin moderation dashboard, Android APK packaging, licensed music catalogue integration, backups, monitoring and independent security testing still require implementation and verification. Keep Row Level Security enabled and review all database/storage policies before public launch. Only upload or distribute recordings when you control the required rights.
