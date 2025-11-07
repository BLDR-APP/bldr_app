// supabase/functions/fatsecret/index.ts
// Deno Deploy / Supabase Edge Function
// Ações (POST JSON):
//  - { "action": "foods_search", "query": "...", "page": 0, "maxResults": 20, "region": "BR", "language": "pt_BR" }
//  - { "action": "food_get", "food_id": "12345", "region": "BR", "language": "pt_BR" }
//  - { "action": "barcode", "barcode": "7891234567890" }
//  - { "action": "ping_ip" }  -> retorna IP de saída da Edge Function (use na allowlist da FatSecret)
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
const TOKEN_URL = "https://oauth.fatsecret.com/connect/token";
const REST_URL = "https://platform.fatsecret.com/rest/server.api";
const BARCODE_URL = "https://platform.fatsecret.com/rest/food/barcode/find-by-id/v1";
const CLIENT_ID = Deno.env.get("FATSECRET_CLIENT_ID") ?? "";
const CLIENT_SECRET = Deno.env.get("FATSECRET_CLIENT_SECRET") ?? "";
const SCOPES = Deno.env.get("FATSECRET_SCOPES") ?? "basic";
async function getToken() {
  if (!CLIENT_ID || !CLIENT_SECRET) {
    throw new Error("FATSECRET_CLIENT_ID/SECRET ausentes nas secrets do Supabase.");
  }
  const strategies = [
    {
      name: "S1(Basic+Body+Scope)",
      useBasic: true,
      bodyCreds: true,
      withScope: true
    },
    {
      name: "S2(Basic+Scope)",
      useBasic: true,
      bodyCreds: false,
      withScope: true
    },
    {
      name: "S3(BodyOnly)",
      useBasic: false,
      bodyCreds: true,
      withScope: false
    }
  ];
  let lastErrText = "";
  for (const s of strategies){
    const headers = {
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"
    };
    if (s.useBasic) {
      const basic = btoa(`${CLIENT_ID}:${CLIENT_SECRET}`);
      headers["Authorization"] = `Basic ${basic}`;
    }
    const body = new URLSearchParams();
    body.set("grant_type", "client_credentials");
    if (s.withScope && SCOPES) body.set("scope", SCOPES);
    if (s.bodyCreds) {
      body.set("client_id", CLIENT_ID);
      body.set("client_secret", CLIENT_SECRET);
    }
    const r = await fetch(TOKEN_URL, {
      method: "POST",
      headers,
      body
    });
    const txt = await r.text().catch(()=>"");
    if (r.ok) {
      const data = JSON.parse(txt || "{}");
      const token = String(data?.access_token ?? "");
      if (token) return {
        token,
        strategy: s.name
      };
      lastErrText = `(${s.name}) resposta sem access_token: ${txt}`;
    } else {
      lastErrText = `(${s.name}) ${r.status} ${txt}`;
    }
  }
  throw new Error(`Falha ao obter token: ${lastErrText}`);
}
async function foodsSearch(token, p) {
  const body = new URLSearchParams();
  body.set("method", "foods.search");
  body.set("format", "json");
  body.set("search_expression", String(p.query ?? ""));
  body.set("page_number", String(p.page ?? 0));
  body.set("max_results", String(p.maxResults ?? 20));
  if (SCOPES.toLowerCase().includes("localization")) {
    if (p.region) body.set("region", String(p.region));
    if (p.language) body.set("language", String(p.language));
  }
  const resp = await fetch(REST_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body
  });
  if (!resp.ok) throw new Error(`foods.search: ${resp.status} ${await resp.text()}`);
  return await resp.json();
}
async function foodGet(token, p) {
  const body = new URLSearchParams();
  body.set("method", "food.get");
  body.set("format", "json");
  body.set("food_id", String(p.food_id ?? ""));
  if (SCOPES.toLowerCase().includes("localization")) {
    if (p.region) body.set("region", String(p.region));
    if (p.language) body.set("language", String(p.language));
  }
  const resp = await fetch(REST_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body
  });
  if (!resp.ok) throw new Error(`food.get: ${resp.status} ${await resp.text()}`);
  return await resp.json();
}
async function barcode(token, p) {
  const url = new URL(BARCODE_URL);
  url.searchParams.set("barcode", String(p.barcode ?? ""));
  url.searchParams.set("format", "json");
  const resp = await fetch(url, {
    headers: {
      "Authorization": `Bearer ${token}`
    }
  });
  if (!resp.ok) throw new Error(`barcode: ${resp.status} ${await resp.text()}`);
  return await resp.json();
}
async function pingIp() {
  // retorna o IP público de saída da Edge Function
  const r = await fetch("https://api.ipify.org?format=json");
  const j = await r.json().catch(()=>({}));
  return j; // { ip: "x.x.x.x" }
}
Deno.serve(async (req)=>{
  try {
    if (req.method !== "POST") {
      return new Response("Use POST", {
        status: 405
      });
    }
    const payload = await req.json().catch(()=>({}));
    const action = String(payload.action ?? "");
    if (action === "ping_ip") {
      const ip = await pingIp();
      return new Response(JSON.stringify({
        ok: true,
        data: ip
      }), {
        headers: {
          "Content-Type": "application/json"
        }
      });
    }
    const { token, strategy } = await getToken();
    let data;
    if (action === "foods_search") {
      data = await foodsSearch(token, payload);
    } else if (action === "food_get") {
      data = await foodGet(token, payload);
    } else if (action === "barcode") {
      data = await barcode(token, payload);
    } else {
      return new Response(JSON.stringify({
        ok: false,
        error: "Ação inválida"
      }), {
        status: 400
      });
    }
    return new Response(JSON.stringify({
      ok: true,
      strategy,
      data
    }), {
      headers: {
        "Content-Type": "application/json"
      },
      status: 200
    });
  } catch (e) {
    return new Response(JSON.stringify({
      ok: false,
      error: String(e?.message ?? e)
    }), {
      headers: {
        "Content-Type": "application/json"
      },
      status: 400
    });
  }
});
