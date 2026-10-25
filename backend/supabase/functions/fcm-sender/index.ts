// ==============================================================================
// THE LOCAL SHOP: EDGE FUNCTION - FCM PUSH NOTIFICATION SENDER (HTTP v1)
// Uses Google Service Account OAuth2 & Firebase Cloud Messaging HTTP v1 API
// ==============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: any;
  old_record: any;
}

function pemToBinary(pem: string): Uint8Array {
  const cleanPem = pem
    .replace(/-----BEGIN [A-Z ]+-----/g, "")
    .replace(/-----END [A-Z ]+-----/g, "")
    .replace(/\s+/g, "");
  const raw = atob(cleanPem);
  const binary = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) {
    binary[i] = raw.charCodeAt(i);
  }
  return binary;
}

function base64UrlEncode(data: Uint8Array | string): string {
  const str = typeof data === "string" ? data : String.fromCharCode(...data);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getGoogleAccessToken(serviceAccount: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaim = base64UrlEncode(JSON.stringify(claimSet));
  const unsignedToken = `${encodedHeader}.${encodedClaim}`;

  const keyBytes = pemToBinary(serviceAccount.private_key);
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(unsignedToken)
  );

  const jwt = `${unsignedToken}.${base64UrlEncode(new Uint8Array(signature))}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await response.json();
  if (!response.ok) {
    throw new Error(`Google OAuth token exchange failed: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "";

    const adminClient = createClient(supabaseUrl, supabaseServiceKey);
    const payload: WebhookPayload = await req.json();

    const { table, type, record, old_record } = payload;
    let targetUserId: string | null = null;
    let title = "The Local Shop";
    let body = "";
    let dataPayload: Record<string, string> = { table, event: type };

    if (table === "orders") {
      if (type === "INSERT") {
        // Customer placed a new order -> Notify Shop Owner
        const { data: shop } = await adminClient
          .from("shops")
          .select("owner_id, name")
          .eq("id", record.shop_id)
          .single();

        if (shop) {
          targetUserId = shop.owner_id;
          title = `🛍️ New Order #${record.order_number || ""}`;
          body = `Slot: ${record.slot_type?.toUpperCase() ?? "INSTANT"} | Total: ₹${record.total}. Tap to view order.`;
          dataPayload.orderId = record.id;
        }
      } else if (type === "UPDATE" && record.status !== old_record.status) {
        // Shop status changed -> Notify Customer
        targetUserId = record.customer_id;
        dataPayload.orderId = record.id;

        switch (record.status) {
          case "accepted":
            title = "Order Accepted";
            body = "The shopkeeper has accepted your order.";
            break;
          case "preparing":
            title = "Packing Items";
            body = "Your items are being packed.";
            break;
          case "out_for_delivery":
            title = "Out for Delivery! 🛵";
            body = "Your delivery is on the way to your flat.";
            break;
          case "delivered":
            title = "Delivered! ✅";
            body = "Your order was marked delivered. Thank you!";
            break;
          case "cancelled":
            title = "Order Cancelled";
            body = "Your order was cancelled.";
            break;
          default:
            title = "Order Update";
            body = `Order status updated to ${record.status}.`;
        }
      }
    } else if (table === "messages" && type === "INSERT") {
      // New chat message / Bill sent
      const { data: order } = await adminClient
        .from("orders")
        .select("customer_id, shop_id, shops(owner_id, name)")
        .eq("id", record.order_id)
        .single();

      if (order) {
        dataPayload.orderId = record.order_id;
        dataPayload.messageId = record.id;

        const shopOwnerId = (order.shops as any)?.owner_id;
        const shopName = (order.shops as any)?.name ?? "The Local Shop";

        if (record.sender_id === order.customer_id) {
          // Sent by customer -> Notify shopkeeper
          targetUserId = shopOwnerId;
          title = `💬 Order Message`;
          body = record.type === "voice"
            ? "🎤 Sent a voice note"
            : (record.type === "image" ? "📷 Sent an image/list photo" : (record.body || "New order message"));
        } else {
          // Sent by shopkeeper -> Notify customer
          targetUserId = order.customer_id;
          if (record.type === "bill") {
            title = `🧾 Bill Received from ${shopName}`;
            body = `Total: ₹${record.bill?.total || record.body || "Bill ready"}. Tap to confirm & pay!`;
          } else {
            title = `💬 ${shopName}`;
            body = record.type === "voice"
              ? "🎤 Sent a voice note"
              : (record.type === "image" ? "📷 Sent an image" : (record.body || "New reply"));
          }
        }
      }
    }

    if (!targetUserId || !body) {
      return new Response(JSON.stringify({ message: "No notification required for this event." }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch device tokens for the recipient
    const { data: tokens, error: tokensError } = await adminClient
      .from("device_tokens")
      .select("token")
      .eq("user_id", targetUserId);

    if (tokensError || !tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: "User has no registered FCM tokens." }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!serviceAccountJson) {
      console.log(`[FCM Mock Log] Would send push to user ${targetUserId}: ${title} - ${body}`);
      return new Response(JSON.stringify({ message: "Mock logged (FIREBASE_SERVICE_ACCOUNT not configured yet)." }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    const accessToken = await getGoogleAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id;

    // Send notifications to each device token via FCM HTTP v1
    const notificationPromises = tokens.map(async ({ token }) => {
      const fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token: token,
              notification: {
                title,
                body,
              },
              data: dataPayload,
              android: {
                priority: "HIGH",
                notification: {
                  sound: "default",
                  click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
              },
            },
          }),
        }
      );

      const resBody = await fcmResponse.json();
      return { token, status: fcmResponse.status, result: resBody };
    });

    const results = await Promise.all(notificationPromises);

    return new Response(JSON.stringify({ success: true, dispatched: results }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
