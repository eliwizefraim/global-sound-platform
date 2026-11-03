# Architecture and rollout

## Foundation
- One API for website and Android WebView/APK.
- Supabase Auth issues user sessions; API validates bearer tokens.
- PostgreSQL stores profiles, artists, tracks, community posts, playlists and append-only coin ledger.
- Storage buckets should be private by default. Serve approved public tracks through signed URLs/CDN policies.

## Security rules
- Never ship Supabase service-role keys or payment secrets in frontend code.
- Enforce Row Level Security and server-side role checks.
- Verify payment webhooks server-side before crediting coins or activating subscriptions.
- Do not let clients write wallet ledger entries.
- Require rights confirmation and moderation before public music distribution.

## Later modules
1. Auth screens and profile onboarding.
2. Artist upload workflow, private object storage, review and approved playback.
3. Community posts/comments, reporting and moderation.
4. Wallet ledger, idempotent payment webhook and reconciliation.
5. LiveKit rooms with short-lived server-issued tokens.
6. Admin dashboard with audited privileged actions.
7. Android packaging, deep links, background audio and release testing.
