-- Location: supabase/migrations/20250816004909_bldr_fitness_complete.sql
-- Schema Analysis: Fresh project - no existing tables
-- Integration Type: Complete new fitness app schema
-- Dependencies: None (creating from scratch)

-- 1. Custom Types and Enums
CREATE TYPE public.user_role AS ENUM ('admin', 'trainer', 'member');
CREATE TYPE public.fitness_goal AS ENUM ('weight_loss', 'muscle_gain', 'strength', 'endurance', 'general_fitness');
CREATE TYPE public.activity_level AS ENUM ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active');
CREATE TYPE public.gender_type AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE public.workout_type AS ENUM ('strength', 'cardio', 'flexibility', 'sports', 'custom');
CREATE TYPE public.exercise_type AS ENUM ('compound', 'isolation', 'cardio', 'stretching', 'plyometric');
CREATE TYPE public.muscle_group AS ENUM ('chest', 'back', 'shoulders', 'biceps', 'triceps', 'legs', 'abs', 'cardio', 'full_body');
CREATE TYPE public.meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');
CREATE TYPE public.measurement_type AS ENUM ('weight', 'body_fat', 'muscle_mass', 'waist', 'chest', 'arms', 'thighs');

-- 2. Core User Management Tables
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    username TEXT UNIQUE,
    role public.user_role DEFAULT 'member'::public.user_role,
    avatar_url TEXT,
    date_of_birth DATE,
    gender public.gender_type,
    height_cm INTEGER,
    fitness_goal public.fitness_goal,
    activity_level public.activity_level,
    target_weight_kg DECIMAL(5,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Workout Management Tables
CREATE TABLE public.workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    workout_type public.workout_type NOT NULL,
    estimated_duration_minutes INTEGER,
    difficulty_level INTEGER CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
    is_public BOOLEAN DEFAULT false,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    exercise_type public.exercise_type NOT NULL,
    primary_muscle_group public.muscle_group NOT NULL,
    secondary_muscle_groups public.muscle_group[],
    instructions TEXT[],
    tips TEXT[],
    image_url TEXT,
    video_url TEXT,
    equipment_needed TEXT[],
    is_system_exercise BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.workout_template_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_template_id UUID REFERENCES public.workout_templates(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL,
    sets INTEGER,
    reps INTEGER,
    duration_seconds INTEGER,
    rest_seconds INTEGER,
    weight_kg DECIMAL(6,2),
    distance_meters DECIMAL(8,2),
    notes TEXT,
    UNIQUE(workout_template_id, order_index)
);

CREATE TABLE public.user_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    workout_template_id UUID REFERENCES public.workout_templates(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    total_duration_seconds INTEGER,
    notes TEXT,
    is_completed BOOLEAN DEFAULT false
);

CREATE TABLE public.workout_exercise_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_workout_id UUID REFERENCES public.user_workouts(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
    set_number INTEGER NOT NULL,
    reps INTEGER,
    weight_kg DECIMAL(6,2),
    duration_seconds INTEGER,
    distance_meters DECIMAL(8,2),
    rest_seconds INTEGER,
    completed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- 4. Nutrition Management Tables
CREATE TABLE public.food_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    brand TEXT,
    barcode TEXT,
    calories_per_100g DECIMAL(7,2) NOT NULL,
    protein_per_100g DECIMAL(5,2) DEFAULT 0,
    carbs_per_100g DECIMAL(5,2) DEFAULT 0,
    fat_per_100g DECIMAL(5,2) DEFAULT 0,
    fiber_per_100g DECIMAL(5,2) DEFAULT 0,
    sugar_per_100g DECIMAL(5,2) DEFAULT 0,
    sodium_per_100g DECIMAL(7,2) DEFAULT 0,
    is_verified BOOLEAN DEFAULT false,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.user_meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    meal_type public.meal_type NOT NULL,
    meal_date DATE NOT NULL,
    name TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.meal_food_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_id UUID REFERENCES public.user_meals(id) ON DELETE CASCADE,
    food_item_id UUID REFERENCES public.food_items(id) ON DELETE CASCADE,
    quantity_grams DECIMAL(7,2) NOT NULL,
    calories DECIMAL(7,2) NOT NULL,
    protein DECIMAL(5,2) DEFAULT 0,
    carbs DECIMAL(5,2) DEFAULT 0,
    fat DECIMAL(5,2) DEFAULT 0
);

-- 5. Progress Tracking Tables
CREATE TABLE public.user_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    measurement_type public.measurement_type NOT NULL,
    value DECIMAL(6,2) NOT NULL,
    unit TEXT NOT NULL DEFAULT 'kg',
    measured_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL,
    achievement_name TEXT NOT NULL,
    achievement_description TEXT,
    achieved_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    value DECIMAL(10,2),
    unit TEXT
);

-- 6. Water Tracking Table
CREATE TABLE public.user_water_intake (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    amount_ml INTEGER NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    date_logged DATE DEFAULT CURRENT_DATE
);

-- 7. Essential Indexes for Performance
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_username ON public.user_profiles(username);
CREATE INDEX idx_workout_templates_created_by ON public.workout_templates(created_by);
CREATE INDEX idx_workout_templates_type ON public.workout_templates(workout_type);
CREATE INDEX idx_exercises_muscle_group ON public.exercises(primary_muscle_group);
CREATE INDEX idx_exercises_type ON public.exercises(exercise_type);
CREATE INDEX idx_user_workouts_user_id ON public.user_workouts(user_id);
CREATE INDEX idx_user_workouts_date ON public.user_workouts(started_at);
CREATE INDEX idx_workout_sets_workout_id ON public.workout_exercise_sets(user_workout_id);
CREATE INDEX idx_food_items_name ON public.food_items(name);
CREATE INDEX idx_user_meals_user_date ON public.user_meals(user_id, meal_date);
CREATE INDEX idx_user_measurements_user_type ON public.user_measurements(user_id, measurement_type);
CREATE INDEX idx_water_intake_user_date ON public.user_water_intake(user_id, date_logged);

