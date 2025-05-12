-- Gift Cards Schema

-- Gift Cards Table
CREATE TABLE gift_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    is_used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP WITH TIME ZONE,
    used_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_by UUID NOT NULL REFERENCES user_admins(id),
    expires_at TIMESTAMP WITH TIME ZONE,
    notes TEXT
);

-- RLS Policies for gift_cards table
CREATE POLICY "Allow admins full access to gift cards" ON gift_cards
    FOR ALL
    TO authenticated
    USING (EXISTS (SELECT 1 FROM user_admins WHERE user_admins.id = auth.uid()))
    WITH CHECK (EXISTS (SELECT 1 FROM user_admins WHERE user_admins.id = auth.uid()));

CREATE POLICY "Allow users to view and use their own gift cards" ON gift_cards
    FOR SELECT
    TO authenticated
    USING (used_by = auth.uid() OR is_used = FALSE);

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

-- Function to create a new gift card
CREATE OR REPLACE FUNCTION create_gift_card(
    p_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID;
    v_gift_card_id UUID;
BEGIN
    -- Check if the user is an admin
    SELECT id INTO v_admin_id FROM user_admins WHERE id = auth.uid();
    
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Only admins can create gift cards';
    END IF;
    
    -- Insert new gift card
    INSERT INTO gift_cards (
        code,
        created_by,
        expires_at,
        notes
    ) VALUES (
        generate_gift_card_code(),
        v_admin_id,
        p_expires_at,
        p_notes
    ) RETURNING id INTO v_gift_card_id;
    
    RETURN v_gift_card_id;
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
BEGIN
    -- Get the gift card
    SELECT * INTO v_gift_card_record
    FROM gift_cards
    WHERE code = p_code
    FOR UPDATE;
    
    -- Check if gift card exists
    IF v_gift_card_record.id IS NULL THEN
        RAISE EXCEPTION 'Gift card not found';
    END IF;
    
    -- Check if gift card is already used
    IF v_gift_card_record.is_used THEN
        RAISE EXCEPTION 'Gift card has already been used';
    END IF;
    
    -- Check if gift card is expired
    IF v_gift_card_record.expires_at IS NOT NULL AND v_gift_card_record.expires_at < now() THEN
        RAISE EXCEPTION 'Gift card has expired';
    END IF;
    
    -- Update gift card as used
    UPDATE gift_cards
    SET 
        is_used = TRUE,
        used_at = now(),
        used_by = auth.uid()
    WHERE id = v_gift_card_record.id;
    
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
        'used_cards', COUNT(*) FILTER (WHERE is_used = TRUE)::BIGINT,
        'unused_cards', COUNT(*) FILTER (WHERE is_used = FALSE)::BIGINT
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
