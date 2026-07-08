-- へぇの種 MVP PostgreSQL schema
-- Generated: 2026-07-07

create extension if not exists "pgcrypto";

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists cards (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  hook text not null,
  short_body text not null,
  long_body text not null,
  category_id uuid not null references categories(id),
  confidence_level text not null check (confidence_level in ('A','B','C','D')),
  status text not null check (status in ('draft','review','approved','published','archived')) default 'draft',
  publish_date date,
  editor_note text,
  ai_prompt_version text,
  ai_model text,
  created_by uuid,
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists card_sources (
  id uuid primary key default gen_random_uuid(),
  card_id uuid not null references cards(id) on delete cascade,
  title text not null,
  url text not null,
  source_type text not null check (source_type in ('official','academic','wiki','media','book','other')),
  retrieved_at date not null,
  license_note text,
  quote_used boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists quizzes (
  id uuid primary key default gen_random_uuid(),
  card_id uuid not null references cards(id) on delete cascade,
  question text not null,
  choices jsonb not null,
  answer_index int not null,
  explanation text not null,
  created_at timestamptz not null default now()
);

create table if not exists card_relations (
  from_card_id uuid not null references cards(id) on delete cascade,
  to_card_id uuid not null references cards(id) on delete cascade,
  relation_type text not null,
  reason text not null,
  created_at timestamptz not null default now(),
  primary key (from_card_id, to_card_id)
);

create table if not exists user_profiles (
  user_id uuid primary key,
  display_name text,
  preferred_categories text[] not null default '{}',
  premium_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists saved_cards (
  user_id uuid not null,
  card_id uuid not null references cards(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, card_id)
);

create table if not exists user_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  anonymous_id text,
  event_type text not null check (event_type in ('card_view','card_read','save','unsave','quiz_answer','share','source_click','deck_view')),
  card_id uuid references cards(id) on delete set null,
  metadata jsonb not null default '{}',
  occurred_at timestamptz not null default now()
);

create table if not exists daily_decks (
  id uuid primary key default gen_random_uuid(),
  deck_date date not null,
  segment_key text not null default 'default',
  card_ids uuid[] not null,
  created_at timestamptz not null default now(),
  unique (deck_date, segment_key)
);

create table if not exists content_jobs (
  id uuid primary key default gen_random_uuid(),
  job_type text not null,
  status text not null check (status in ('queued','running','succeeded','failed')) default 'queued',
  input jsonb not null default '{}',
  output jsonb not null default '{}',
  error text,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_cards_status_publish_date on cards(status, publish_date);
create index if not exists idx_user_events_user_time on user_events(user_id, occurred_at desc);
create index if not exists idx_saved_cards_user on saved_cards(user_id);
