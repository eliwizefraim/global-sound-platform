import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createClient } from '@supabase/supabase-js';

const app = express();
const port = Number(process.env.PORT || 3000);

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_ORIGIN
    ? process.env.FRONTEND_ORIGIN.split(',').map(v => v.trim())
    : false,
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '1mb' }));

const hasSupabase = Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY);
const supabase = hasSupabase
  ? createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY, {
      auth: { persistSession: false, autoRefreshToken: false }
    })
  : null;

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'global-sound-platform-api',
    databaseConfigured: Boolean(supabase),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/api/v1', (_req, res) => {
  res.json({
    name: 'Global Sound Platform API',
    version: '1.0.0',
    modules: ['accounts', 'music', 'artists', 'community', 'arena', 'wallet', 'admin'],
    status: 'foundation'
  });
});

// Verify a Supabase access token. Route handlers can use req.user after this middleware.
async function requireUser(req, res, next) {
  if (!supabase) return res.status(503).json({ error: 'Authentication service is not configured.' });
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'Sign-in required.' });
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data?.user) return res.status(401).json({ error: 'Invalid or expired session.' });
  req.user = data.user;
  next();
}

app.get('/api/v1/me', requireUser, (req, res) => {
  res.json({ id: req.user.id, email: req.user.email ?? null });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Unexpected server error.' });
});

app.listen(port, () => {
  console.log(`Global Sound API listening on port ${port}`);
});
