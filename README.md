# Global Sound

A Supabase-backed music discovery and community app. The current live MVP supports email/password accounts, published music browsing and playback, community posts, and private artist uploads submitted for moderation. It does **not** yet include payment processing, subscriptions, live broadcast rooms, or an Android package.

## Run locally

Requirements: Node.js 20+ and a Supabase project.

1. Install dependencies: `npm install`
2. Copy `.env.example` to `.env` and set `PORT` and `FRONTEND_ORIGIN` as appropriate. The app's Supabase URL and public anon key are entered in the web UI and saved in that browser; never put a service-role key in the frontend.
3. In the Supabase SQL Editor, run `001_initial_schema.sql`, then `002_live_mvp.sql`.
4. Start the app: `npm start` (or `npm run dev`). Open `http://localhost:3000`.
5. In the app, connect using your Supabase Project URL and the **anon/public** key from Project Settings → API.
6. In Supabase Auth settings, configure the local site URL and enable email/password sign-in. Email confirmation behavior is controlled by your Supabase Auth settings.

The API also exposes `GET /health`, `GET /api/v1`, and authenticated `GET /api/v1/me`.

## Live features

- Sign up, sign in, and sign out using Supabase Auth.
- Load approved public tracks and play them through short-lived signed URLs.
- Publish and browse community posts.
- Upload audio files (up to 30 MB) to a private `music` Storage bucket. New artist profiles and tracks remain pending until an administrator reviews them.
- User-submitted tracks cannot set themselves as approved through the policies in `002_live_mvp.sql`.

## Moderation

The included schema intentionally has no browser-based approval action or admin dashboard. To publish a release, a trusted administrator must verify the artist and approve the track in a trusted process. Never use a Supabase service-role key in browser code. Review Supabase Storage, Auth, and database policies before deploying to production.
