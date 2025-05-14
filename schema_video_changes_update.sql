-- Add missing fields to video_changes table
ALTER TABLE public.video_changes
ADD COLUMN thumbnail_url text,
ADD COLUMN is_free_preview boolean;
