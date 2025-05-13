-- Gift Cards Schema

-- Gift Cards Table
CREATE TABLE gift_cards (
  code TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  redeemed_at TIMESTAMP WITH TIME ZONE NULL,
  redeemed_by UUID NULL,
  days INTEGER NOT NULL DEFAULT 365,
  serial BIGSERIAL NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  metadata TEXT NOT NULL DEFAULT ''::TEXT,
  generated_by UUID NULL,
  CONSTRAINT gift_cards_pkey PRIMARY KEY (code),
  CONSTRAINT gift_cards_serial_key UNIQUE (serial),
  CONSTRAINT gift_cards_generated_by_fkey FOREIGN KEY (generated_by) REFERENCES user_admins (id),
  CONSTRAINT gift_cards_redeemed_by_fkey FOREIGN KEY (redeemed_by) REFERENCES user_students (id) ON DELETE CASCADE,
  CONSTRAINT check_column_format CHECK (
    (
      (length(code) = 16)
      AND (code ~ '^[0-9A-Z]{16}$'::TEXT)
    )
  )
);

CREATE INDEX IF NOT EXISTS gift_cards_updated_at_idx ON gift_cards USING btree (updated_at);

-- Function to generate a unique gift card code
CREATE OR REPLACE FUNCTION generate_gift_card_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a random alphanumeric code (16 characters)
        new_code := upper(substring(md5(random()::text) from 1 for 16));
        
        -- Check if the code already exists
        SELECT EXISTS (
            SELECT 1 FROM gift_cards WHERE code = new_code
        ) INTO code_exists;
        
        -- Exit loop if code is unique
        EXIT WHEN NOT code_exists;
    END LOOP;
    
    RETURN new_code;
END;
$$;

-- Function to create new gift cards
CREATE OR REPLACE FUNCTION generate_gift_cards(
    p_days INTEGER DEFAULT 365,
    p_metadata TEXT DEFAULT '',
    p_quantity INTEGER DEFAULT 1
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID;
    v_codes TEXT DEFAULT '';
    v_code TEXT;
    i INTEGER;
BEGIN
    -- Check if the user is an admin
    SELECT id INTO v_admin_id FROM user_admins WHERE id = auth.uid();
    
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Only admins can create gift cards';
    END IF;
    
    -- Create multiple gift cards if quantity > 1
    FOR i IN 1..p_quantity LOOP
        -- Generate a unique code
        v_code := generate_gift_card_code();
        
        -- Insert new gift card
        INSERT INTO gift_cards (
            code,
            days,
            metadata,
            generated_by
        ) VALUES (
            v_code,
            p_days,
            p_metadata,
            v_admin_id
        );
        
        -- Append code to result
        IF i > 1 THEN
            v_codes := v_codes || ', ';
        END IF;
        v_codes := v_codes || v_code;
    END LOOP;
    
    RETURN v_codes;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating gift card: %', SQLERRM;
        RAISE;
END;
$$;

-- Function to use a gift card
CREATE OR REPLACE FUNCTION use_gift_card(
    p_code TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_gift_card_record gift_cards%ROWTYPE;
    v_student_id UUID;
BEGIN
    -- Get the student ID
    SELECT id INTO v_student_id FROM user_students WHERE id = auth.uid();
    
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Only students can use gift cards';
    END IF;

    -- Get the gift card
    SELECT * INTO v_gift_card_record
    FROM gift_cards
    WHERE code = p_code
    FOR UPDATE;
    
    -- Check if gift card exists
    IF v_gift_card_record.code IS NULL THEN
        RAISE EXCEPTION 'Gift card not found';
    END IF;
    
    -- Check if gift card is already used
    IF v_gift_card_record.redeemed_at IS NOT NULL THEN
        RAISE EXCEPTION 'Gift card has already been used';
    END IF;
    
    -- Update gift card as used
    UPDATE gift_cards
    SET 
        redeemed_at = now(),
        redeemed_by = v_student_id
    WHERE code = v_gift_card_record.code;
    
    RETURN TRUE;
END;
$$;

-- Function to get gift card statistics
CREATE OR REPLACE FUNCTION get_gift_card_stats()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_cards', COUNT(*)::BIGINT,
        'used_cards', COUNT(*) FILTER (WHERE redeemed_at IS NOT NULL)::BIGINT,
        'unused_cards', COUNT(*) FILTER (WHERE redeemed_at IS NULL)::BIGINT
    ) INTO result
    FROM gift_cards;
    
    RETURN result;
END;
$$;

-- Add trigger for updated_at
CREATE TRIGGER set_updated_at
    BEFORE INSERT OR UPDATE
    ON gift_cards
    FOR EACH ROW
EXECUTE PROCEDURE update_updated_at();
