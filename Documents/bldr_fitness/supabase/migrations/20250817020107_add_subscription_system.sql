-- Location: supabase/migrations/20250817020107_add_subscription_system.sql
-- Schema Analysis: Adding subscription and payment functionality to existing BLDR fitness schema
-- Integration Type: Addition - extends existing user_profiles table
-- Dependencies: user_profiles (existing table)

-- 1. Create subscription-related enums
CREATE TYPE public.subscription_plan_type AS ENUM ('core', 'club');
CREATE TYPE public.subscription_status AS ENUM ('active', 'canceled', 'past_due', 'unpaid', 'trialing');
CREATE TYPE public.billing_period AS ENUM ('monthly', 'annual');
CREATE TYPE public.payment_status AS ENUM ('pending', 'succeeded', 'failed', 'canceled', 'requires_action');

-- 2. Create subscription plans table
CREATE TABLE public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    plan_type public.subscription_plan_type NOT NULL,
    monthly_price DECIMAL(10,2) NOT NULL,
    annual_price DECIMAL(10,2) NOT NULL,
    monthly_price_text TEXT NOT NULL,
    annual_price_text TEXT NOT NULL,
    description TEXT NOT NULL,
    features TEXT[] NOT NULL,
    is_popular BOOLEAN DEFAULT false,
    stripe_monthly_price_id TEXT,
    stripe_annual_price_id TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create user subscriptions table
CREATE TABLE public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES public.subscription_plans(id) ON DELETE RESTRICT,
    stripe_subscription_id TEXT UNIQUE,
    stripe_customer_id TEXT,
    status public.subscription_status DEFAULT 'active',
    billing_period public.billing_period NOT NULL,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    trial_end TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create payment intents table for tracking payments
CREATE TABLE public.payment_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES public.user_subscriptions(id) ON DELETE SET NULL,
    stripe_payment_intent_id TEXT UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'brl',
    status public.payment_status DEFAULT 'pending',
    plan_type public.subscription_plan_type NOT NULL,
    billing_period public.billing_period NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Essential indexes for performance
CREATE INDEX idx_subscription_plans_plan_type ON public.subscription_plans(plan_type);
CREATE INDEX idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX idx_user_subscriptions_stripe_subscription_id ON public.user_subscriptions(stripe_subscription_id);
CREATE INDEX idx_payment_intents_user_id ON public.payment_intents(user_id);
CREATE INDEX idx_payment_intents_stripe_payment_intent_id ON public.payment_intents(stripe_payment_intent_id);
CREATE INDEX idx_payment_intents_status ON public.payment_intents(status);

-- 6. Add triggers for updated_at columns
CREATE TRIGGER update_subscription_plans_updated_at
    BEFORE UPDATE ON public.subscription_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at
    BEFORE UPDATE ON public.user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_intents_updated_at
    BEFORE UPDATE ON public.payment_intents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. Enable RLS on all tables
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_intents ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies using Pattern 4 (Public Read, Private Write) for subscription plans
CREATE POLICY "public_can_read_subscription_plans"
ON public.subscription_plans
FOR SELECT
TO public
USING (is_active = true);

-- Pattern 2 (Simple User Ownership) for user subscriptions
CREATE POLICY "users_manage_own_user_subscriptions"
ON public.user_subscriptions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2 (Simple User Ownership) for payment intents
CREATE POLICY "users_manage_own_payment_intents"
ON public.payment_intents
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 9. Insert default subscription plans
DO $$
DECLARE
    core_plan_id UUID := gen_random_uuid();
    club_plan_id UUID := gen_random_uuid();
BEGIN
    INSERT INTO public.subscription_plans (
        id, name, plan_type, monthly_price, annual_price, 
        monthly_price_text, annual_price_text, description, 
        features, is_popular
    ) VALUES
        (
            core_plan_id,
            'BLDR CORE',
            'core'::public.subscription_plan_type,
            29.90,
            299.00,
            'R$29,90/mês',
            'R$299,00/ano',
            'Base sólida para sua evolução. Essencial e funcional.',
            ARRAY[
                'Treinos padrão e personalizados',
                'Plano nutricional adaptado',
                'Registro e gráficos de progresso',
                'Acesso à comunidade geral',
                'Estatísticas e metas',
                'Suporte básico'
            ],
            false
        ),
        (
            club_plan_id,
            'BLDR CLUB',
            'club'::public.subscription_plan_type,
            59.90,
            499.00,
            'R$59,90/mês',
            'R$499,00/ano',
            'Experiência completa para quem vive o lifestyle.',
            ARRAY[
                'Tudo do CORE +',
                'Treinos "Elite" e desafios mensais',
                'Planos nutricionais exclusivos',
                'Consultas mensais com IA ou especialista (PDF)',
                'Grupos privados e eventos premium',
                '10% off vitalício na loja',
                'Sorteios e acesso antecipado a recursos',
                'Badge "BLDR CLUB" no perfil'
            ],
            true
        );
END $$;