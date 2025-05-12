-- Add thumbnail_url to course_videos table
ALTER TABLE course_videos ADD COLUMN thumbnail_url TEXT;

-- Add membership_type to courses table
ALTER TABLE courses ADD COLUMN membership_type TEXT NOT NULL DEFAULT 'PRO';

-- Add is_free_preview to course_videos table
ALTER TABLE course_videos ADD COLUMN is_free_preview BOOLEAN NOT NULL DEFAULT FALSE;
