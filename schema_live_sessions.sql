-- Live Sessions Table
create table live_sessions (
    id uuid default gen_random_uuid() not null primary key,
    creator_id uuid not null references user_content_creators(id) on delete cascade,
    course_id uuid not null references courses(id) on delete cascade,
    title text not null,
    status text not null check (status in ('active', 'ended')),
    channel_name text not null,
    started_at timestamp with time zone default now(),
    ended_at timestamp with time zone,
    viewer_count integer default 0,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Add appropriate policies
create policy "allow all ops for admin" on live_sessions
    as permissive
    for all
    to authenticated
    using (is_user_admin)
    with check (is_user_admin);

create policy "allow all ops for content creator" on live_sessions
    as permissive
    for all
    to authenticated
    using (creator_id = auth.uid())
    with check (creator_id = auth.uid());

create policy "allow select for all" on live_sessions
    as permissive
    for select
    using (true);

-- Add trigger for updated_at
create trigger set_updated_at
    before insert or update
    on live_sessions
    for each row
execute procedure update_updated_at();
