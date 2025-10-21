-- Location: supabase/migrations/20250817022814_add_onboarding_tracking.sql
-- Schema Analysis: Existing user_profiles table needs onboarding tracking field
-- Integration Type: Extension - Adding onboarding completion tracking
-- Dependencies: Existing user_profiles table

-- Add onboarding_completed column to existing user_profiles table
ALTER TABLE public.user_profiles 
ADD COLUMN onboarding_completed BOOLEAN DEFAULT false;

-- Add index for efficient onboarding status queries
CREATE INDEX idx_user_profiles_onboarding_completed 
ON public.user_profiles(onboarding_completed);

-- Update existing users to have onboarding_completed as true if they have fitness_goal set
-- (assume users with fitness goals have completed onboarding previously)
UPDATE public.user_profiles 
SET onboarding_completed = true 
WHERE fitness_goal IS NOT NULL;