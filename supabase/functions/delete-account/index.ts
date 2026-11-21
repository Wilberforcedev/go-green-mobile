import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (status: number, payload: Record<string, unknown>) =>
  new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return json(405, { error: "Use POST to delete an account." });
  }

  const authorization = request.headers.get("Authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "");
  if (!token || token === authorization) {
    return json(401, { error: "Sign in again to delete your account." });
  }

  let body: { confirmation?: string } | null = null;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: "Confirm account deletion and try again." });
  }
  if (body?.confirmation !== "DELETE") {
    return json(400, { error: "Account deletion was not confirmed." });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publicKey =
    Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !publicKey || !serviceRoleKey) {
    return json(500, { error: "Account deletion is not configured." });
  }

  const callerClient = createClient(supabaseUrl, publicKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: userData, error: userError } =
    await callerClient.auth.getUser(token);
  if (userError || !userData.user) {
    return json(401, { error: "Sign in again to delete your account." });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: profile, error: profileError } = await adminClient
    .from("profiles")
    .select("role")
    .eq("id", userData.user.id)
    .maybeSingle();
  if (profileError) {
    return json(500, { error: "Could not confirm account access." });
  }
  if (profile?.role === "admin") {
    return json(409, {
      error: "Transfer administrator access before deleting this account.",
    });
  }

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(
    userData.user.id,
  );
  if (deleteError) {
    return json(500, { error: "The account could not be deleted. Try again." });
  }

  return json(200, { deleted: true });
});