-- 8. Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_template_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercise_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_food_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_water_intake ENABLE ROW LEVEL SECURITY;

-- 9. Helper Functions (Created Before RLS Policies)
CREATE OR REPLACE FUNCTION public.is_admin_from_auth()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND (au.raw_user_meta_data->>'role' = 'admin' 
         OR au.raw_app_meta_data->>'role' = 'admin')
)
$$;

CREATE OR REPLACE FUNCTION public.can_access_workout_template(template_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.workout_templates wt
    WHERE wt.id = template_uuid
    AND (wt.is_public = true OR wt.created_by = auth.uid())
)
$$;

-- 10. RLS Policies
-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for personal data
CREATE POLICY "users_manage_own_workouts"
ON public.user_workouts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_workout_sets"
ON public.workout_exercise_sets
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_workouts uw
        WHERE uw.id = user_workout_id AND uw.user_id = auth.uid()
    )
);

CREATE POLICY "users_manage_own_meals"
ON public.user_meals
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_meal_items"
ON public.meal_food_items
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_meals um
        WHERE um.id = meal_id AND um.user_id = auth.uid()
    )
);

CREATE POLICY "users_manage_own_measurements"
ON public.user_measurements
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_achievements"
ON public.user_achievements
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_water_intake"
ON public.user_water_intake
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public read, private write for shared content
CREATE POLICY "public_can_read_exercises"
ON public.exercises
FOR SELECT
TO public
USING (true);

CREATE POLICY "users_manage_own_exercises"
ON public.exercises
FOR ALL
TO authenticated
USING (created_by = auth.uid() OR is_system_exercise = true)
WITH CHECK (created_by = auth.uid());

CREATE POLICY "public_can_read_food_items"
ON public.food_items
FOR SELECT
TO public
USING (true);

CREATE POLICY "users_manage_own_food_items"
ON public.food_items
FOR ALL
TO authenticated
USING (created_by = auth.uid() OR created_by IS NULL)
WITH CHECK (created_by = auth.uid());

-- Pattern 7: Complex access for workout templates
CREATE POLICY "users_view_accessible_workout_templates"
ON public.workout_templates
FOR SELECT
TO authenticated
USING (public.can_access_workout_template(id));

CREATE POLICY "users_manage_own_workout_templates"
ON public.workout_templates
FOR ALL
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

CREATE POLICY "users_manage_template_exercises"
ON public.workout_template_exercises
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.workout_templates wt
        WHERE wt.id = workout_template_id 
        AND (wt.created_by = auth.uid() OR wt.is_public = true)
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.workout_templates wt
        WHERE wt.id = workout_template_id AND wt.created_by = auth.uid()
    )
);

-- 11. Automatic Profile Creation Trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'member')::public.user_role
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 12. Mock Data for Testing
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    trainer_uuid UUID := gen_random_uuid();
    member_uuid UUID := gen_random_uuid();
    workout_template_id UUID := gen_random_uuid();
    exercise1_id UUID := gen_random_uuid();
    exercise2_id UUID := gen_random_uuid();
    food_item_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@bldr.com', crypt('BldrAdmin123!', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "BLDR Admin", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (trainer_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'trainer@bldr.com', crypt('BldrTrainer123!', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Trainer", "role": "trainer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (member_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'member@bldr.com', crypt('BldrMember123!', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Jane Member", "role": "member"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Insert system exercises
    INSERT INTO public.exercises (id, name, description, exercise_type, primary_muscle_group, secondary_muscle_groups, instructions, equipment_needed, is_system_exercise) VALUES
        (exercise1_id, 'Push-up', 'Classic bodyweight chest exercise', 'compound'::public.exercise_type, 'chest'::public.muscle_group, 
         ARRAY['shoulders'::public.muscle_group, 'triceps'::public.muscle_group], 
         ARRAY['Start in plank position', 'Lower body until chest nearly touches floor', 'Push back up to starting position'], 
         ARRAY['None'], true),
        (exercise2_id, 'Squats', 'Fundamental lower body exercise', 'compound'::public.exercise_type, 'legs'::public.muscle_group, 
         ARRAY['abs'::public.muscle_group], 
         ARRAY['Stand with feet shoulder-width apart', 'Lower body as if sitting in chair', 'Return to standing position'], 
         ARRAY['None'], true);

    -- Create sample workout template
    INSERT INTO public.workout_templates (id, name, description, workout_type, estimated_duration_minutes, difficulty_level, is_public, created_by) VALUES
        (workout_template_id, 'Beginner Full Body', 'Perfect workout for fitness beginners', 'strength'::public.workout_type, 30, 2, true, trainer_uuid);

    -- Add exercises to workout template
    INSERT INTO public.workout_template_exercises (workout_template_id, exercise_id, order_index, sets, reps, rest_seconds) VALUES
        (workout_template_id, exercise1_id, 1, 3, 10, 60),
        (workout_template_id, exercise2_id, 2, 3, 15, 60);

    -- Create sample food items
    INSERT INTO public.food_items (id, name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, is_verified) VALUES
        (food_item_id, 'Chicken Breast (Cooked)', 165.0, 31.0, 0.0, 3.6, true);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 13. Update Functions for Timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Apply timestamp triggers to relevant tables
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_workout_templates_updated_at
    BEFORE UPDATE ON public.workout_templates
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();