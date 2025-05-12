-- Create chat_conversations table to track conversations between users
CREATE TABLE chat_conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create chat_participants table to track users in each conversation
CREATE TABLE chat_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    user_type TEXT NOT NULL, -- 'alumni' or 'student'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(conversation_id, user_id)
);

-- Create chat_messages table to store messages
CREATE TABLE chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add triggers for updated_at timestamps
CREATE TRIGGER set_updated_at
    BEFORE INSERT OR UPDATE ON chat_conversations
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at();

CREATE TRIGGER set_updated_at
    BEFORE INSERT OR UPDATE ON chat_participants
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at();

CREATE TRIGGER set_updated_at
    BEFORE INSERT OR UPDATE ON chat_messages
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at();

-- Create RLS policies for chat_conversations
CREATE POLICY "Users can view conversations they're part of" ON chat_conversations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chat_participants 
            WHERE chat_participants.conversation_id = id 
            AND chat_participants.user_id = auth.uid()
        )
    );

CREATE POLICY "Alumni can insert conversations" ON chat_conversations
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_alumni
            WHERE user_alumni.id = auth.uid()
            AND user_alumni.is_approved = true
        )
    );

-- Create RLS policies for chat_participants
CREATE POLICY "Users can view participants in their conversations" ON chat_participants
    FOR SELECT USING (
        conversation_id IN (
            SELECT conversation_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Alumni can add participants" ON chat_participants
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_alumni
            WHERE user_alumni.id = auth.uid()
            AND user_alumni.is_approved = true
        )
    );

-- Create RLS policies for chat_messages
CREATE POLICY "Users can view messages in their conversations" ON chat_messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT conversation_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can send messages to conversations they're in" ON chat_messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        conversation_id IN (
            SELECT conversation_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update read status of messages in their conversations" ON chat_messages
    FOR UPDATE USING (
        conversation_id IN (
            SELECT conversation_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    ) WITH CHECK (
        conversation_id IN (
            SELECT conversation_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );
