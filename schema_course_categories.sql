-- Create course_categories table
CREATE TABLE course_categories (
    id UUID DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Add category_id to courses table
ALTER TABLE courses ADD COLUMN category_id UUID REFERENCES course_categories(id);

-- Add category_id to course_changes table to track category changes
ALTER TABLE course_changes ADD COLUMN category_id UUID;

-- Create trigger for updated_at
CREATE TRIGGER set_updated_at
BEFORE INSERT OR UPDATE ON course_categories
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at();

-- Add policies for course_categories
CREATE POLICY "Allow admins full access to categories" ON course_categories
    AS PERMISSIVE FOR ALL
    TO authenticated
    USING (is_user_admin())
    WITH CHECK (is_user_admin());

CREATE POLICY "Allow all users to view categories" ON course_categories
    AS PERMISSIVE FOR SELECT
    USING (true);

-- Insert some default categories
INSERT INTO course_categories (name, description) VALUES
    ('Programming', 'Courses related to programming and software development'),
    ('Design', 'Courses related to graphic design, UI/UX, and visual arts'),
    ('Business', 'Courses related to business management, entrepreneurship, and marketing'),
    ('Science', 'Courses related to scientific disciplines'),
    ('Mathematics', 'Courses related to mathematical concepts and applications'),
    ('Language', 'Courses related to language learning and linguistics'),
    ('Arts', 'Courses related to fine arts, music, and creative expression'),
    ('Health', 'Courses related to health, wellness, and medical topics'),
    ('Technology', 'Courses related to technology, IT, and computer science'),
    ('Other', 'Other courses that don\'t fit into specific categories');

-- Update the approve_course_changes function to include category_id
CREATE OR REPLACE FUNCTION approve_course_changes(p_course_id uuid) RETURNS void
    SECURITY DEFINER
    LANGUAGE plpgsql
AS
$$
DECLARE
  v_course_change course_changes;
BEGIN
  -- Get the latest unreviewed change
  SELECT * INTO v_course_change
  FROM course_changes
  WHERE course_id = p_course_id
    AND is_reviewed = false
  ORDER BY created_at DESC
  LIMIT 1;

  IF FOUND THEN
    -- Update the course with new values
    UPDATE courses
    SET title = v_course_change.title,
        description = v_course_change.description,
        category_id = v_course_change.category_id
    WHERE id = p_course_id;

    -- Mark change as reviewed and approved
    UPDATE course_changes
    SET is_reviewed = true,
        is_approved = true
    WHERE id = v_course_change.id;
  END IF;
END;
$$;
