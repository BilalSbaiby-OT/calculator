-- HostCompliant — Supabase Database Schema
-- Run this in Supabase SQL Editor to create the full schema
-- Version: 1.0 — MVP

-- ============================================================
-- EXTENSIONS
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pg_trgm"; -- for fuzzy text search


-- ============================================================
-- ENUMS
-- ============================================================

create type subscription_tier as enum ('free', 'solo', 'host', 'professional');
create type property_type as enum ('entire_apartment', 'entire_house', 'private_room', 'bb');
create type compliance_status as enum ('not_started', 'in_progress', 'done', 'not_applicable');
create type compliance_category as enum ('permits', 'tax_registration', 'safety', 'display_requirements', 'guest_reporting', 'operational_limits', 'insurance', 'other');
create type deadline_type as enum ('one_time', 'annual', 'quarterly', 'monthly', 'event_based');
create type alert_severity as enum ('info', 'warning', 'critical');
create type user_role as enum ('user', 'admin');


-- ============================================================
-- CITIES
-- ============================================================

create table cities (
  id                  uuid primary key default uuid_generate_v4(),
  name                varchar(100) not null,
  slug                varchar(100) not null unique,         -- e.g. 'barcelona', 'paris'
  country             varchar(100) not null,
  country_code        char(2) not null,                     -- ISO 3166-1 alpha-2: 'ES', 'FR'
  language_code       varchar(10) not null default 'en',    -- primary language: 'fr', 'es', 'nl'
  timezone            varchar(50) not null default 'Europe/Paris',
  regulatory_summary  text,                                 -- plain-language overview
  official_source_url text,                                 -- link to main govt STR page
  last_reviewed_at    timestamptz,                          -- when compliance items were last verified
  is_active           boolean not null default false,       -- false = not yet published
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- Seed: launch cities
insert into cities (name, slug, country, country_code, language_code, timezone, is_active) values
  ('Paris',      'paris',      'France',      'FR', 'fr', 'Europe/Paris',     true),
  ('Barcelona',  'barcelona',  'Spain',       'ES', 'es', 'Europe/Madrid',    true),
  ('Amsterdam',  'amsterdam',  'Netherlands', 'NL', 'nl', 'Europe/Amsterdam', true),
  ('Lisbon',     'lisbon',     'Portugal',    'PT', 'pt', 'Europe/Lisbon',    true),
  ('Rome',       'rome',       'Italy',       'IT', 'it', 'Europe/Rome',      true);


-- ============================================================
-- COMPLIANCE ITEMS
-- ============================================================

create table compliance_items (
  id                        uuid primary key default uuid_generate_v4(),
  city_id                   uuid not null references cities(id) on delete cascade,
  category                  compliance_category not null,
  title                     varchar(200) not null,
  short_description         text not null,                  -- shown in the checklist row
  full_description          text,                           -- shown when user expands item
  how_to_comply             text,                           -- step-by-step guide
  official_url              text,                           -- link to government page
  penalty_description       varchar(500),                   -- human-readable: "Up to €90,000"
  penalty_min_eur           integer,                        -- min fine in EUR (for sorting)
  penalty_max_eur           integer,                        -- max fine in EUR
  deadline_type             deadline_type not null default 'one_time',
  -- For annual deadlines: day and month (e.g. 31 January = day=31, month=1)
  deadline_day              smallint check (deadline_day between 1 and 31),
  deadline_month            smallint check (deadline_month between 1 and 12),
  -- For event-based: description of when the deadline triggers
  deadline_event_description varchar(300),
  is_mandatory              boolean not null default true,
  -- Which property types this applies to (null = all)
  applies_to_property_types property_type[],
  -- Difficulty rating
  difficulty                smallint check (difficulty between 1 and 3), -- 1=easy, 2=moderate, 3=complex
  display_order             smallint not null default 100,  -- for ordering within category
  is_active                 boolean not null default true,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);

create index idx_compliance_items_city on compliance_items(city_id);
create index idx_compliance_items_active on compliance_items(is_active);


-- ============================================================
-- USER PROFILES
-- (extends Supabase auth.users)
-- ============================================================

create table user_profiles (
  id                  uuid primary key references auth.users(id) on delete cascade,
  email               varchar(255) not null,
  full_name           varchar(200),
  role                user_role not null default 'user',
  subscription_tier   subscription_tier not null default 'free',
  stripe_customer_id  varchar(100) unique,
  stripe_sub_id       varchar(100) unique,
  sub_current_period_end timestamptz,
  -- Notification preferences
  notif_reminder_90d  boolean not null default true,
  notif_reminder_30d  boolean not null default true,
  notif_reminder_7d   boolean not null default true,
  notif_reminder_1d   boolean not null default true,
  notif_alerts        boolean not null default true,
  notif_product       boolean not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- Auto-create profile on user sign-up
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into user_profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', '')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();


-- ============================================================
-- PROPERTIES
-- ============================================================

create table properties (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  city_id         uuid not null references cities(id),
  name            varchar(200) not null,                   -- user-given nickname
  property_type   property_type not null,
  platforms       text[] not null default '{}',            -- ['airbnb', 'booking_com', 'vrbo']
  -- Optional: street address (not required, for user's own reference)
  address_line    varchar(300),
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_properties_user on properties(user_id);
create index idx_properties_city on properties(city_id);

-- Enforce property limits per subscription tier
-- (enforced at application layer, not DB layer, for flexibility)


-- ============================================================
-- COMPLIANCE STATUSES
-- Per property × compliance item
-- ============================================================

create table compliance_statuses (
  id                  uuid primary key default uuid_generate_v4(),
  property_id         uuid not null references properties(id) on delete cascade,
  compliance_item_id  uuid not null references compliance_items(id) on delete cascade,
  status              compliance_status not null default 'not_started',
  completed_at        timestamptz,                          -- when marked 'done'
  notes               text,                                 -- user notes
  -- Calculated deadline for this property × item combo
  -- Stored here so we can query "what's due next" efficiently
  next_deadline_at    date,
  -- Has user been reminded? (reset each year for annual items)
  reminded_90d        boolean not null default false,
  reminded_30d        boolean not null default false,
  reminded_7d         boolean not null default false,
  reminded_1d         boolean not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (property_id, compliance_item_id)
);

create index idx_compliance_statuses_property on compliance_statuses(property_id);
create index idx_compliance_statuses_deadline on compliance_statuses(next_deadline_at);
create index idx_compliance_statuses_status on compliance_statuses(status);


-- ============================================================
-- DOCUMENTS
-- Files uploaded by users per compliance item
-- ============================================================

create table documents (
  id                  uuid primary key default uuid_generate_v4(),
  property_id         uuid not null references properties(id) on delete cascade,
  compliance_item_id  uuid references compliance_items(id) on delete set null,
  user_id             uuid not null references auth.users(id) on delete cascade,
  -- Supabase Storage path: documents/{user_id}/{property_id}/{filename}
  storage_path        text not null,
  original_filename   varchar(500) not null,
  mime_type           varchar(100),
  file_size_bytes     integer,
  created_at          timestamptz not null default now()
);

create index idx_documents_property on documents(property_id);
create index idx_documents_user on documents(user_id);


-- ============================================================
-- REGULATORY ALERTS
-- Published by admin; sent to users in affected city
-- ============================================================

create table regulatory_alerts (
  id              uuid primary key default uuid_generate_v4(),
  city_id         uuid not null references cities(id) on delete cascade,
  severity        alert_severity not null default 'info',
  title           varchar(300) not null,
  summary         varchar(500) not null,                   -- used in email subject/preview
  full_text       text not null,
  source_url      text,
  published_at    timestamptz not null default now(),
  -- Tracking
  emails_sent     integer not null default 0,
  created_by      uuid references auth.users(id),
  created_at      timestamptz not null default now()
);

create index idx_alerts_city on regulatory_alerts(city_id);
create index idx_alerts_published on regulatory_alerts(published_at desc);


-- ============================================================
-- EMAIL LOGS
-- Track every transactional email sent
-- ============================================================

create table email_logs (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  email_type      varchar(100) not null,  -- 'reminder_30d', 'alert_critical', 'welcome', etc.
  subject         varchar(500),
  -- Reference to source entity (alert or compliance item)
  related_alert_id        uuid references regulatory_alerts(id),
  related_compliance_id   uuid references compliance_items(id),
  sent_at         timestamptz not null default now(),
  -- Resend/email provider message ID for debugging
  provider_message_id varchar(200)
);

create index idx_email_logs_user on email_logs(user_id);
create index idx_email_logs_type on email_logs(email_type);


-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all user-facing tables
alter table user_profiles enable row level security;
alter table properties enable row level security;
alter table compliance_statuses enable row level security;
alter table documents enable row level security;

-- user_profiles: users can only read/write their own profile
create policy "user_profiles_select_own"
  on user_profiles for select
  using (auth.uid() = id);

create policy "user_profiles_update_own"
  on user_profiles for update
  using (auth.uid() = id);

-- properties: users can only CRUD their own properties
create policy "properties_select_own"
  on properties for select
  using (auth.uid() = user_id);

create policy "properties_insert_own"
  on properties for insert
  with check (auth.uid() = user_id);

create policy "properties_update_own"
  on properties for update
  using (auth.uid() = user_id);

create policy "properties_delete_own"
  on properties for delete
  using (auth.uid() = user_id);

-- compliance_statuses: access via property ownership
create policy "compliance_statuses_select"
  on compliance_statuses for select
  using (
    property_id in (
      select id from properties where user_id = auth.uid()
    )
  );

create policy "compliance_statuses_insert"
  on compliance_statuses for insert
  with check (
    property_id in (
      select id from properties where user_id = auth.uid()
    )
  );

create policy "compliance_statuses_update"
  on compliance_statuses for update
  using (
    property_id in (
      select id from properties where user_id = auth.uid()
    )
  );

-- documents: access via property ownership
create policy "documents_select_own"
  on documents for select
  using (auth.uid() = user_id);

create policy "documents_insert_own"
  on documents for insert
  with check (auth.uid() = user_id);

create policy "documents_delete_own"
  on documents for delete
  using (auth.uid() = user_id);

-- cities and compliance_items: public read, admin write only
alter table cities enable row level security;
alter table compliance_items enable row level security;
alter table regulatory_alerts enable row level security;

create policy "cities_public_read"
  on cities for select
  using (is_active = true);

create policy "compliance_items_public_read"
  on compliance_items for select
  using (is_active = true);

create policy "alerts_public_read"
  on regulatory_alerts for select
  using (true);

-- Admin-only write policies (uses user_profiles.role check)
create policy "cities_admin_all"
  on cities for all
  using (
    exists (
      select 1 from user_profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "compliance_items_admin_all"
  on compliance_items for all
  using (
    exists (
      select 1 from user_profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "alerts_admin_insert"
  on regulatory_alerts for insert
  with check (
    exists (
      select 1 from user_profiles
      where id = auth.uid() and role = 'admin'
    )
  );


-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Calculate next deadline date for a compliance item
-- given the current date
create or replace function calculate_next_deadline(
  p_deadline_type deadline_type,
  p_deadline_day  smallint,
  p_deadline_month smallint
) returns date as $$
declare
  v_today date := current_date;
  v_this_year int := extract(year from v_today);
  v_candidate date;
begin
  if p_deadline_type = 'one_time' then
    return null; -- handled manually by user
  end if;

  if p_deadline_type = 'annual' and p_deadline_day is not null and p_deadline_month is not null then
    v_candidate := make_date(v_this_year, p_deadline_month, p_deadline_day);
    if v_candidate <= v_today then
      v_candidate := make_date(v_this_year + 1, p_deadline_month, p_deadline_day);
    end if;
    return v_candidate;
  end if;

  if p_deadline_type = 'quarterly' then
    -- Return end of current quarter + 15 days (filing deadline)
    if extract(month from v_today) <= 3 then
      return make_date(v_this_year, 4, 15);
    elsif extract(month from v_today) <= 6 then
      return make_date(v_this_year, 7, 15);
    elsif extract(month from v_today) <= 9 then
      return make_date(v_this_year, 10, 15);
    else
      return make_date(v_this_year + 1, 1, 15);
    end if;
  end if;

  return null;
end;
$$ language plpgsql immutable;


-- Get compliance summary for a property
create or replace function get_property_compliance_summary(p_property_id uuid)
returns table(
  total_items     int,
  done_items      int,
  overdue_items   int,
  pending_items   int,
  compliance_pct  numeric
) as $$
begin
  return query
  select
    count(*)::int as total_items,
    count(*) filter (where cs.status = 'done')::int as done_items,
    count(*) filter (
      where cs.status != 'done'
        and cs.status != 'not_applicable'
        and cs.next_deadline_at < current_date
    )::int as overdue_items,
    count(*) filter (
      where cs.status = 'not_started' or cs.status = 'in_progress'
    )::int as pending_items,
    round(
      100.0 * count(*) filter (where cs.status = 'done') /
      nullif(count(*) filter (where cs.status != 'not_applicable'), 0),
      1
    ) as compliance_pct
  from compliance_statuses cs
  where cs.property_id = p_property_id;
end;
$$ language plpgsql security definer;


-- ============================================================
-- VIEWS
-- ============================================================

-- Upcoming deadlines view (used by dashboard and cron job)
create or replace view upcoming_deadlines as
select
  cs.id as compliance_status_id,
  cs.property_id,
  p.name as property_name,
  p.user_id,
  p.city_id,
  ci.id as compliance_item_id,
  ci.title as compliance_item_title,
  ci.category,
  ci.deadline_type,
  cs.next_deadline_at,
  cs.status,
  cs.reminded_90d,
  cs.reminded_30d,
  cs.reminded_7d,
  cs.reminded_1d,
  (cs.next_deadline_at - current_date) as days_until_deadline
from compliance_statuses cs
join properties p on cs.property_id = p.id
join compliance_items ci on cs.compliance_item_id = ci.id
where
  cs.status != 'done'
  and cs.status != 'not_applicable'
  and cs.next_deadline_at is not null
  and p.is_active = true
  and ci.is_active = true;

-- Overdue items view
create or replace view overdue_compliance as
select * from upcoming_deadlines
where days_until_deadline < 0;

-- Due within 30 days
create or replace view due_soon_compliance as
select * from upcoming_deadlines
where days_until_deadline between 0 and 30;


-- ============================================================
-- STORAGE BUCKETS (run in Supabase dashboard or via API)
-- ============================================================

-- Create storage bucket for user documents
-- This must be run via Supabase dashboard or management API:
--
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES (
--   'documents',
--   'documents',
--   false,  -- private bucket
--   10485760,  -- 10MB per file
--   ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
-- );
--
-- Storage path structure: documents/{user_id}/{property_id}/{filename}
-- RLS on storage objects: only file owner can read/write


-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

create index idx_properties_active on properties(is_active) where is_active = true;
create index idx_compliance_statuses_deadline_reminder
  on compliance_statuses(next_deadline_at, reminded_30d, reminded_7d, reminded_1d)
  where status not in ('done', 'not_applicable');

-- Full-text search on city pages
create index idx_cities_search on cities using gin(to_tsvector('english', name || ' ' || country));
create index idx_compliance_items_search
  on compliance_items using gin(to_tsvector('english', title || ' ' || coalesce(short_description, '')));
