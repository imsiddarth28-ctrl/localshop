// ==============================================================================
// THE LOCAL SHOP: EDGE FUNCTION - ADMIN PASSWORD RESET
// Resets user password using service_role key after verifying caller is Admin.
// Forces `profiles.must_change_password = true` so user must change password on login.
// ==============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const authHeader = req.headers.get("Authorization");

    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Initialize user client to verify admin credentials
    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized caller" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check if caller is app admin in profiles table
    const { data: callerProfile, error: profileCheckError } = await userClient
      .from("profiles")
      .select("role, suspended")
      .eq("id", user.id)
      .single();

    if (profileCheckError || callerProfile?.role !== "admin" || callerProfile?.suspended) {
      return new Response(
        JSON.stringify({ error: "Forbidden: Only active admins can perform password resets." }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Parse request payload
    const { requestId, targetUserId, newPassword } = await req.json();

    if (!targetUserId || !newPassword || newPassword.length < 6) {
      return new Response(
        JSON.stringify({ error: "Invalid parameters: targetUserId and newPassword (min 6 chars) are required." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Initialize admin client with SERVICE_ROLE key
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // Update password in Supabase Auth
    const { error: updateAuthError } = await adminClient.auth.admin.updateUserById(
      targetUserId,
      { password: newPassword }
    );

    if (updateAuthError) {
      return new Response(
        JSON.stringify({ error: `Failed to update auth password: ${updateAuthError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Force user to change password on next login
    const { error: profileUpdateError } = await adminClient
      .from("profiles")
      .update({ must_change_password: true, updated_at: new Date().toISOString() })
      .eq("id", targetUserId);

    if (profileUpdateError) {
      console.error("Warning: Failed to set must_change_password flag:", profileUpdateError);
    }

    // 5. If linked to a password_reset_request, mark it completed
    if (requestId) {
      await adminClient
        .from("password_reset_requests")
        .update({
          status: "completed",
          resolved_at: new Date().toISOString(),
          admin_notes: `Reset completed by admin ${user.id}`,
        })
        .eq("id", requestId);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Password reset successfully. User will be prompted to change password on next login.",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
