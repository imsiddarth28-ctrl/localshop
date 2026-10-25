const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const isProd = process.env.NODE_ENV === 'production';

// ---------------------------------------------------------------------------
// 1. SECURITY HEADERS & APP HARDENING
// ---------------------------------------------------------------------------
// Disable Express fingerprinting header
app.disable('x-powered-by');

// Trust reverse proxy (Render, Vercel, Cloudflare, etc.) for accurate IP rate limiting
app.set('trust proxy', 1);

// Apply Helmet security headers
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        connectSrc: ["'self'", 'https:'],
        objectSrc: ["'none'"],
        upgradeInsecureRequests: isProd ? [] : null,
      },
    },
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);

// ---------------------------------------------------------------------------
// 2. RESTRICTIVE CORS CONFIGURATION
// ---------------------------------------------------------------------------
const configuredOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : [];

const corsOptions = {
  origin: (origin, callback) => {
    // Allow non-browser requests (e.g. mobile apps, server-to-server, curl)
    if (!origin) return callback(null, true);

    // Whitelist rules:
    // 1. Explicitly configured origins
    // 2. Vercel deployments (*.vercel.app)
    // 3. Render endpoints (*.onrender.com)
    // 4. Localhost for development
    if (
      configuredOrigins.includes(origin) ||
      origin.endsWith('.vercel.app') ||
      origin.endsWith('.onrender.com') ||
      /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
    ) {
      return callback(null, true);
    }

    return callback(new Error('Blocked by CORS policy'));
  },
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-api-key', 'apikey'],
  credentials: true,
  maxAge: 86400, // Cache preflight for 24h
};

app.use(cors(corsOptions));

// ---------------------------------------------------------------------------
// 3. REQUEST BODY LIMITS & PARSERS (DoS mitigation)
// ---------------------------------------------------------------------------
app.use(express.json({ limit: '50kb' }));
app.use(express.urlencoded({ extended: false, limit: '50kb' }));

// ---------------------------------------------------------------------------
// 4. RATE LIMITING (Brute-force and DDoS protection)
// ---------------------------------------------------------------------------
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // Max 200 requests per 15 minutes per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests from this IP. Please try again after 15 minutes.' },
});

const notifyLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 30, // Max 30 push notification dispatches per 5 minutes per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Notification rate limit exceeded. Please wait before retrying.' },
});

const colonyLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 30, // Max 30 lookups per minute per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many colony verification attempts. Please wait.' },
});

app.use('/api/', generalLimiter);

// ---------------------------------------------------------------------------
// 5. SANITIZATION HELPER
// ---------------------------------------------------------------------------
function sanitizeInput(str, maxLength = 255) {
  if (typeof str !== 'string') return '';
  return str
    .replace(/<[^>]*>/g, '') // Strip HTML tags (XSS protection)
    .replace(/[\r\n\t]+/g, ' ')
    .trim()
    .slice(0, maxLength);
}

// ---------------------------------------------------------------------------
// 6. HEALTH CHECKS
// ---------------------------------------------------------------------------
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'online',
    service: 'The Local Shop Backend API',
    version: '1.1.0',
    environment: isProd ? 'production' : 'development',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: 'GET /health',
      fcmSender: 'POST /api/notify',
      colonyValidate: 'GET /api/colony/:code',
    },
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
  });
});

