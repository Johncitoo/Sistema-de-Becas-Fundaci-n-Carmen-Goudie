-- ===========================
--  Extensions
-- ===========================
CREATE EXTENSION IF NOT EXISTS citext   WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- ===========================
--  Enum types
-- ===========================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'application_status') THEN
    CREATE TYPE public.application_status AS ENUM (
      'DRAFT','SUBMITTED','IN_REVIEW','PRESELECTED','FINALIST','SELECTED',
      'NOT_SELECTED','NOT_ELIGIBLE','NEEDS_FIX','INTERVIEW_SCHEDULED','WITHDRAWN'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'call_status') THEN
    CREATE TYPE public.call_status AS ENUM ('DRAFT','OPEN','CLOSED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_status') THEN
    CREATE TYPE public.document_status AS ENUM ('PENDING','UPLOADING','UPLOADED','VALIDATED','INVALID','VALID');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_type') THEN
    CREATE TYPE public.document_type AS ENUM ('RSH','GRADES','IDENTITY','ENROLLMENT_CERT','OTHER');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'form_field_type') THEN
    CREATE TYPE public.form_field_type AS ENUM ('INPUT','NUMBER','TEXTAREA','SELECT','CHECKBOX','RADIO','FILE','IMAGE','DATE','REPEATABLE_GROUP');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'institution_type') THEN
    CREATE TYPE public.institution_type AS ENUM ('LICEO','COLEGIO','INSTITUTO','OTRO');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'interview_stage') THEN
    CREATE TYPE public.interview_stage AS ENUM ('PRESELECTION','FINAL');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE public.user_role AS ENUM ('ADMIN','REVIEWER','APPLICANT');
  END IF;
END$$;

-- ===========================
--  Functions
-- ===========================
CREATE OR REPLACE FUNCTION public.rut_calc_dv(rut_body bigint)
RETURNS text
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE s BIGINT := 0; m INT := 2; d INT; n BIGINT := rut_body; dv_val INT;
BEGIN
  IF rut_body IS NULL OR rut_body <= 0 THEN RETURN NULL; END IF;
  WHILE n > 0 LOOP
    d := (n % 10); s := s + d * m; m := m + 1; IF m > 7 THEN m := 2; END IF; n := n / 10;
  END LOOP;
  dv_val := 11 - (s % 11);
  IF dv_val = 11 THEN RETURN '0';
  ELSIF dv_val = 10 THEN RETURN 'K';
  ELSE RETURN dv_val::TEXT;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.applicants_validate_rut()
RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE dv_expected TEXT;
BEGIN
  IF NEW.rut_number IS NULL OR NEW.rut_dv IS NULL THEN
    RAISE EXCEPTION 'RUT number and DV are required';
  END IF;
  NEW.rut_dv := UPPER(TRIM(NEW.rut_dv));
  dv_expected := rut_calc_dv(NEW.rut_number);
  IF dv_expected IS NULL OR NEW.rut_dv <> dv_expected THEN
    RAISE EXCEPTION 'Invalid RUT: %-% (expected DV %)', NEW.rut_number, NEW.rut_dv, dv_expected;
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.audit_logs_block_mods()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP IN ('UPDATE','DELETE') THEN
    RAISE EXCEPTION 'audit_logs es inmutable (append-only)';
  END IF;
  RETURN NEW;
END $$;

-- ===========================
--  Tables
-- ===========================
CREATE TABLE IF NOT EXISTS public.applicants (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rut_number   bigint NOT NULL,
  rut_dv       char(1) NOT NULL,
  first_name   text NOT NULL,
  last_name    text NOT NULL,
  full_name    text GENERATED ALWAYS AS (btrim(first_name || ' ' || last_name)) STORED,
  birth_date   date,
  email        citext,
  phone        text,
  address      text,
  commune      text,
  region       text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_applicants_rut UNIQUE (rut_number, rut_dv)
);

