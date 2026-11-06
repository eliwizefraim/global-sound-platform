import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

dotenv.config();
const app = express();
const port = Number(process.env.PORT || 3000);
const frontendDir = fileURLToPath(new URL('./frontend/', import.meta.url));
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: process.env.FRONTEND_ORIGIN ? process.env.FRONTEND_ORIGIN.split(',').map(v => v.trim()) : true }));
app.use(express.json({ limit: '1mb' }));
app.get('/health', (_req, res) => res.json({ ok: true, service: 'global-sound-platform-api' }));
app.get('/api/v1', (_req, res) => res.json({ name: 'Global Sound Platform API', version: '1.0.0' }));
app.get('/api/v1/me', async (req, res) => {
  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!token) return res.status(401).json({ error: 'Missing bearer token' });
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) return res.status(503).json({ error: 'Supabase server configuration is missing' });
  const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return res.status(401).json({ error: 'Invalid or expired session' });
  return res.json({ id: data.user.id, email: data.user.email });
});
app.use(express.static(frontendDir));
app.get('*', (_req, res) => res.sendFile(path.join(frontendDir, 'index.html')));
app.listen(port, () => console.log(`Global Sound Platform listening on ${port}`));
