import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno';

// Pegamos a chave dos segredos do Supabase
const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')!;

const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2022-11-15',
  httpClient: Stripe.createFetchHttpClient(),
});

serve(async (req) => {
  try {
    const { plan_id, billing_period, coupon_code } = await req.json();

    // --- PRINTS DE DEBUG ---
    console.log(`--- FUNÇÃO SUPABASE INICIADA ---`);
    console.log(`BACKEND: Recebido coupon_code: ${coupon_code}`);
    console.log(`BACKEND: Usando chave Stripe que começa com: ${stripeSecretKey.substring(0, 10)}...`); // Ex: sk_live_... ou sk_test_...
    // --- FIM DOS PRINTS ---

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const { data: plan, error: planError } = await supabaseClient
      .from('subscription_plans')
      .select('stripe_monthly_price_id, stripe_annual_price_id')
      .eq('id', plan_id)
      .single();

    if (planError || !plan) throw new Error(`Plan with ID ${plan_id} not found.`);

    const priceId = billing_period === 'annual' ? plan.stripe_annual_price_id : plan.stripe_monthly_price_id;
    if (!priceId) throw new Error(`Price ID for the selected plan and billing period is missing.`);

    const { data: profile } = await supabaseClient
      .from('user_profiles')
      .select('stripe_customer_id')
      .eq('id', user.id)
      .single();

    let stripeCustomerId = profile?.stripe_customer_id;

    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: { supabase_id: user.id },
      });
      stripeCustomerId = customer.id;
      await supabaseClient
        .from('user_profiles')
        .update({ stripe_customer_id: stripeCustomerId })
        .eq('id', user.id);
    }

    const subscriptionParams: Stripe.SubscriptionCreateParams = {
      customer: stripeCustomerId,
      items: [{ price: priceId }],
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent'],
    };

    if (coupon_code && coupon_code.trim() !== '') {
      subscriptionParams.coupon = coupon_code.trim().toUpperCase();
    }

    const subscription = await stripe.subscriptions.create(subscriptionParams);

    if (subscription.latest_invoice?.payment_intent) {
      const responsePayload = {
        client_secret: subscription.latest_invoice.payment_intent.client_secret,
        subscription_id: subscription.id,
      };
       return new Response(JSON.stringify(responsePayload), {
        headers: { 'Content-Type': 'application/json' },
      });
    } else {
      // Caso de cupom 100% que não gera payment_intent
       const responsePayload = {
        client_secret: null, // Não há client_secret para confirmar
        subscription_id: subscription.id,
      };
       return new Response(JSON.stringify(responsePayload), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

  } catch (error) {
    // --- PRINT DE DEBUG PARA ERROS ---
    console.error(`ERRO NA FUNÇÃO SUPABASE: ${error.message}`);
    // --- FIM DO PRINT ---
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});