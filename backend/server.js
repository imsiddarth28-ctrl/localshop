const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({ origin: '*' }));
app.use(express.json());

// ---------------------------------------------------------------------------
// 1. HEALTH CHECKS (Render requirement)
// ---------------------------------------------------------------------------
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'online',
    service: 'The Local Shop Backend API',
    version: '1.0.0',
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
// 2. FCM PUSH NOTIFICATION RELAY
// ---------------------------------------------------------------------------
app.post('/api/notify', async (req, res) => {
  try {
    const { token, title, body, data } = req.body;

    if (!token || !title || !body) {
      return res.status(400).json({
        error: 'Missing required fields: token, title, body are mandatory.',
      });
    }

    const supabaseUrl = process.env.SUPABASE_URL || 'https://cdqszwgemaxinfrzejuu.supabase.co';
    const edgeFunctionUrl = `${supabaseUrl}/functions/v1/fcm-sender`;

    // Relay to Supabase Edge Function fcm-sender
    const response = await fetch(edgeFunctionUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ token, title, body, data }),
    });

    const result = await response.json().catch(() => ({}));

    if (!response.ok) {
      return res.status(response.status).json({
        error: 'FCM relay failed',
        details: result,
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Notification dispatched successfully',
      result,
    });
  } catch (error) {
    console.error('Notification dispatch error:', error);
    return res.status(500).json({
      error: 'Internal notification error',
      message: error.message,
    });
  }
});

// ---------------------------------------------------------------------------
// 3. COLONY VALIDATION HELPER
// ---------------------------------------------------------------------------
app.get('/api/colony/:code', async (req, res) => {
  try {
    const code = (req.params.code || '').trim().toUpperCase();
    const supabaseUrl = process.env.SUPABASE_URL || 'https://cdqszwgemaxinfrzejuu.supabase.co';
    const anonKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNkcXN6d2dlbWF4aW5mcnplanV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI4NTAzMjQsImV4cCI6MjEwODQyNjMyNH0.KivjJ3bVuhfBzysRu-GEuDc4WEBGdSjrfhn1GsQhf3Y';

    const rpcRes = await fetch(`${supabaseUrl}/rest/v1/rpc/validate_colony_join_code`, {
      method: 'POST',
      headers: {
        'apikey': anonKey,
        'Authorization': `Bearer ${anonKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ p_join_code: code }),
    });

    const data = await rpcRes.json();
    return res.status(200).json({ code, valid: Array.isArray(data) && data.length > 0, data });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// Start listening
app.listen(PORT, '0.0.0.0', () => {
  console.log(`The Local Shop backend running on port ${PORT}`);
});