// ---------------------------------------------------------------------------
// 7. FCM PUSH NOTIFICATION RELAY (Authenticated & Sanitized)
// ---------------------------------------------------------------------------
app.post('/api/notify', notifyLimiter, async (req, res) => {
  try {
    // Optional API key enforcement if configured
    const requiredApiKey = process.env.NOTIFY_API_KEY;
    if (requiredApiKey) {
      const clientKey = req.headers['x-api-key'] || req.headers['authorization']?.replace(/^Bearer\s+/i, '');
      if (clientKey !== requiredApiKey) {
        return res.status(401).json({ error: 'Unauthorized: Invalid or missing API key.' });
      }
    }

    const { token, title, body, data } = req.body;

    if (!token || typeof token !== 'string' || token.trim().length === 0) {
      return res.status(400).json({ error: 'Missing or invalid required field: token' });
    }

    if (!title || typeof title !== 'string' || title.trim().length === 0) {
      return res.status(400).json({ error: 'Missing or invalid required field: title' });
    }

    if (!body || typeof body !== 'string' || body.trim().length === 0) {
      return res.status(400).json({ error: 'Missing or invalid required field: body' });
    }

    const cleanTitle = sanitizeInput(title, 120);
    const cleanBody = sanitizeInput(body, 500);

    const supabaseUrl = process.env.SUPABASE_URL;
    if (!supabaseUrl) {
      return res.status(503).json({ error: 'SUPABASE_URL environment variable is not configured.' });
    }

    const edgeFunctionUrl = `${supabaseUrl}/functions/v1/fcm-sender`;

    // Relay to Supabase Edge Function fcm-sender
    const response = await fetch(edgeFunctionUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        token: token.trim(),
        title: cleanTitle,
        body: cleanBody,
        data: typeof data === 'object' && data !== null ? data : {},
      }),
    });

    const result = await response.json().catch(() => ({}));

    if (!response.ok) {
      return res.status(response.status).json({
        error: 'FCM relay failed',
        details: isProd ? undefined : result,
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Notification dispatched successfully',
    });
  } catch (error) {
    console.error('Notification dispatch error:', error.message);
    return res.status(500).json({
      error: 'Internal notification relay error',
      message: isProd ? 'Internal Server Error' : error.message,
    });
  }
});

// ---------------------------------------------------------------------------
// 8. COLONY VALIDATION HELPER (Strict Regex & Param Validation)
// ---------------------------------------------------------------------------
const COLONY_CODE_REGEX = /^[A-Z0-9]{4,10}$/;

app.get('/api/colony/:code', colonyLimiter, async (req, res) => {
  try {
    const rawCode = (req.params.code || '').trim().toUpperCase();

    if (!COLONY_CODE_REGEX.test(rawCode)) {
      return res.status(400).json({
        code: rawCode,
        valid: false,
        error: 'Invalid colony code format. Expected 4-10 alphanumeric characters (e.g. GRN101).',
      });
    }

    const supabaseUrl = process.env.SUPABASE_URL;
    const anonKey = process.env.SUPABASE_ANON_KEY;

    if (!supabaseUrl || !anonKey) {
      return res.status(503).json({
        error: 'Supabase credentials not configured in environment variables.',
      });
    }

    const rpcRes = await fetch(`${supabaseUrl}/rest/v1/rpc/validate_colony_join_code`, {
      method: 'POST',
      headers: {
        apikey: anonKey,
        Authorization: `Bearer ${anonKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ p_join_code: rawCode }),
    });

    const data = await rpcRes.json();
    return res.status(200).json({
      code: rawCode,
      valid: Array.isArray(data) && data.length > 0,
      data: Array.isArray(data) ? data : [],
    });
  } catch (err) {
    console.error('Colony validation error:', err.message);
    return res.status(500).json({
      error: isProd ? 'Colony verification failed' : err.message,
    });
  }
});

// ---------------------------------------------------------------------------
// 9. 404 & GLOBAL ERROR HANDLER
// ---------------------------------------------------------------------------
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err.message);
  if (res.headersSent) {
    return next(err);
  }
  return res.status(500).json({
    error: 'Internal server error',
    message: isProd ? 'An unexpected error occurred.' : err.message,
  });
});

// ---------------------------------------------------------------------------
// 10. SERVER START
// ---------------------------------------------------------------------------
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[SECURITY] The Local Shop backend running on port ${PORT} (env: ${process.env.NODE_ENV || 'development'})`);
});
