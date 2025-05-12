-- Add new fields to user_alumni table
ALTER TABLE user_alumni
ADD COLUMN birthdate DATE,
ADD COLUMN graduation_year INTEGER,
ADD COLUMN university TEXT,
ADD COLUMN experience TEXT;

-- Update comment on table
COMMENT ON TABLE user_alumni IS 'Table storing alumni user profiles with additional education and experience information';
