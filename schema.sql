create table user_admins
(
    id             uuid not null
        primary key
        references auth.users
            on update cascade on delete cascade,
    email          text not null,
    username       text not null,
    first_name     text not null,
    is_super_admin boolean                  default false,
    created_at     timestamp with time zone default now(),
    updated_at     timestamp with time zone default now(),
    last_name      text
);

create policy "allow all ops for superadmin" on user_admins
    as permissive
    for all
    to authenticated
    using is_super_admin
with check is_super_admin;

create policy "allow select for admin" on user_admins
    as permissive
    for select
    to authenticated
    using (auth.uid() = id);

create table user_alumni
(
    id          uuid not null
        primary key
        references auth.users
            on update cascade on delete cascade,
    first_name  text not null,
    last_name   text not null,
    email       text not null,
    is_approved boolean                  default false,
    created_at  timestamp with time zone default now(),
    updated_at  timestamp with time zone default now()
);

comment on table user_alumni is 'Table storing alumni user profiles with required email field';

create policy "Admins can delete alumni profiles" on user_alumni
    as permissive
    for delete
    using (EXISTS (SELECT 1
                   FROM user_admins
                   WHERE (user_admins.id = auth.uid())));

create policy "Admins can insert alumni profiles" on user_alumni
    as permissive
    for insert
    with check (EXISTS (SELECT 1
                        FROM user_admins
                        WHERE (user_admins.id = auth.uid())));

create policy "Admins can update alumni profiles" on user_alumni
    as permissive
    for update
    using (EXISTS (SELECT 1
                   FROM user_admins
                   WHERE (user_admins.id = auth.uid())));

create policy "Admins can view all alumni profiles" on user_alumni
    as permissive
    for select
    using (EXISTS (SELECT 1
                   FROM user_admins
                   WHERE (user_admins.id = auth.uid())));

create policy "Alumni can update own data" on user_alumni
    as permissive
    for update
    to authenticated
    using (id = auth.uid());

create policy "Alumni can update their own profile" on user_alumni
    as permissive
    for update
    using (id = auth.uid());

create policy "Alumni can view own data" on user_alumni
    as permissive
    for select
    to authenticated
    using (id = auth.uid());

create policy "Alumni can view their own profile" on user_alumni
    as permissive
    for select
    using (id = auth.uid());

create policy "Anyone can register as alumni" on user_alumni
    as permissive
    for insert
    to anon, authenticated
    with check true;

create policy "Users can insert their own alumni profile during registration" on user_alumni
    as permissive
    for insert
    with check (id = auth.uid());

create table user_companies
(
    id           uuid not null
        primary key
        references auth.users
            on update cascade on delete cascade,
    company_name text not null,
    email        text not null,
    is_approved  boolean                  default false,
    created_at   timestamp with time zone default now(),
    updated_at   timestamp with time zone default now()
);

create table internships
(
    id               uuid                     default gen_random_uuid() not null
        primary key,
    company_id       uuid                                               not null
        references user_companies
            on update cascade on delete cascade,
    title            text                                               not null,
    description      text                                               not null,
    duration         text                                               not null,
    skills           text[]                                             not null,
    is_approved      boolean,
    created_at       timestamp with time zone default now(),
    updated_at       timestamp with time zone default now(),
    is_active        boolean                  default true              not null,
    rejection_reason text
);

create policy "allow all ops for admin" on internships
    as permissive
    for all
    to authenticated
    using is_user_admin()
with check is_user_admin();

create policy "allow all ops for company" on internships
    as permissive
    for all
    to authenticated
    using (company_id = auth.uid())
    with check (company_id = auth.uid());

create policy "allow select for all" on internships
    as permissive
    for select
    using true;

create policy "allow all ops for admin" on user_companies
    as permissive
    for all
    to authenticated
    using is_user_admin()
with check is_user_admin();

create policy "allow all ops for company" on user_companies
    as permissive
    for all
    to authenticated
    using (auth.uid() = id)
    with check (auth.uid() = id);

