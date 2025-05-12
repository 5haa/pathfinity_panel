-- Add profile_picture_url column to user_students table
ALTER TABLE user_students
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;
