-- Add onboarding tracking columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarding_goal text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferred_categories jsonb;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarding_completed_at timestamptz;
