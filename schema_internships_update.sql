-- Add new columns to the internships table
ALTER TABLE internships
ADD COLUMN is_paid BOOLEAN DEFAULT false NOT NULL,
ADD COLUMN city TEXT;

-- Update the comment on the table to reflect the new fields
COMMENT ON TABLE internships IS 'Table storing internship opportunities posted by companies with paid/unpaid status and city location';

-- Add comments on the new columns
COMMENT ON COLUMN internships.is_paid IS 'Indicates whether the internship is paid (true) or unpaid (false)';
COMMENT ON COLUMN internships.city IS 'The city where the internship is located';
