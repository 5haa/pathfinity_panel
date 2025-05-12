-- Add profile_picture_url column to user_admins table
ALTER TABLE user_admins
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;

-- Add profile_picture_url column to user_alumni table
ALTER TABLE user_alumni
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;

-- Add profile_picture_url column to user_companies table
ALTER TABLE user_companies
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;

-- Add profile_picture_url column to user_content_creators table
ALTER TABLE user_content_creators
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;
