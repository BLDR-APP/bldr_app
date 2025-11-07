-- Location: supabase/migrations/20250817033341_add_email_confirmation.sql
-- Schema Analysis: Extends existing BLDR fitness schema with email confirmation tracking
-- Integration Type: Extension - Adding email verification functionality
-- Dependencies: Existing user_profiles table, auth system

-- 1. Add email confirmation tracking to user_profiles
ALTER TABLE public.user_profiles
ADD COLUMN email_confirmed BOOLEAN DEFAULT false,
ADD COLUMN email_confirmed_at TIMESTAMPTZ,
ADD COLUMN confirmation_token TEXT,
ADD COLUMN confirmation_sent_at TIMESTAMPTZ;

-- 2. Add indexes for email confirmation queries
CREATE INDEX idx_user_profiles_email_confirmed ON public.user_profiles(email_confirmed);
CREATE INDEX idx_user_profiles_confirmation_token ON public.user_profiles(confirmation_token);

-- 3. Function to handle email confirmation
CREATE OR REPLACE FUNCTION public.confirm_user_email(token TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_record RECORD;
BEGIN
    -- Find user by confirmation token
    SELECT * INTO user_record
    FROM public.user_profiles
    WHERE confirmation_token = token
    AND email_confirmed = false
    AND confirmation_sent_at > (NOW() - INTERVAL '24 hours'); -- Token expires in 24 hours
    
    -- If user not found or token expired, return false
    IF user_record IS NULL THEN
        RETURN false;
    END IF;
    
    -- Update user confirmation status
    UPDATE public.user_profiles
    SET 
        email_confirmed = true,
        email_confirmed_at = NOW(),
        confirmation_token = NULL
    WHERE id = user_record.id;
    
    RETURN true;
END;
$$;

-- 4. Function to generate confirmation token
CREATE OR REPLACE FUNCTION public.generate_confirmation_token(user_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    token TEXT;
    user_id UUID;
BEGIN
    -- Generate a random token
    token := encode(gen_random_bytes(32), 'hex');
    
    -- Get user ID
    SELECT id INTO user_id FROM public.user_profiles WHERE email = user_email;
    
    -- If user not found, return null
    IF user_id IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Update user with new confirmation token
    UPDATE public.user_profiles
    SET 
        confirmation_token = token,
        confirmation_sent_at = NOW()
    WHERE id = user_id;
    
    RETURN token;
END;
$$;

-- 5. Function to resend confirmation email
CREATE OR REPLACE FUNCTION public.resend_confirmation_email(user_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_record RECORD;
    new_token TEXT;
BEGIN
    -- Find user by email
    SELECT * INTO user_record
    FROM public.user_profiles
    WHERE email = user_email
    AND email_confirmed = false;
    
    -- If user not found or already confirmed, return false
    IF user_record IS NULL THEN
        RETURN false;
    END IF;
    
    -- Check if enough time has passed since last confirmation email (5 minutes)
    IF user_record.confirmation_sent_at > (NOW() - INTERVAL '5 minutes') THEN
        RETURN false;
    END IF;
    
    -- Generate new token
    new_token := encode(gen_random_bytes(32), 'hex');
    
    -- Update user with new confirmation token
    UPDATE public.user_profiles
    SET 
        confirmation_token = new_token,
        confirmation_sent_at = NOW()
    WHERE id = user_record.id;
    
    RETURN true;
END;
$$;

-- 6. Update the handle_new_user trigger to generate confirmation token
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (
    id, 
    email, 
    full_name, 
    role,
    email_confirmed,
    confirmation_token,
    confirmation_sent_at
  )
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'member')::public.user_role,
    false,
    encode(gen_random_bytes(32), 'hex'),
    NOW()
  );
  RETURN NEW;
END;
$$;