create policy "allow select for all" on user_companies
    as permissive
    for select
    using true;

create table user_content_creators
(
    id          uuid not null
        primary key
        references auth.users
            on update cascade on delete cascade,
    first_name  text not null,
    last_name   text not null,
    birthdate   date,
    email       text not null,
    is_approved boolean                  default false,
    created_at  timestamp with time zone default now(),
    updated_at  timestamp with time zone default now(),
    bio         text,
    phone       numeric
);

create table courses
(
    id               uuid                     default gen_random_uuid() not null
        primary key,
    title            text                     default ''::text          not null,
    updated_at       timestamp with time zone default now(),
    created_at       timestamp with time zone default now(),
    creator_id       uuid                                               not null
        references user_content_creators
            on update cascade on delete cascade,
    is_approved      boolean                  default false,
    is_active        boolean                  default true,
    rejection_reason text,
    description      text
);

create table course_changes
(
    id               uuid                     default gen_random_uuid() not null
        primary key,
    course_id        uuid
        references courses
            on delete cascade,
    title            text,
    description      text,
    is_reviewed      boolean                  default false,
    is_approved      boolean,
    rejection_reason text,
    created_at       timestamp with time zone default now(),
    updated_at       timestamp with time zone default now()
);

create policy "allow all ops for admin" on course_changes
    as permissive
    for all
    to authenticated
    using is_user_admin()
with check is_user_admin();

create policy "allow all ops for content creator" on course_changes
    as permissive
    for all
    to authenticated
    using (course_id IN (SELECT courses.id
                         FROM courses
                         WHERE (courses.creator_id = auth.uid())))
    with check (course_id IN (SELECT courses.id
                              FROM courses
                              WHERE (courses.creator_id = auth.uid())));

create policy "course changes can be selected by everyone" on course_changes
    as permissive
    for select
    using true;

create table course_videos
(
    id               uuid                     default gen_random_uuid() not null
        primary key,
    course_id        uuid                                               not null
        references courses
            on delete cascade,
    title            text                                               not null,
    description      text                                               not null,
    video_url        text                                               not null,
    sequence_number  integer                                            not null,
    created_at       timestamp with time zone default now()             not null,
    updated_at       timestamp with time zone default now()             not null,
    is_reviewed      boolean,
    is_approved      boolean,
    rejection_reason text
);

create policy "allow all ops for admin" on course_videos
    as permissive
    for all
    to authenticated
    using is_user_admin()
with check is_user_admin();

create policy "allow all ops for content creator" on course_videos
    as permissive
    for all
    to authenticated
    using (course_id IN (SELECT courses.id
                         FROM courses
                         WHERE (courses.creator_id = auth.uid())))
    with check (course_id IN (SELECT courses.id
                              FROM courses
                              WHERE (courses.creator_id = auth.uid())));

create policy "allow select for all" on course_videos
    as permissive
    for select
    using true;

create policy "allow all ops for admin" on courses
    as permissive
    for all
    to authenticated
    using is_user_admin()
with check is_user_admin();

create policy "allow all ops for content creator" on courses
    as permissive
    for all
    to authenticated
    using (creator_id = auth.uid())
    with check (creator_id = auth.uid());

create policy "allow select for all" on courses
    as permissive
    for select
    using true;

create policy "allow all ops for admin" on user_content_creators
    as permissive
    for all
    to authenticated
    using is_user_admin()
with check is_user_admin();

create policy "allow all ops for content creator" on user_content_creators
    as permissive
    for all
    to authenticated
    using (auth.uid() = id)
    with check (auth.uid() = id);

create policy "allow select for all" on user_content_creators
    as permissive
    for select
    using true;

create table user_students
(
    id                 uuid                     default auth.uid() not null
        primary key
        references auth.users
            on update cascade on delete cascade,
    first_name         text,
    last_name          text,
    birthdate          date,
    premium            boolean                  default false      not null,
    premium_expires_at timestamp with time zone,
    created_at         timestamp with time zone default now()      not null,
    active             boolean                  default true       not null,
    gender             text,
    updated_at         timestamp with time zone default now()      not null,
    email              text
);

