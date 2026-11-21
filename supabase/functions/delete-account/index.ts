import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "Use POST to delete an account." });
  }

  const authorization = request.headers.get("Authorization") ?? "";
  const token = authorization.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) return jsonResponse(401, { error: "Sign in before deleting your account." });

  let body: { confirmation?: string } | null = null;
  try {
    body = await request.json();
  } catch {
    return jsonResponse(400, { error: "Confirm account deletion and try again." });
  }
  if (body?.confirmation !== "DELETE") {
    return jsonResponse(400, { error: "Account deletion was not confirmed." });
  }

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) {
    return jsonResponse(500, { error: "Account deletion is not configured." });
  }

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: authData, error: authError } = await admin.auth.getUser(token);
  const user = authData.user;
  if (authError || !user) {
    return jsonResponse(401, { error: "Your session is invalid. Sign in again." });
  }

  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .maybeSingle();
  if (profileError) {
    return jsonResponse(500, { error: "Could not verify account access." });
  }

  if (profile?.role === "admin") {
    return jsonResponse(409, {
      error: "Remove administrator access before deleting this account.",
    });
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    return jsonResponse(500, { error: "The account could not be deleted." });
  }
  return jsonResponse(200, { deleted: true });
});
