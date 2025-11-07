// supabase/functions/checkout/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.21.0";
import Stripe from "https://esm.sh/stripe@12.0.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "*",
};

const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
if (!stripeKey) throw new Error("Missing STRIPE_SECRET_KEY");

const stripe = new Stripe(stripeKey, { apiVersion: "2024-06-20" as any });

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

// liga/desliga logs pelo env DEBUG (default: true)
const DEBUG = (Deno.env.get("DEBUG") ?? "true").toLowerCase() === "true";

// =================== VALIDATE COUPON ===================
async function handleValidateCoupon(req: Request): Promise<Response> {
  const t0 = Date.now();
  let raw = "";
  try {
    raw = await req.clone().text();
    if (DEBUG) {
      console.log("[validate-coupon] method:", req.method);
      console.log("[validate-coupon] url:", new URL(req.url).toString());
      console.log("[validate-coupon] body(raw):", raw);
    }

    const { code, currency = "brl" } = raw ? JSON.parse(raw) : await req.json();

    if (!code || String(code).trim().length === 0) {
      if (DEBUG) console.log("[validate-coupon] missing code");
      return new Response(
        JSON.stringify({ error: "Código de cupom é obrigatório", details: "missing code" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 },
      );
    }

    if (DEBUG) console.log("[validate-coupon] code:", code, "currency:", currency);

    const promos = await stripe.promotionCodes.list({
      code: String(code).trim(),
      active: true,
      limit: 1,
      expand: ["data.coupon"],
    });

    if (DEBUG) {
      console.log("[validate-coupon] stripe promos.count:", promos?.data?.length ?? 0);
      if (promos?.data?.length) {
        const p = promos.data[0];
        console.log("[validate-coupon] promo.id:", p.id, "promo.code:", p.code, "coupon.id:", p.coupon?.id);
        console.log("[validate-coupon] coupon.percent_off:", p.coupon?.percent_off, "amount_off:", p.coupon?.amount_off, "currency:", p.coupon?.currency);
        console.log("[validate-coupon] coupon.valid:", p.coupon?.valid, "promo.active:", p.active);
      }
    }

    if (!promos.data.length) {
      return new Response(
        JSON.stringify({
          error: "Cupom inválido ou inativo",
          details: "promotionCodes.list returned empty",
          hint: "Verifique se o código existe no mesmo ambiente (test/live) e se está ativo.",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 404 },
      );
    }

    const promo = promos.data[0];
    const coupon = promo.coupon;
    let discount_cents = 0;

    if (coupon?.amount_off) {
      if (!coupon.currency || coupon.currency.toLowerCase() === String(currency).toLowerCase()) {
        discount_cents = coupon.amount_off;
      } else {
        return new Response(
          JSON.stringify({
            error: "Cupom com moeda diferente",
            details: `coupon.currency=${coupon.currency}, payment.currency=${String(currency).toLowerCase()}`,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 },
        );
      }
    } else if (coupon?.percent_off) {
      // percentual: cálculo final (em centavos) é feito no create-payment-intent
      discount_cents = 0;
    }

    if (DEBUG) console.log("[validate-coupon] ok in", Date.now() - t0, "ms");

    return new Response(
      JSON.stringify({
        valid: promo.active && !!coupon?.valid,
        coupon_code: String(code).trim(),
        discount_cents,                // se amount_off
        percent_off: coupon?.percent_off ?? null,
        promotion_code_id: promo.id,
        type: coupon?.amount_off ? "fixed" : "percentage",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 },
    );
  } catch (err: any) {
    console.error("[validate-coupon] ERROR:", err?.message ?? err, " raw:", raw);
    return new Response(
      JSON.stringify({
        error: "Erro ao validar cupom",
        details: err?.message ?? String(err),
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 },
    );
  }
}

// =================== CREATE PAYMENT INTENT ===================
async function handleCreatePaymentIntent(req: Request): Promise<Response> {
  let raw = "";
  try {
    raw = await req.clone().text();
    if (DEBUG) console.log("[create-payment-intent] body(raw):", raw);
    const body = raw ? JSON.parse(raw) : await req.json();
    const {
      plan_id,
      billing_period,
      currency = "brl",
      user_id,
      coupon_code,
    } = body;

    if (!plan_id || !billing_period || !user_id) {
      return new Response(
        JSON.stringify({ error: "Parâmetros obrigatórios ausentes" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 },
      );
    }

    const { data: plan, error: planError } = await supabaseAdmin
      .from("subscription_plans")
      .select("*")
      .eq("id", plan_id)
      .eq("is_active", true)
      .single();

    if (planError || !plan) {
      return new Response(
        JSON.stringify({ error: "Plano não encontrado ou inativo" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 404 },
      );
    }

    const amountOriginalCents =
      billing_period === "annual"
        ? Math.round(plan.annual_price * 100)
        : Math.round(plan.monthly_price * 100);

    let discountCents = 0;
    let promotionCodeId: string | null = null;

    if (coupon_code) {
      const promos = await stripe.promotionCodes.list({
        code: String(coupon_code).trim(),
        active: true,
        limit: 1,
        expand: ["data.coupon"],
      });

      if (!promos.data.length) {
        if (DEBUG) console.log("[create-payment-intent] coupon not found:", coupon_code);
      } else {
        const promo = promos.data[0];
        promotionCodeId = promo.id;
        const coupon = promo.coupon;

        if (coupon.amount_off) {
          if (!coupon.currency || coupon.currency.toLowerCase() === String(currency).toLowerCase()) {
            discountCents = coupon.amount_off;
          } else {
            return new Response(
              JSON.stringify({
                error: "Cupom com moeda diferente",
                details: `coupon.currency=${coupon.currency}, payment.currency=${String(currency).toLowerCase()}`,
              }),
              { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 },
            );
          }
        } else if (coupon.percent_off) {
          discountCents = Math.floor(amountOriginalCents * (coupon.percent_off / 100));
        }
      }
    }

    const amountFinalCents = Math.max(0, amountOriginalCents - discountCents);

    if (DEBUG) {
      console.log("[create-payment-intent] amount_original_cents:", amountOriginalCents);
      console.log("[create-payment-intent] discount_cents:", discountCents);
      console.log("[create-payment-intent] amount_final_cents:", amountFinalCents);
      console.log("[create-payment-intent] promotion_code_id:", promotionCodeId);
    }

    if (amountFinalCents === 0) {
      return new Response(
        JSON.stringify({
          client_secret: null,
          payment_intent_id: null,
          amount_original_cents: amountOriginalCents,
          amount_final_cents: 0,
          discount_cents: discountCents,
          promotion_code_id: promotionCodeId,
          payment_skipped: true,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 },
      );
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountFinalCents,
      currency,
      automatic_payment_methods: { enabled: true },
      description: `BLDR Fitness - ${plan.name} (${billing_period})`,
      metadata: {
        user_id,
        plan_id,
        plan_name: plan.name,
        billing_period,
        promotion_code_id: promotionCodeId ?? "",
        discount_cents: String(discountCents),
      },
    });

    return new Response(
      JSON.stringify({
        client_secret: paymentIntent.client_secret,
        payment_intent_id: paymentIntent.id,
        amount_original_cents: amountOriginalCents,
        amount_final_cents: amountFinalCents,
        discount_cents: discountCents,
        promotion_code_id: promotionCodeId,
        payment_skipped: false,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 },
    );
  } catch (err: any) {
    console.error("[create-payment-intent] ERROR:", err?.message ?? err, " raw:", raw);
    return new Response(
      JSON.stringify({ error: "Erro ao criar PaymentIntent", details: err?.message ?? String(err) }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 },
    );
  }
}

// =================== ROUTER ===================
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const url = new URL(req.url);
  const pathname = url.pathname;

  if (pathname.endsWith("/validate-coupon") && req.method === "POST") {
    return handleValidateCoupon(req);
  }
  if (pathname.endsWith("/create-payment-intent") && req.method === "POST") {
    return handleCreatePaymentIntent(req);
  }

  return new Response("Not found", { status: 404, headers: corsHeaders });
});