create policy "allow all ops for admin" on user_students
    as permissive
    for all
    to authenticated
    using is_user_admin()
with check is_user_admin();

create policy "allow all ops for student" on user_students
    as permissive
    for all
    to authenticated
    using (auth.uid() = id)
    with check (auth.uid() = id);

create policy "allow select for all" on user_students
    as permissive
    for select
    using true;

create table video_changes
(
    id               uuid                     default gen_random_uuid() not null
        primary key,
    course_video_id  uuid
        references course_videos
            on delete cascade,
    title            text,
    description      text,
    video_url        text,
    is_reviewed      boolean                  default false,
    is_approved      boolean,
    rejection_reason text,
    created_at       timestamp with time zone default now(),
    updated_at       timestamp with time zone default now()
);

create policy "allow all ops for admin" on video_changes
    as permissive
    for all
    to authenticated
    using is_user_admin()
with check is_user_admin();

create policy "allow all ops for content creator" on video_changes
    as permissive
    for all
    to authenticated
    using (course_video_id IN (SELECT course_videos.id
                               FROM course_videos
                               WHERE (course_videos.course_id IN (SELECT courses.id
                                                                  FROM courses
                                                                  WHERE (courses.creator_id = auth.uid())))))
    with check (course_video_id IN (SELECT course_videos.id
                                    FROM course_videos
                                    WHERE (course_videos.course_id IN (SELECT courses.id
                                                                       FROM courses
                                                                       WHERE (courses.creator_id = auth.uid())))));

create policy "video changes can be selected by everyone" on video_changes
    as permissive
    for select
    using true;

create table settings
(
    key        text                                   not null
        primary key,
    value      text                                   not null,
    updated_at timestamp with time zone default now() not null
);

create policy "Enable read access for all users" on settings
    as permissive
    for select
    to authenticated
    using true;

create function approve_course_changes(p_course_id uuid) returns void
    security definer
    language plpgsql
as
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
        description = v_course_change.description
    WHERE id = p_course_id;

    -- Mark change as reviewed and approved
    UPDATE course_changes
    SET is_reviewed = true,
        is_approved = true
    WHERE id = v_course_change.id;
  END IF;
END;
$$;

create function get_user_type_and_status()
    returns TABLE(user_type text, is_approved boolean, is_super_admin boolean)
    security definer
    language plpgsql
as
$$
DECLARE
  user_id UUID := auth.uid();
BEGIN
  -- Check if user is an admin
  IF EXISTS (SELECT 1 FROM user_admins WHERE id = user_id) THEN
    RETURN QUERY SELECT
      'admin'::TEXT,
      TRUE::BOOLEAN,
      (SELECT user_admins.is_super_admin FROM user_admins WHERE user_admins.id = user_id);
  -- Check if user is a content creator
  ELSIF EXISTS (SELECT 1 FROM user_content_creators WHERE id = user_id) THEN
    RETURN QUERY SELECT
      'content_creator'::TEXT,
      (SELECT user_content_creators.is_approved FROM user_content_creators WHERE user_content_creators.id = user_id),
      FALSE::BOOLEAN;
  -- Check if user is an alumni
  ELSIF EXISTS (SELECT 1 FROM user_alumni WHERE id = user_id) THEN
    RETURN QUERY SELECT
      'alumni'::TEXT,
      (SELECT user_alumni.is_approved FROM user_alumni WHERE user_alumni.id = user_id),
      FALSE::BOOLEAN;
  -- Check if user is a company
  ELSIF EXISTS (SELECT 1 FROM user_companies WHERE id = user_id) THEN
    RETURN QUERY SELECT
      'company'::TEXT,
      (SELECT user_companies.is_approved FROM user_companies WHERE user_companies.id = user_id),
      FALSE::BOOLEAN;
  ELSE
    RETURN QUERY SELECT NULL::TEXT, NULL::BOOLEAN, NULL::BOOLEAN;
  END IF;