CREATE TABLE IF NOT EXISTS public.calls (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  text NOT NULL,
  year                  integer NOT NULL,
  status                public.call_status NOT NULL DEFAULT 'DRAFT',
  total_seats           integer NOT NULL DEFAULT 0,
  min_per_institution   integer NOT NULL DEFAULT 0,
  dates                 jsonb,
  rules                 jsonb,
  form_published_at     timestamptz,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_calls_year_name UNIQUE (year, name),
  CONSTRAINT calls_total_seats_check CHECK (total_seats >= 0),
  CONSTRAINT calls_min_per_institution_check CHECK (min_per_institution >= 0)
);

CREATE TABLE IF NOT EXISTS public.form_sections (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id   uuid NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  title     text NOT NULL,
  "order"   integer NOT NULL DEFAULT 0,
  visible   boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.form_fields (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id           uuid NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  section_id        uuid REFERENCES public.form_sections(id) ON DELETE SET NULL,
  name              text NOT NULL,
  label             text NOT NULL,
  type              public.form_field_type NOT NULL,
  required          boolean NOT NULL DEFAULT false,
  options           jsonb,
  validation        jsonb,
  help_text         text,
  show_if           jsonb,
  "order"           integer NOT NULL DEFAULT 0,
  active            boolean NOT NULL DEFAULT true,
  visibility        text NOT NULL DEFAULT 'PUBLIC',
  editable_by_roles jsonb,
  CONSTRAINT uq_form_field_name UNIQUE (call_id, name),
  CONSTRAINT form_fields_visibility_check CHECK (visibility IN ('PUBLIC','INTERNAL'))
);

CREATE TABLE IF NOT EXISTS public.institutions (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name      text NOT NULL,
  code      text,
  commune   text,
  province  text,
  region    text,
  type      public.institution_type NOT NULL DEFAULT 'LICEO',
  active    boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT institutions_name_key UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS public.applications (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_id    uuid NOT NULL REFERENCES public.applicants(id) ON DELETE CASCADE,
  call_id         uuid NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  institution_id  uuid REFERENCES public.institutions(id) ON DELETE SET NULL,
  status          public.application_status NOT NULL DEFAULT 'DRAFT',
  submitted_at    timestamptz,
  is_eligible     boolean,
  eligibility_reasons jsonb,
  academic        jsonb,
  household       jsonb,
  participation   jsonb,
  texts           jsonb,
  builder_extra   jsonb,
  total_score     numeric(8,3),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_application_per_call UNIQUE (applicant_id, call_id)
);

CREATE TABLE IF NOT EXISTS public.application_status_history (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  from_status    public.application_status,
  to_status      public.application_status NOT NULL,
  actor_user_id  uuid REFERENCES public.users(id) ON DELETE SET NULL,
  reason         text,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.application_notes (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  author_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  section_id     uuid REFERENCES public.form_sections(id) ON DELETE SET NULL,
  visibility     text NOT NULL DEFAULT 'INTERNAL',
  body           text NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT application_notes_visibility_check CHECK (visibility IN ('INTERNAL','APPLICANT'))
);

-- Legacy/simple upload table (puede convivir con documents versionado)
CREATE TABLE IF NOT EXISTS public.application_documents (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  type          text NOT NULL,
  file_name     text NOT NULL,
  mime_type     text NOT NULL,
  size_kb       integer NOT NULL,
  storage_key   text,
  status        text NOT NULL DEFAULT 'PENDING',
  created_at    timestamptz NOT NULL DEFAULT now(),
  uploaded_at   timestamptz
);

-- Nuevo repositorio versionado de documentos
CREATE TABLE IF NOT EXISTS public.documents (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id    uuid NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  type              public.document_type NOT NULL,
  filename          text NOT NULL,
  storage_key       text NOT NULL,
  content_type      text,
  size_bytes        bigint,
  checksum          text,
  validation_status public.document_status NOT NULL DEFAULT 'PENDING',
  invalid_reason    text,
  validated_by      uuid REFERENCES public.users(id) ON DELETE SET NULL,
  validated_at      timestamptz,
  version           integer NOT NULL DEFAULT 1,
  is_current        boolean NOT NULL DEFAULT true,
  form_field_id     uuid REFERENCES public.form_fields(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.criteria (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id     uuid NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  key         text NOT NULL,
  name        text NOT NULL,
  weight_pct  integer NOT NULL,
  config      jsonb,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_criteria_key UNIQUE (call_id, key),
  CONSTRAINT criteria_weight_pct_check CHECK (weight_pct >= 0 AND weight_pct <= 100)
);

CREATE TABLE IF NOT EXISTS public.scores (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  criterion_id   uuid NOT NULL REFERENCES public.criteria(id) ON DELETE CASCADE,
  raw_value      numeric,
  normalized     numeric,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_score UNIQUE (application_id, criterion_id)
);

CREATE TABLE IF NOT EXISTS public.scoring_runs (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id          uuid NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  criteria_snapshot jsonb NOT NULL,
  tiebreakers      jsonb,
  seed             text,
  executed_by      uuid REFERENCES public.users(id) ON DELETE SET NULL,
  executed_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ranking_results (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id       uuid NOT NULL REFERENCES public.scoring_runs(id) ON DELETE CASCADE,
  call_id      uuid NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  application_id uuid NOT NULL UNIQUE REFERENCES public.applications(id) ON DELETE CASCADE,
  "position"   integer NOT NULL,
  selected     boolean NOT NULL DEFAULT false,
  by_min_institution_rule boolean NOT NULL DEFAULT false,
  exclusion_reason text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_rank_pos_per_call UNIQUE (call_id, "position")
);

CREATE TABLE IF NOT EXISTS public.interviews (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  uuid NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  stage           public.interview_stage NOT NULL,
  interview_date  timestamptz,
  rubric          jsonb,
  recommendation  text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.interview_participants (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  interview_id uuid NOT NULL REFERENCES public.interviews(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE SET NULL,
  role        text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.invites (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id             uuid NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  institution_id      uuid REFERENCES public.institutions(id) ON DELETE SET NULL,
  code_hash           text NOT NULL UNIQUE,
  expires_at          timestamptz,
  used_by_applicant   uuid REFERENCES public.applicants(id) ON DELETE SET NULL,
  used_at             timestamptz,
  meta                jsonb,
  created_by_user_id  uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT invites_used_consistency_chk CHECK (
    (used_by_applicant IS NULL AND used_at IS NULL)
    OR (used_by_applicant IS NOT NULL AND used_at IS NOT NULL)
  )
);

CREATE TABLE IF NOT EXISTS public.email_templates (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key         text NOT NULL UNIQUE,
  name        text NOT NULL,
  subject_tpl text NOT NULL,
  body_tpl    text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.email_batches (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id         uuid REFERENCES public.calls(id) ON DELETE CASCADE,
  template_key    text NOT NULL,
  filter_snapshot jsonb NOT NULL,
  status          text NOT NULL DEFAULT 'DRAFT',
  scheduled_at    timestamptz,
  created_by      uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT email_batches_status_check CHECK (status IN ('DRAFT','QUEUED','RUNNING','DONE','FAILED'))
);

CREATE TABLE IF NOT EXISTS public.email_recipients (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id     uuid NOT NULL REFERENCES public.email_batches(id) ON DELETE CASCADE,
  to_address   citext NOT NULL,
  applicant_id uuid REFERENCES public.applicants(id) ON DELETE SET NULL,
  status       text NOT NULL DEFAULT 'QUEUED',
  error_message text,
  sent_at      timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT email_recipients_status_check CHECK (status IN ('QUEUED','SENT','FAILED'))
);

CREATE TABLE IF NOT EXISTS public.email_logs (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key   text REFERENCES public.email_templates(key) ON DELETE SET NULL,
  batch_id       uuid REFERENCES public.email_batches(id) ON DELETE SET NULL,
  to_address     citext NOT NULL,
  applicant_id   uuid REFERENCES public.applicants(id) ON DELETE SET NULL,
  institution_id uuid REFERENCES public.institutions(id) ON DELETE SET NULL,
  payload        jsonb,
  status         text NOT NULL,
  error_message  text,
  sent_at        timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT email_logs_status_check CHECK (status IN ('QUEUED','SENT','FAILED'))
);

CREATE TABLE IF NOT EXISTS public.form_responses (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  field_id       uuid NOT NULL REFERENCES public.form_fields(id) ON DELETE CASCADE,
  value          jsonb NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_form_response UNIQUE (application_id, field_id)
);

CREATE TABLE IF NOT EXISTS public.call_document_requirements (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id      uuid NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  type         public.document_type NOT NULL,
  required     boolean NOT NULL DEFAULT true,
  accept       text,
  max_size_mb  integer,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_call_doc_req UNIQUE (call_id, type)
);

CREATE TABLE IF NOT EXISTS public.call_institution_policies (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id         uuid NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  institution_id  uuid NOT NULL REFERENCES public.institutions(id) ON DELETE CASCADE,
  min_interviews  integer NOT NULL DEFAULT 2,
  min_selected    integer,
  top_pct         integer,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_call_inst_policy UNIQUE (call_id, institution_id)
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  action        text NOT NULL,
  entity        text NOT NULL,
  entity_id     uuid,
  meta          jsonb,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.password_resets (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token_hash          text NOT NULL UNIQUE,
  expires_at          timestamptz NOT NULL,
  used_at             timestamptz,
  requested_ip        inet,
  requested_user_agent text,
  consumed_ip         inet,
  consumed_user_agent text,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.password_set_tokens (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token_hash         text NOT NULL UNIQUE,
  expires_at         timestamptz NOT NULL,
  used_at            timestamptz,
  issued_ip          inet,
  issued_user_agent  text,
  consumed_ip        inet,
  consumed_user_agent text,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_sessions (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  refresh_token_hash  text NOT NULL,
  token_family_id     uuid NOT NULL DEFAULT gen_random_uuid(),
  rotated_from_session_id uuid REFERENCES public.user_sessions(id) ON DELETE SET NULL,
  user_agent          text,
  ip                  inet,
  expires_at          timestamptz NOT NULL,
  revoked_at          timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.users (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email               citext NOT NULL UNIQUE,
  password_hash       text NOT NULL,
  password_updated_at timestamptz NOT NULL DEFAULT now(),
  full_name           text NOT NULL,
  role                public.user_role NOT NULL,
  is_active           boolean NOT NULL DEFAULT true,
  applicant_id        uuid REFERENCES public.applicants(id) ON DELETE SET NULL,
  last_login_at       timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

-- ===========================
--  Indexes
-- ===========================
CREATE INDEX IF NOT EXISTS idx_applicants_email           ON public.applicants USING btree (email);
CREATE INDEX IF NOT EXISTS idx_calls_year                 ON public.calls      USING btree (year);
CREATE INDEX IF NOT EXISTS idx_form_sections_call         ON public.form_sections USING btree (call_id);
CREATE INDEX IF NOT EXISTS idx_form_fields_call           ON public.form_fields USING btree (call_id);
CREATE INDEX IF NOT EXISTS gin_form_fields_show_if        ON public.form_fields USING gin (show_if);

CREATE INDEX IF NOT EXISTS idx_applications_call_status   ON public.applications USING btree (call_id, status);
CREATE INDEX IF NOT EXISTS idx_applications_inst          ON public.applications USING btree (institution_id);
CREATE INDEX IF NOT EXISTS gin_applications_academic      ON public.applications USING gin (academic);
CREATE INDEX IF NOT EXISTS gin_applications_household     ON public.applications USING gin (household);
CREATE INDEX IF NOT EXISTS gin_applications_participation ON public.applications USING gin (participation);
CREATE INDEX IF NOT EXISTS gin_applications_builder       ON public.applications USING gin (builder_extra);

CREATE INDEX IF NOT EXISTS idx_app_status_hist_app        ON public.application_status_history USING btree (application_id);
CREATE INDEX IF NOT EXISTS idx_app_notes_app              ON public.application_notes USING btree (application_id);

CREATE INDEX IF NOT EXISTS idx_docs_app                   ON public.documents USING btree (application_id);
CREATE INDEX IF NOT EXISTS idx_docs_type                  ON public.documents USING btree (type);
CREATE INDEX IF NOT EXISTS idx_documents_app_created_at   ON public.documents USING btree (application_id, created_at);
CREATE INDEX IF NOT EXISTS idx_documents_app_current      ON public.documents USING btree (application_id, filename) WHERE is_current;
CREATE UNIQUE INDEX IF NOT EXISTS uq_doc_current          ON public.documents USING btree (application_id, type) WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_appdocs_application        ON public.application_documents USING btree (application_id);

CREATE INDEX IF NOT EXISTS idx_form_responses_value       ON public.form_responses USING gin (value);

CREATE INDEX IF NOT EXISTS idx_int_part_interview         ON public.interview_participants USING btree (interview_id);
CREATE INDEX IF NOT EXISTS idx_interviews_app             ON public.interviews USING btree (application_id);

CREATE INDEX IF NOT EXISTS idx_invites_call               ON public.invites USING btree (call_id);
CREATE INDEX IF NOT EXISTS idx_invites_expires            ON public.invites USING btree (expires_at);
CREATE INDEX IF NOT EXISTS idx_invites_active             ON public.invites USING btree (code_hash) WHERE used_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_email_logs_status          ON public.email_logs USING btree (status);
CREATE INDEX IF NOT EXISTS idx_email_logs_to              ON public.email_logs USING btree (to_address);

CREATE INDEX IF NOT EXISTS idx_scores_app                 ON public.scores USING btree (application_id);
CREATE INDEX IF NOT EXISTS idx_scoring_runs_call          ON public.scoring_runs USING btree (call_id);

CREATE INDEX IF NOT EXISTS idx_rank_call                  ON public.ranking_results USING btree (call_id);

CREATE INDEX IF NOT EXISTS idx_sessions_user              ON public.user_sessions USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_active            ON public.user_sessions USING btree (user_id) WHERE revoked_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sessions_expires           ON public.user_sessions USING btree (expires_at);
CREATE INDEX IF NOT EXISTS idx_sessions_family            ON public.user_sessions USING btree (token_family_id);
CREATE INDEX IF NOT EXISTS idx_sessions_revoked           ON public.user_sessions USING btree (revoked_at);

CREATE INDEX IF NOT EXISTS idx_users_role                 ON public.users USING btree (role);
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_applicant      ON public.users USING btree (applicant_id) WHERE applicant_id IS NOT NULL;

-- ===========================
--  Triggers
-- ===========================
-- block modifications to audit_logs (append-only)
DROP TRIGGER IF EXISTS trg_audit_block_mods ON public.audit_logs;
CREATE TRIGGER trg_audit_block_mods
BEFORE UPDATE OR DELETE ON public.audit_logs
FOR EACH ROW EXECUTE FUNCTION public.audit_logs_block_mods();

-- updated_at maintenance
DO $$
BEGIN
  PERFORM 1;
  DROP TRIGGER IF EXISTS trg_applicants_updated ON public.applicants;
  CREATE TRIGGER trg_applicants_updated BEFORE UPDATE ON public.applicants FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_applications_updated ON public.applications;
  CREATE TRIGGER trg_applications_updated BEFORE UPDATE ON public.applications FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_call_doc_req_updated ON public.call_document_requirements;
  CREATE TRIGGER trg_call_doc_req_updated BEFORE UPDATE ON public.call_document_requirements FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_call_inst_policies_updated ON public.call_institution_policies;
  CREATE TRIGGER trg_call_inst_policies_updated BEFORE UPDATE ON public.call_institution_policies FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_calls_updated ON public.calls;
  CREATE TRIGGER trg_calls_updated BEFORE UPDATE ON public.calls FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_criteria_updated ON public.criteria;
  CREATE TRIGGER trg_criteria_updated BEFORE UPDATE ON public.criteria FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_documents_updated ON public.documents;
  CREATE TRIGGER trg_documents_updated BEFORE UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_form_responses_updated ON public.form_responses;
  CREATE TRIGGER trg_form_responses_updated BEFORE UPDATE ON public.form_responses FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_institutions_updated ON public.institutions;
  CREATE TRIGGER trg_institutions_updated BEFORE UPDATE ON public.institutions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_interviews_updated ON public.interviews;
  CREATE TRIGGER trg_interviews_updated BEFORE UPDATE ON public.interviews FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_ranking_results_updated ON public.ranking_results;
  CREATE TRIGGER trg_ranking_results_updated BEFORE UPDATE ON public.ranking_results FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_scores_updated ON public.scores;
  CREATE TRIGGER trg_scores_updated BEFORE UPDATE ON public.scores FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

  DROP TRIGGER IF EXISTS trg_users_updated ON public.users;
  CREATE TRIGGER trg_users_updated BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
END$$;

-- RUT validator
DROP TRIGGER IF EXISTS trg_applicants_rut_validate ON public.applicants;
CREATE TRIGGER trg_applicants_rut_validate
BEFORE INSERT OR UPDATE ON public.applicants
FOR EACH ROW EXECUTE FUNCTION public.applicants_validate_rut();

-- ===========================
--  RLS policies (DEV-SAFE: NO se habilita RLS)
--  Cuando quieras activar RLS:
--    ALTER TABLE public.<tabla> ENABLE ROW LEVEL SECURITY;
-- ===========================
-- applicants
DROP POLICY IF EXISTS pol_applicants_insert ON public.applicants;
CREATE POLICY pol_applicants_insert ON public.applicants
FOR INSERT WITH CHECK (COALESCE(current_setting('app.user_role', true), '') = 'ADMIN');

DROP POLICY IF EXISTS pol_applicants_select ON public.applicants;
CREATE POLICY pol_applicants_select ON public.applicants
FOR SELECT USING (
  COALESCE(current_setting('app.user_role', true), '') IN ('ADMIN','REVIEWER')
  OR id = NULLIF(current_setting('app.applicant_id', true), '')::uuid
);

DROP POLICY IF EXISTS pol_applicants_update ON public.applicants;
CREATE POLICY pol_applicants_update ON public.applicants
FOR UPDATE USING (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR id = NULLIF(current_setting('app.applicant_id', true), '')::uuid
)
WITH CHECK (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR id = NULLIF(current_setting('app.applicant_id', true), '')::uuid
);

-- applications
DROP POLICY IF EXISTS pol_apps_insert ON public.applications;
CREATE POLICY pol_apps_insert ON public.applications
FOR INSERT WITH CHECK (COALESCE(current_setting('app.user_role', true), '') = 'ADMIN');

DROP POLICY IF EXISTS pol_apps_select ON public.applications;
CREATE POLICY pol_apps_select ON public.applications
FOR SELECT USING (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR applicant_id = NULLIF(current_setting('app.applicant_id', true), '')::uuid
  OR (
    COALESCE(current_setting('app.user_role', true), '') = 'REVIEWER'
    AND EXISTS (
      SELECT 1 FROM public.review_assignments ra
      WHERE ra.application_id = applications.id
        AND ra.reviewer_user_id = NULLIF(current_setting('app.user_id', true), '')::uuid
        AND ra.unassigned_at IS NULL
    )
  )
);

DROP POLICY IF EXISTS pol_apps_update ON public.applications;
CREATE POLICY pol_apps_update ON public.applications
FOR UPDATE USING (
  COALESCE(current_setting('app.user_role', true), '') IN ('ADMIN','REVIEWER')
  OR applicant_id = NULLIF(current_setting('app.applicant_id', true), '')::uuid
)
WITH CHECK (
  COALESCE(current_setting('app.user_role', true), '') IN ('ADMIN','REVIEWER')
  OR applicant_id = NULLIF(current_setting('app.applicant_id', true), '')::uuid
);

-- documents
DROP POLICY IF EXISTS pol_docs_insert ON public.documents;
CREATE POLICY pol_docs_insert ON public.documents
FOR INSERT WITH CHECK (
  COALESCE(current_setting('app.user_role', true), '') IN ('ADMIN','REVIEWER')
  OR application_id IN (SELECT id FROM public.applications a
                        WHERE a.applicant_id = NULLIF(current_setting('app.applicant_id', true), '')::uuid)
);

DROP POLICY IF EXISTS pol_docs_select ON public.documents;
CREATE POLICY pol_docs_select ON public.documents
FOR SELECT USING (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = documents.application_id
        AND (
          a.applicant_id = NULLIF(current_setting('app.applicant_id', true), '')::uuid
          OR (
            COALESCE(current_setting('app.user_role', true), '') = 'REVIEWER'
            AND EXISTS (
              SELECT 1 FROM public.review_assignments ra
              WHERE ra.application_id = a.id
                AND ra.reviewer_user_id = NULLIF(current_setting('app.user_id', true), '')::uuid
                AND ra.unassigned_at IS NULL
            )
          )
        )
  )
);

DROP POLICY IF EXISTS pol_docs_update ON public.documents;
CREATE POLICY pol_docs_update ON public.documents
FOR UPDATE USING (COALESCE(current_setting('app.user_role', true), '') IN ('ADMIN','REVIEWER'))
WITH CHECK   (COALESCE(current_setting('app.user_role', true), '') IN ('ADMIN','REVIEWER'));

-- application_notes
DROP POLICY IF EXISTS pol_notes_select ON public.application_notes;
CREATE POLICY pol_notes_select ON public.application_notes
FOR SELECT USING (
  COALESCE(current_setting('app.user_role', true), '') IN ('ADMIN','REVIEWER')
  OR (
    EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = application_notes.application_id
        AND a.applicant_id = NULLIF(current_setting('app.applicant_id', true), '')::uuid
    )
    AND visibility = 'APPLICANT'
  )
);

DROP POLICY IF EXISTS pol_notes_write ON public.application_notes;
CREATE POLICY pol_notes_write ON public.application_notes
USING (COALESCE(current_setting('app.user_role', true), '') IN ('ADMIN','REVIEWER'))
WITH CHECK (COALESCE(current_setting('app.user_role', true), '') IN ('ADMIN','REVIEWER'));

-- password_resets
DROP POLICY IF EXISTS pol_pwresets_all ON public.password_resets;
CREATE POLICY pol_pwresets_all ON public.password_resets
USING (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR user_id = NULLIF(current_setting('app.user_id', true), '')::uuid
)
WITH CHECK (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR user_id = NULLIF(current_setting('app.user_id', true), '')::uuid
);

-- user_sessions
DROP POLICY IF EXISTS pol_sessions_all ON public.user_sessions;
CREATE POLICY pol_sessions_all ON public.user_sessions
USING (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR user_id = NULLIF(current_setting('app.user_id', true), '')::uuid
)
WITH CHECK (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR user_id = NULLIF(current_setting('app.user_id', true), '')::uuid
);

-- users
DROP POLICY IF EXISTS pol_users_insert ON public.users;
CREATE POLICY pol_users_insert ON public.users
FOR INSERT WITH CHECK (COALESCE(current_setting('app.user_role', true), '') = 'ADMIN');

DROP POLICY IF EXISTS pol_users_select ON public.users;
CREATE POLICY pol_users_select ON public.users
FOR SELECT USING (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR id = NULLIF(current_setting('app.user_id', true), '')::uuid
);

DROP POLICY IF EXISTS pol_users_update ON public.users;
CREATE POLICY pol_users_update ON public.users
FOR UPDATE USING (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR id = NULLIF(current_setting('app.user_id', true), '')::uuid
)
WITH CHECK (
  COALESCE(current_setting('app.user_role', true), '') = 'ADMIN'
  OR id = NULLIF(current_setting('app.user_id', true), '')::uuid
);
