import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno';

const createAdminClient = () => {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
};

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2022-11-15',
  httpClient: Stripe.createFetchHttpClient(),
});

serve(async (req) => {
  const signature = req.headers.get('Stripe-Signature');
  const body = await req.text();
  const webhookSigningSecret = Deno.env.get('STRIPE_WEBHOOK_SIGNING_SECRET')!;

  let receivedEvent;
  try {
    receivedEvent = await stripe.webhooks.constructEventAsync(
      body,
      signature!,
      webhookSigningSecret
    );
    console.log(`✅ Evento verificado: ${receivedEvent.type}`);
  } catch (err) {
    console.error(`❌ Erro na verificação da assinatura do webhook: ${err.message}`);
    return new Response(err.message, { status: 400 });
  }

  try {
    const adminClient = createAdminClient();
    const subscription = receivedEvent.data.object as Stripe.Subscription;

    switch (receivedEvent.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        console.log(`🔔 Recebido evento: ${receivedEvent.type} para a assinatura ${subscription.id}`);

        const customerId = subscription.customer as string;
        const subscriptionItem = subscription.items.data[0];
        if (!subscriptionItem) throw new Error('Assinatura não contém itens.');

        const stripeProductId = subscriptionItem.price.product as string;
        const { data: planData, error: planError } = await adminClient
          .from('subscription_plans')
          .select('id')
          .eq('stripe_product_id', stripeProductId)
          .single();

        if (planError || !planData) throw new Error(`Plano com stripe_product_id ${stripeProductId} não encontrado no Supabase.`);
        const planId = planData.id;

        const { data: profile, error: profileError } = await adminClient
          .from('user_profiles')
          .select('id')
          .eq('stripe_customer_id', customerId)
          .single();

        if (profileError || !profile) throw new Error(`Perfil não encontrado para o stripe_customer_id: ${customerId}`);
        const userId = profile.id;

        // --- PONTO DA CORREÇÃO ---
        // Traduz o valor do Stripe ('month'/'year') para o valor do seu Enum ('monthly'/'annual')
        const interval = subscriptionItem.price.recurring?.interval;
        const billingPeriodForDb = interval === 'month' ? 'monthly' : interval === 'year' ? 'annual' : null;
        // --- FIM DA CORREÇÃO ---

        const subscriptionRecord = {
          user_id: userId,
          plan_id: planId,
          status: subscription.status,
          stripe_subscription_id: subscription.id,
          stripe_customer_id: customerId,
          billing_period: billingPeriodForDb, // Usa o valor traduzido
          current_period_start: new Date(subscriptionItem.current_period_start * 1000).toISOString(),
          current_period_end: new Date(subscriptionItem.current_period_end * 1000).toISOString(),
          trial_end: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
          canceled_at: subscription.canceled_at ? new Date(subscription.canceled_at * 1000).toISOString() : null,
        };

        const { error: upsertError } = await adminClient
          .from('user_subscriptions')
          .upsert(subscriptionRecord, { onConflict: 'stripe_subscription_id' });

        if (upsertError) throw upsertError;

        console.log(`✅ Assinatura ${subscription.id} salva/atualizada para o usuário ${userId}`);
        break;
      }

      case 'customer.subscription.deleted': {
        // ... (lógica de cancelamento permanece a mesma)
        break;
      }

      default: {
        console.log(`- Evento não tratado: ${receivedEvent.type}`);
      }
    }
  } catch (error) {
    console.error('- Erro ao processar o webhook:', error.message);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 });
});