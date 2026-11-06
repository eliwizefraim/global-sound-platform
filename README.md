# Global Sound Platform

Mobile-first music discovery and community MVP for listeners and independent artists.

## Current web MVP
- Supabase email/password sign-up, sign-in and sign-out.
- Browse approved public tracks and play audio using short-lived signed Storage URLs.
- Read and publish community posts.
- Responsive single-page interface served by the Express app.

Artist upload/moderation screens, admin dashboard, payments, G.S Coins transactions, live rooms, AI music-industry assistant and Android packaging are **not yet implemented**.

## Run locally
Requirements: Node.js 20+ and a Supabase project.

1. Install dependencies: `npm install`
2. Start the server: `npm start` (or `npm run dev`).
3. Open `http://localhost:3000`.
4. In the Account panel, enter the Supabase Project URL and its **anon/public or publishable key**. The browser saves these two public settings locally.
5. Create an account or sign in.

The API exposes `GET /health`, `GET /api/v1`, and authenticated `GET /api/v1/me`.

## Database setup
In Supabase SQL Editor, run these files in order:
1. [001_initial_schema.sql](./001_initial_schema.sql)
2. [002_live_mvp.sql](./002_live_mvp.sql)

Configure Supabase Auth for email/password sign-in and set the correct Site URL / redirect URLs for your deployed website.

## Important security notes
- Use only the public anon/publishable key in the browser. Never put a service-role or secret key in frontend code.
- Keep Row Level Security enabled. Review policies before public launch.
- Coin ledger changes must be performed by trusted server-side payment workflows; never let the browser write wallet entries.
- Only upload or distribute audio when you own or control the required rights. Public release requires trusted moderation.
- This repository is an MVP foundation, not yet production-ready. HTTPS hosting, backups, security review, monitoring, payment verification and licensing are still required.
