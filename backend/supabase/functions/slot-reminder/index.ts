// ==============================================================================
// THE LOCAL SHOP: EDGE FUNCTION - SLOT REMINDER
// Triggered via pg_cron or schedule at 6:30 AM and 5:30 PM (IST)
// Reminds shopkeepers to prepare and start their batch deliveries.
// ==============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // Parse slot parameter if passed: 'morning' or 'evening', or deduce by current hour in IST
    const url = new URL(req.url);
    let slotType = url.searchParams.get("slot") as "morning" | "evening" | null;

    if (!slotType) {
      // Determine slot type based on Indian Standard Time (UTC + 5:30)
      const now = new Date();
      const istHours = (now.getUTCHours() + 5 + Math.floor((now.getUTCMinutes() + 30) / 60)) % 24;
      slotType = istHours < 12 ? "morning" : "evening";
    }

    const todayDate = new Date().toISOString().split("T")[0];

    // Find all active morning/evening orders for today
    const { data: orders, error } = await adminClient
      .from("orders")
      .select("id, shop_id, slot_type, status, shops(owner_id, name)")
      .eq("slot_type", slotType)
      .eq("delivery_date", todayDate)
      .in("status", ["placed", "accepted", "preparing"]);

    if (error) {
      throw error;
    }

    // Group count by shop
    const shopCounts: Record<string, { count: number; ownerId: string; shopName: string }> = {};

    for (const order of orders || []) {
      const shop = order.shops as any;
      if (!shop) continue;
      if (!shopCounts[order.shop_id]) {
        shopCounts[order.shop_id] = { count: 0, ownerId: shop.owner_id, shopName: shop.name };
      }
      shopCounts[order.shop_id].count++;
    }

    const summary = [];
    for (const shopId of Object.keys(shopCounts)) {
      const item = shopCounts[shopId];
      summary.push({
        shopId,
        shopName: item.shopName,
        ownerId: item.ownerId,
        pendingOrders: item.count,
        slot: slotType,
        reminderMessage: `Reminder: You have ${item.count} orders queued for the ${slotType === "morning" ? "7:00 AM" : "6:00 PM"} batch delivery run. Please review and pack.`,
      });
    }

    return new Response(JSON.stringify({ success: true, slot: slotType, reminders: summary }), {
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