END;
$$;

create function handle_new_user_safe() returns trigger
    security definer
    SET search_path = public
    language plpgsql
as
$$
DECLARE
    required_field text;
    missing_fields text[];
BEGIN
    -- Common validation
    IF NEW.raw_user_meta_data IS NULL OR NEW.raw_user_meta_data::text = '{}'::text THEN
        RAISE EXCEPTION 'User metadata cannot be empty';
    END IF;

    IF NEW.raw_user_meta_data ->> 'p_user_type' IS NULL THEN
        RAISE EXCEPTION 'User type (p_user_type) is required in metadata';
    END IF;

    -- Handle student user
    IF NEW.raw_user_meta_data ->> 'p_user_type' = 'user_student' THEN
        -- Validate required fields




            INSERT INTO user_students(id , email)
            VALUES (NEW.id , NEW.email);

    END IF;

    -- If no recognized user type was processed
    IF NEW.raw_user_meta_data ->> 'p_user_type' NOT IN ('user_student', 'user_alumni', 'user_company', 'user_content_creator', 'user_admin') THEN
        RAISE EXCEPTION 'Invalid user type: %', NEW.raw_user_meta_data ->> 'p_user_type';
    END IF;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'User creation failed: %', SQLERRM;
END;
$$;

create function is_user_admin() returns boolean
    security definer
    language sql
as
$$
SELECT EXISTS (
    SELECT 1
    FROM public.user_admins
    WHERE id = auth.uid()
);
$$;

create function update_updated_at() returns trigger
    language plpgsql
as
$$
BEGIN
    NEW.updated_at := NOW();  -- Set timestamp to the current timestamp
RETURN NEW;  -- Return the updated row
END;
$$;

create trigger set_updated_at
    before insert or update
    on course_changes
    for each row
execute procedure update_updated_at();

create trigger set_updated_at
    before insert or update
    on course_videos
    for each row
execute procedure update_updated_at();

create trigger set_updated_at
    before insert or update
    on courses
    for each row
execute procedure update_updated_at();

create trigger set_updated_at
    before insert or update
    on internships
    for each row
execute procedure update_updated_at();

create trigger set_updated_at
    before insert or update
    on user_admins
    for each row
execute procedure update_updated_at();

create trigger set_updated_at
    before insert or update
    on user_alumni
    for each row
execute procedure update_updated_at();

create trigger set_updated_at
    before insert or update
    on user_companies
    for each row
execute procedure update_updated_at();

create trigger set_updated_at
    before insert or update
    on user_content_creators
    for each row
execute procedure update_updated_at();

create trigger set_updated_at
    before insert or update
    on user_students
    for each row
execute procedure update_updated_at();

create trigger set_updated_at
    before insert or update
    on video_changes
    for each row
execute procedure update_updated_at();

create function rpc_delete_account() returns void
    security definer
    language plpgsql
as
$$
BEGIN
    IF is_user_admin() THEN
        RAISE EXCEPTION 'Cannot delete an admin account';
    END IF;

    DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

create function get_content_creator_with_email(creator_id uuid)
    returns TABLE(id uuid, first_name text, last_name text, bio text, phone text, birthdate date, is_approved boolean, created_at timestamp with time zone, updated_at timestamp with time zone, email text)
    security definer
    language plpgsql
as
$$
BEGIN
  RETURN QUERY
  SELECT
    ucc.id,
    ucc.first_name,
    ucc.last_name,
    ucc.bio,
    ucc.phone,
    ucc.birthdate,
    ucc.is_approved,
    ucc.created_at,
    ucc.updated_at,
    au.email
  FROM
    public.user_content_creators ucc
  INNER JOIN
    auth.users au ON ucc.id = au.id
  WHERE
    ucc.id = creator_id;
END;
$$;


