-- Add membership_type column to courses table
ALTER TABLE courses
ADD COLUMN IF NOT EXISTS membership_type TEXT DEFAULT 'PRO';

-- Add difficulty column to courses table
ALTER TABLE courses
ADD COLUMN IF NOT EXISTS difficulty TEXT DEFAULT 'MEDIUM';
