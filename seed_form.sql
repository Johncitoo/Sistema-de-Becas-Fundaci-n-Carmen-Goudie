-- ==========================================================
-- Fundación Carmen Goudie — Backend DB (PostgreSQL 14+)
-- Esquema + Seeds mínimos (ADMIN/REVIEWER/APPLICANT/Convocatoria)
-- Seguro por defecto: hashes Argon2id (PHC), códigos/tokens como hash
-- RLS: políticas escritas pero NO habilitadas (ver notas al final)
-- ==========================================================

BEGIN;

-- =============================
-- Extensions
-- =============================
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid(), gen_random_bytes()
-- (Opcional si está disponible en Railway) CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- =============================
-- Utility: updated_at trigger
-- =============================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END $$ LANGUAGE plpgsql;

-- =============================
-- RUT validator (Chile)
-- =============================
CREATE OR REPLACE FUNCTION rut_calc_dv(rut_body BIGINT)
RETURNS TEXT AS $$
DECLARE
  s BIGINT := 0; m INT := 2; d INT; n BIGINT := rut_body; dv_val INT;
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
END $$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION applicants_validate_rut()
RETURNS TRIGGER AS $$
DECLARE dv_expected TEXT;
BEGIN
  IF NEW.rut_number IS NULL OR NEW.rut_dv IS NULL THEN
    RAISE EXCEPTION 'RUT number and DV are required';
  END IF;
  NEW.rut_dv := UPPER(TRIM(NEW.rut_dv));
  dv_expected := rut_calc_dv(NEW.rut_number);
  IF dv_expected IS NULL OR NEW.rut_dv <> dv_expected THEN
    RAISE EXCEPTION 'Invalid RUT: %-% (expected DV %)',
      NEW.rut_number, NEW.rut_dv, dv_expected;
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;

-- =============================
-- Types (ENUM)
-- =============================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='user_role')
  THEN CREATE TYPE user_role AS ENUM ('ADMIN','REVIEWER','APPLICANT'); END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='institution_type')
  THEN CREATE TYPE institution_type AS ENUM ('LICEO','COLEGIO','INSTITUTO','OTRO'); END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='call_status')
  THEN CREATE TYPE call_status AS ENUM ('DRAFT','OPEN','CLOSED'); END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='application_status')
  THEN CREATE TYPE application_status AS ENUM
    ('DRAFT','SUBMITTED','IN_REVIEW','PRESELECTED','FINALIST','SELECTED','NOT_SELECTED','NOT_ELIGIBLE'); END IF;

  -- Añadir estados extendidos si faltan
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid=e.enumtypid
    WHERE t.typname='application_status' AND e.enumlabel='NEEDS_FIX'
  ) THEN ALTER TYPE application_status ADD VALUE 'NEEDS_FIX'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid=e.enumtypid
    WHERE t.typname='application_status' AND e.enumlabel='INTERVIEW_SCHEDULED'
  ) THEN ALTER TYPE application_status ADD VALUE 'INTERVIEW_SCHEDULED'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid=e.enumtypid
    WHERE t.typname='application_status' AND e.enumlabel='WITHDRAWN'
  ) THEN ALTER TYPE application_status ADD VALUE 'WITHDRAWN'; END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='document_type')
  THEN CREATE TYPE document_type AS ENUM ('RSH','GRADES','IDENTITY','ENROLLMENT_CERT','OTHER'); END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='document_status')
  THEN CREATE TYPE document_status AS ENUM ('PENDING','UPLOADING','UPLOADED','VALIDATED','INVALID'); END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='interview_stage')
  THEN CREATE TYPE interview_stage AS ENUM ('PRESELECTION','FINAL'); END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='form_field_type')
  THEN CREATE TYPE form_field_type AS ENUM
    ('INPUT','NUMBER','TEXTAREA','SELECT','CHECKBOX','RADIO','FILE','IMAGE','DATE','REPEATABLE_GROUP'); END IF;
END $$;

-- =============================
-- Core catalogs
-- =============================
CREATE TABLE IF NOT EXISTS institutions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL UNIQUE,
  code        TEXT,
  commune     TEXT,
  province    TEXT,
  region      TEXT,
  type        institution_type NOT NULL DEFAULT 'LICEO',
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TRIGGER trg_institutions_updated
BEFORE UPDATE ON institutions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS calls (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL,
  year                  INT  NOT NULL,
  status                call_status NOT NULL DEFAULT 'DRAFT',
  total_seats           INT  NOT NULL DEFAULT 0 CHECK (total_seats >= 0),
  min_per_institution   INT  NOT NULL DEFAULT 0 CHECK (min_per_institution >= 0),
  dates                 JSONB,
  rules                 JSONB,
  form_published_at     TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_calls_year_name UNIQUE (year, name)
);
CREATE INDEX IF NOT EXISTS idx_calls_year ON calls(year);
CREATE TRIGGER trg_calls_updated
BEFORE UPDATE ON calls FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================
-- Applicants / Users / Sessions / Resets / Invites
-- =============================
CREATE TABLE IF NOT EXISTS applicants (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rut_number   BIGINT NOT NULL,
  rut_dv       CHAR(1)  NOT NULL,
  first_name   TEXT    NOT NULL,
  last_name    TEXT    NOT NULL,
  full_name    TEXT    GENERATED ALWAYS AS (btrim(first_name || ' ' || last_name)) STORED,
  birth_date   DATE,
  email        CITEXT,
  phone        TEXT,
  address      TEXT,
  commune      TEXT,
  region       TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_applicants_rut UNIQUE (rut_number, rut_dv)
);
CREATE INDEX IF NOT EXISTS idx_applicants_email ON applicants(email);
CREATE TRIGGER trg_applicants_updated
BEFORE UPDATE ON applicants FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_applicants_rut_validate
BEFORE INSERT OR UPDATE ON applicants FOR EACH ROW EXECUTE FUNCTION applicants_validate_rut();

CREATE TABLE IF NOT EXISTS users (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email               CITEXT NOT NULL UNIQUE,
  password_hash       TEXT   NOT NULL,          -- PHC Argon2id
  password_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  full_name           TEXT   NOT NULL,
  role                user_role NOT NULL,
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  applicant_id        UUID NULL REFERENCES applicants(id) ON DELETE SET NULL,
  last_login_at       TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_applicant
  ON users(applicant_id) WHERE applicant_id IS NOT NULL;
CREATE TRIGGER trg_users_updated
BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS user_sessions (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token_hash      TEXT NOT NULL,
  token_family_id         UUID NOT NULL DEFAULT gen_random_uuid(),
  rotated_from_session_id UUID NULL REFERENCES user_sessions(id) ON DELETE SET NULL,
  user_agent              TEXT,
  ip                      INET,
  expires_at              TIMESTAMPTZ NOT NULL,
  revoked_at              TIMESTAMPTZ,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sessions_user     ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires  ON user_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_sessions_revoked  ON user_sessions(revoked_at);
CREATE INDEX IF NOT EXISTS idx_sessions_family   ON user_sessions(token_family_id);
CREATE INDEX IF NOT EXISTS idx_sessions_active   ON user_sessions(user_id) WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS password_resets (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash            TEXT NOT NULL UNIQUE,
  expires_at            TIMESTAMPTZ NOT NULL,
  used_at               TIMESTAMPTZ,
  requested_ip          INET,
  requested_user_agent  TEXT,
  consumed_ip           INET,
  consumed_user_agent   TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_pwresets_user    ON password_resets(user_id);
CREATE INDEX IF NOT EXISTS idx_pwresets_expires ON password_resets(expires_at);

CREATE TABLE IF NOT EXISTS password_set_tokens (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash           TEXT NOT NULL UNIQUE,      -- HMAC(token, PEPPER) o hash simple según backend
  expires_at           TIMESTAMPTZ NOT NULL,
  used_at              TIMESTAMPTZ,
  issued_ip            INET,
  issued_user_agent    TEXT,
  consumed_ip          INET,
  consumed_user_agent  TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_pst_user ON password_set_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_pst_expires ON password_set_tokens(expires_at);

CREATE TABLE IF NOT EXISTS invites (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id             UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  institution_id      UUID NULL REFERENCES institutions(id) ON DELETE SET NULL,
  code_hash           TEXT NOT NULL UNIQUE,  -- HMAC(code, PEPPER) o hash simple
  expires_at          TIMESTAMPTZ,
  used_by_applicant   UUID REFERENCES applicants(id) ON DELETE SET NULL,
  used_at             TIMESTAMPTZ,
  meta                JSONB,
  created_by_user_id  UUID NULL REFERENCES users(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT invites_used_consistency_chk
    CHECK ( (used_by_applicant IS NULL AND used_at IS NULL)
         OR (used_by_applicant IS NOT NULL AND used_at IS NOT NULL) )
);
CREATE INDEX IF NOT EXISTS idx_invites_active  ON invites (code_hash) WHERE used_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_invites_expires ON invites (expires_at);
CREATE INDEX IF NOT EXISTS idx_invites_call    ON invites (call_id);

-- =============================
-- Applications (+ history)
-- =============================
CREATE TABLE IF NOT EXISTS applications (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_id     UUID NOT NULL REFERENCES applicants(id) ON DELETE CASCADE,
  call_id          UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  institution_id   UUID NULL REFERENCES institutions(id) ON DELETE SET NULL,
  status           application_status NOT NULL DEFAULT 'DRAFT',
  submitted_at     TIMESTAMPTZ,
  is_eligible      BOOLEAN,
  eligibility_reasons JSONB,
  academic         JSONB,
  household        JSONB,
  participation    JSONB,
  texts            JSONB,
  builder_extra    JSONB,
  total_score      NUMERIC(8,3),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_application_per_call UNIQUE (applicant_id, call_id)
);
CREATE INDEX IF NOT EXISTS idx_applications_call_status ON applications(call_id, status);
CREATE INDEX IF NOT EXISTS idx_applications_inst        ON applications(institution_id);
CREATE INDEX IF NOT EXISTS gin_applications_academic      ON applications USING GIN (academic);
CREATE INDEX IF NOT EXISTS gin_applications_household     ON applications USING GIN (household);
CREATE INDEX IF NOT EXISTS gin_applications_participation ON applications USING GIN (participation);
CREATE INDEX IF NOT EXISTS gin_applications_builder       ON applications USING GIN (builder_extra);
CREATE TRIGGER trg_applications_updated
BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS application_status_history (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  from_status    application_status,
  to_status      application_status NOT NULL,
  actor_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  reason         TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_app_status_hist_app ON application_status_history(application_id);

-- =============================
-- Form Builder
-- =============================
CREATE TABLE IF NOT EXISTS form_sections (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id    UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  "order"    INT  NOT NULL DEFAULT 0,
  visible    BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS idx_form_sections_call ON form_sections(call_id);

CREATE TABLE IF NOT EXISTS form_fields (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id     UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  section_id  UUID NULL REFERENCES form_sections(id) ON DELETE SET NULL,
  name        TEXT NOT NULL,
  label       TEXT NOT NULL,
  type        form_field_type NOT NULL,
  required    BOOLEAN NOT NULL DEFAULT FALSE,
  options     JSONB,
  validation  JSONB,
  help_text   TEXT,
  show_if     JSONB,
  "order"     INT  NOT NULL DEFAULT 0,
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  visibility  TEXT NOT NULL DEFAULT 'PUBLIC' CHECK (visibility IN ('PUBLIC','INTERNAL')),
  editable_by_roles JSONB
);
CREATE INDEX IF NOT EXISTS idx_form_fields_call ON form_fields(call_id);
CREATE INDEX IF NOT EXISTS gin_form_fields_show_if ON form_fields USING GIN (show_if);

CREATE TABLE IF NOT EXISTS form_responses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  field_id        UUID NOT NULL REFERENCES form_fields(id) ON DELETE CASCADE,
  value           JSONB NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_form_response UNIQUE (application_id, field_id)
);
CREATE INDEX IF NOT EXISTS gin_form_responses_value ON form_responses USING GIN (value);
CREATE TRIGGER trg_form_responses_updated
BEFORE UPDATE ON form_responses FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================
-- Application Notes
-- =============================
CREATE TABLE IF NOT EXISTS application_notes (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  author_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  section_id     UUID NULL REFERENCES form_sections(id) ON DELETE SET NULL,
  visibility     TEXT NOT NULL DEFAULT 'INTERNAL' CHECK (visibility IN ('INTERNAL','APPLICANT')),
  body           TEXT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_app_notes_app ON application_notes(application_id);

-- =============================
-- Documents + requirements
-- =============================
CREATE TABLE IF NOT EXISTS documents (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id    UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  type              document_type NOT NULL,
  filename          TEXT NOT NULL,
  storage_key       TEXT NOT NULL,
  content_type      TEXT,
  size_bytes        BIGINT,
  checksum          TEXT,
  validation_status document_status NOT NULL DEFAULT 'PENDING',
  invalid_reason    TEXT,
  validated_by      UUID REFERENCES users(id) ON DELETE SET NULL,
  validated_at      TIMESTAMPTZ,
  version           INT NOT NULL DEFAULT 1,
  is_current        BOOLEAN NOT NULL DEFAULT TRUE,
  form_field_id     UUID NULL REFERENCES form_fields(id) ON DELETE SET NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_doc_current
  ON documents(application_id, type) WHERE is_current;
CREATE INDEX IF NOT EXISTS idx_docs_app   ON documents(application_id);
CREATE INDEX IF NOT EXISTS idx_docs_type  ON documents(type);
CREATE INDEX IF NOT EXISTS idx_docs_form_field ON documents(form_field_id);
CREATE TRIGGER trg_documents_updated
BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS call_document_requirements (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id       UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  type          document_type NOT NULL,
  required      BOOLEAN NOT NULL DEFAULT TRUE,
  accept        TEXT, -- p.ej. "application/pdf,image/*"
  max_size_mb   INT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_call_doc_req UNIQUE (call_id, type)
);
CREATE TRIGGER trg_call_doc_req_updated
BEFORE UPDATE ON call_document_requirements FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================
-- Reviewers / Criteria / Scores / Ranking / Policies
-- =============================
CREATE TABLE IF NOT EXISTS review_assignments (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id   UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  reviewer_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unassigned_at    TIMESTAMPTZ,
  meta             JSONB,
  CONSTRAINT uq_active_assignment UNIQUE (application_id, reviewer_user_id)
);
CREATE INDEX IF NOT EXISTS idx_review_assign_active
  ON review_assignments(application_id) WHERE unassigned_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_review_assign_reviewer_active
  ON review_assignments(reviewer_user_id) WHERE unassigned_at IS NULL;

CREATE TABLE IF NOT EXISTS criteria (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id     UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  key         TEXT NOT NULL,
  name        TEXT NOT NULL,
  weight_pct  INT  NOT NULL CHECK (weight_pct >= 0 AND weight_pct <= 100),
  config      JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_criteria_key UNIQUE (call_id, key)
);
CREATE TRIGGER trg_criteria_updated
BEFORE UPDATE ON criteria FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS scores (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  criterion_id    UUID NOT NULL REFERENCES criteria(id) ON DELETE CASCADE,
  raw_value       NUMERIC,
  normalized      NUMERIC,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_score UNIQUE (application_id, criterion_id)
);
CREATE INDEX IF NOT EXISTS idx_scores_app ON scores(application_id);
CREATE TRIGGER trg_scores_updated
BEFORE UPDATE ON scores FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS scoring_runs (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id            UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  criteria_snapshot  JSONB NOT NULL,
  tiebreakers        JSONB,
  seed               TEXT,
  executed_by        UUID REFERENCES users(id) ON DELETE SET NULL,
  executed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_scoring_runs_call ON scoring_runs(call_id);

CREATE TABLE IF NOT EXISTS ranking_results (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id            UUID NOT NULL REFERENCES scoring_runs(id) ON DELETE CASCADE,
  call_id           UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  application_id    UUID NOT NULL UNIQUE REFERENCES applications(id) ON DELETE CASCADE,
  position          INT  NOT NULL,
  selected          BOOLEAN NOT NULL DEFAULT FALSE,
  by_min_institution_rule BOOLEAN NOT NULL DEFAULT FALSE,
  exclusion_reason  TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_rank_pos_per_call UNIQUE (call_id, position)
);
CREATE INDEX IF NOT EXISTS idx_rank_call ON ranking_results(call_id);
CREATE TRIGGER trg_ranking_results_updated
BEFORE UPDATE ON ranking_results FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS call_institution_policies (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id         UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  institution_id  UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
  min_interviews  INT DEFAULT 2,
  min_selected    INT,
  top_pct         INT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_call_inst_policy UNIQUE (call_id, institution_id)
);
CREATE TRIGGER trg_call_inst_policies_updated
BEFORE UPDATE ON call_institution_policies FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================
-- Interviews
-- =============================
CREATE TABLE IF NOT EXISTS interviews (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  stage           interview_stage NOT NULL,
  interview_date  TIMESTAMPTZ,
  rubric          JSONB,
  recommendation  TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_interviews_app ON interviews(application_id);
CREATE TRIGGER trg_interviews_updated
BEFORE UPDATE ON interviews FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS interview_participants (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  interview_id  UUID NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  role          TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_int_part_interview ON interview_participants(interview_id);

-- =============================
-- Emails / Batches / Audit
-- =============================
CREATE TABLE IF NOT EXISTS email_templates (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key         TEXT NOT NULL UNIQUE,
  name        TEXT NOT NULL,
  subject_tpl TEXT NOT NULL,
  body_tpl    TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS email_batches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id         UUID REFERENCES calls(id) ON DELETE CASCADE,
  template_key    TEXT NOT NULL,
  filter_snapshot JSONB NOT NULL,
  status          TEXT NOT NULL CHECK (status IN ('DRAFT','QUEUED','RUNNING','DONE','FAILED')) DEFAULT 'DRAFT',
  scheduled_at    TIMESTAMPTZ,
  created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS email_recipients (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id      UUID NOT NULL REFERENCES email_batches(id) ON DELETE CASCADE,
  to_address    CITEXT NOT NULL,
  applicant_id  UUID REFERENCES applicants(id) ON DELETE SET NULL,
  status        TEXT NOT NULL CHECK (status IN ('QUEUED','SENT','FAILED')) DEFAULT 'QUEUED',
  error_message TEXT,
  sent_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS email_logs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key   TEXT REFERENCES email_templates(key) ON DELETE SET NULL,
  batch_id       UUID REFERENCES email_batches(id) ON DELETE SET NULL,
  to_address     CITEXT NOT NULL,
  applicant_id   UUID REFERENCES applicants(id) ON DELETE SET NULL,
  institution_id UUID REFERENCES institutions(id) ON DELETE SET NULL,
  payload        JSONB,
  status         TEXT NOT NULL CHECK (status IN ('QUEUED','SENT','FAILED')),
  error_message  TEXT,
  sent_at        TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_email_logs_status ON email_logs(status);
CREATE INDEX IF NOT EXISTS idx_email_logs_to     ON email_logs(to_address);

CREATE TABLE IF NOT EXISTS audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action        TEXT NOT NULL,
  entity        TEXT NOT NULL,
  entity_id     UUID,
  meta          JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity, entity_id);

CREATE OR REPLACE FUNCTION audit_logs_block_mods()
RETURNS trigger AS $$
BEGIN
  IF TG_OP IN ('UPDATE','DELETE') THEN
    RAISE EXCEPTION 'audit_logs es inmutable (append-only)';
  END IF;
  RETURN NEW;
END$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_audit_block_mods') THEN
    CREATE TRIGGER trg_audit_block_mods
    BEFORE UPDATE OR DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION audit_logs_block_mods();
  END IF;
END$$;

-- =============================
-- RLS Policies (preparadas; RLS deshabilitado por defecto)
-- =============================

-- Applicants
DROP POLICY IF EXISTS pol_applicants_select ON applicants;
CREATE POLICY pol_applicants_select ON applicants
  FOR SELECT USING (
    coalesce(current_setting('app.user_role', true),'') IN ('ADMIN','REVIEWER')
    OR id = NULLIF(current_setting('app.applicant_id', true),'')::uuid
  );

DROP POLICY IF EXISTS pol_applicants_update ON applicants;
CREATE POLICY pol_applicants_update ON applicants
  FOR UPDATE USING (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR id = NULLIF(current_setting('app.applicant_id', true),'')::uuid
  )
  WITH CHECK (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR id = NULLIF(current_setting('app.applicant_id', true),'')::uuid
  );

DROP POLICY IF EXISTS pol_applicants_insert ON applicants;
CREATE POLICY pol_applicants_insert ON applicants
  FOR INSERT WITH CHECK ( coalesce(current_setting('app.user_role', true),'') = 'ADMIN' );

-- Users
DROP POLICY IF EXISTS pol_users_select ON users;
CREATE POLICY pol_users_select ON users
  FOR SELECT USING (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR id = NULLIF(current_setting('app.user_id', true),'')::uuid
  );

DROP POLICY IF EXISTS pol_users_update ON users;
CREATE POLICY pol_users_update ON users
  FOR UPDATE USING (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR id = NULLIF(current_setting('app.user_id', true),'')::uuid
  )
  WITH CHECK (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR id = NULLIF(current_setting('app.user_id', true),'')::uuid
  );

DROP POLICY IF EXISTS pol_users_insert ON users;
CREATE POLICY pol_users_insert ON users
  FOR INSERT WITH CHECK ( coalesce(current_setting('app.user_role', true),'') = 'ADMIN' );

-- Sessions
DROP POLICY IF EXISTS pol_sessions_all ON user_sessions;
CREATE POLICY pol_sessions_all ON user_sessions
  FOR ALL USING (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR user_id = NULLIF(current_setting('app.user_id', true),'')::uuid
  )
  WITH CHECK (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR user_id = NULLIF(current_setting('app.user_id', true),'')::uuid
  );

-- Password resets
DROP POLICY IF EXISTS pol_pwresets_all ON password_resets;
CREATE POLICY pol_pwresets_all ON password_resets
  FOR ALL USING (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR user_id = NULLIF(current_setting('app.user_id', true),'')::uuid
  )
  WITH CHECK (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR user_id = NULLIF(current_setting('app.user_id', true),'')::uuid
  );

-- Applications
DROP POLICY IF EXISTS pol_apps_select ON applications;
CREATE POLICY pol_apps_select ON applications
  FOR SELECT USING (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR applicant_id = NULLIF(current_setting('app.applicant_id', true),'')::uuid
    OR (
      coalesce(current_setting('app.user_role', true),'') = 'REVIEWER'
      AND EXISTS (
        SELECT 1 FROM review_assignments ra
        WHERE ra.application_id = applications.id
          AND ra.reviewer_user_id = NULLIF(current_setting('app.user_id', true),'')::uuid
          AND ra.unassigned_at IS NULL
      )
    )
  );

DROP POLICY IF EXISTS pol_apps_update ON applications;
CREATE POLICY pol_apps_update ON applications
  FOR UPDATE USING (
    coalesce(current_setting('app.user_role', true),'') IN ('ADMIN','REVIEWER')
    OR applicant_id = NULLIF(current_setting('app.applicant_id', true),'')::uuid
  )
  WITH CHECK (
    coalesce(current_setting('app.user_role', true),'') IN ('ADMIN','REVIEWER')
    OR applicant_id = NULLIF(current_setting('app.applicant_id', true),'')::uuid
  );

DROP POLICY IF EXISTS pol_apps_insert ON applications;
CREATE POLICY pol_apps_insert ON applications
  FOR INSERT WITH CHECK ( coalesce(current_setting('app.user_role', true),'') = 'ADMIN' );

-- Documents
DROP POLICY IF EXISTS pol_docs_select ON documents;
CREATE POLICY pol_docs_select ON documents
  FOR SELECT USING (
    coalesce(current_setting('app.user_role', true),'') = 'ADMIN'
    OR EXISTS (
      SELECT 1 FROM applications a
      WHERE a.id = documents.application_id
        AND (
          a.applicant_id = NULLIF(current_setting('app.applicant_id', true),'')::uuid
          OR (
            coalesce(current_setting('app.user_role', true),'') = 'REVIEWER'
            AND EXISTS (
              SELECT 1 FROM review_assignments ra
              WHERE ra.application_id = a.id
                AND ra.reviewer_user_id = NULLIF(current_setting('app.user_id', true),'')::uuid
                AND ra.unassigned_at IS NULL
            )
          )
        )
    )
  );

DROP POLICY IF EXISTS pol_docs_update ON documents;
CREATE POLICY pol_docs_update ON documents
  FOR UPDATE USING ( coalesce(current_setting('app.user_role', true),'') IN ('ADMIN','REVIEWER') )
  WITH CHECK ( coalesce(current_setting('app.user_role', true),'') IN ('ADMIN','REVIEWER') );

DROP POLICY IF EXISTS pol_docs_insert ON documents;
CREATE POLICY pol_docs_insert ON documents
  FOR INSERT WITH CHECK (
    coalesce(current_setting('app.user_role', true),'') IN ('ADMIN','REVIEWER')
    OR application_id IN (
      SELECT a.id FROM applications a
      WHERE a.applicant_id = NULLIF(current_setting('app.applicant_id', true),'')::uuid
    )
  );

-- Notes
DROP POLICY IF EXISTS pol_notes_select ON application_notes;
CREATE POLICY pol_notes_select ON application_notes
  FOR SELECT USING (
    coalesce(current_setting('app.user_role', true),'') IN ('ADMIN','REVIEWER')
    OR (
      EXISTS (
        SELECT 1 FROM applications a
        WHERE a.id = application_notes.application_id
          AND a.applicant_id = NULLIF(current_setting('app.applicant_id', true),'')::uuid
      )
      AND application_notes.visibility = 'APPLICANT'
    )
  );

DROP POLICY IF EXISTS pol_notes_write ON application_notes;
CREATE POLICY pol_notes_write ON application_notes
  FOR ALL USING ( coalesce(current_setting('app.user_role', true),'') IN ('ADMIN','REVIEWER') )
  WITH CHECK ( coalesce(current_setting('app.user_role', true),'') IN ('ADMIN','REVIEWER') );

COMMIT;

-- ============================================
--               SEEDS MÍNIMOS
-- ============================================

BEGIN;

-- 0) Parámetros de ejemplo
--   Hash Argon2id (PHC) para contraseña "Changeme123!"
--   (válido en librerías estándar de verificación Argon2id)
--   Si tu backend usa "pepper" previo, ver Plan B al final.
WITH params AS (
  SELECT
    -- Hash PHC Argon2id para "Changeme123!"
    '$argon2id$v=19$m=65536,t=3,p=4$2UBoODy2X8wV4sCozdeqTQ$FZCwJwRh2y4vrr3bLCPWm+aFc+3k0I8uFHoZYMPH2KI'::text AS phc_admin,
    '$argon2id$v=19$m=65536,t=3,p=4$2UBoODy2X8wV4sCozdeqTQ$FZCwJwRh2y4vrr3bLCPWm+aFc+3k0I8uFHoZYMPH2KI'::text AS phc_reviewer,
    '$argon2id$v=19$m=65536,t=3,p=4$2UBoODy2X8wV4sCozdeqTQ$FZCwJwRh2y4vrr3bLCPWm+aFc+3k0I8uFHoZYMPH2KI'::text AS phc_applicant
)

-- 1) Institución demo
, inst AS (
  INSERT INTO institutions (name, code, commune, province, region, type)
  VALUES ('Liceo Demo FCG', 'DEM001', 'Ovalle', 'Limarí', 'Coquimbo', 'LICEO')
  ON CONFLICT (name) DO UPDATE SET updated_at = NOW()
  RETURNING id
)

-- 2) Convocatoria abierta (año actual)
, c AS (
  INSERT INTO calls (name, year, status, total_seats, min_per_institution, dates, rules, form_published_at)
  VALUES (
    'Becas FCG 2025', EXTRACT(YEAR FROM NOW())::int, 'OPEN', 100, 0,
    '{"apply_until":"2025-12-31"}'::jsonb,
    '{"eligibility":{"min_grade":5.0}}'::jsonb,
    NOW()
  )
  ON CONFLICT (year, name) DO UPDATE
    SET status='OPEN', updated_at=NOW()
  RETURNING id
)

-- 3) Secciones + campos básicos del Form Builder
, s1 AS (
  INSERT INTO form_sections (call_id, title, "order", visible)
  SELECT c.id, 'Datos académicos', 1, TRUE FROM c
  RETURNING id, call_id
), s2 AS (
  INSERT INTO form_sections (call_id, title, "order", visible)
  SELECT c.id, 'Situación socioeconómica', 2, TRUE FROM c
  RETURNING id, call_id
)
, f_ins AS (
  INSERT INTO form_fields
    (call_id, section_id, name, label, type, required, options, validation, help_text, show_if, "order", active, visibility, editable_by_roles)
  SELECT (SELECT call_id FROM s1), (SELECT id FROM s1), 'promedio', 'Promedio anual', 'NUMBER', TRUE, NULL, '{"min": 1, "max": 7}', 'Usa punto decimal', NULL, 1, TRUE, 'PUBLIC', '["APPLICANT"]'
  UNION ALL
  SELECT (SELECT call_id FROM s1), (SELECT id FROM s1), 'ranking', 'Puesto ranking', 'NUMBER', FALSE, NULL, '{"min": 1, "max": 200}', NULL, NULL, 2, TRUE, 'PUBLIC', '["APPLICANT"]'
  UNION ALL
  SELECT (SELECT call_id FROM s2), (SELECT id FROM s2), 'ingresos', 'Ingreso mensual del hogar (CLP)', 'NUMBER', TRUE, NULL, '{"min": 0}', NULL, NULL, 1, TRUE, 'PUBLIC', '["APPLICANT"]'
  UNION ALL
  SELECT (SELECT call_id FROM s2), (SELECT id FROM s2), 'rsh', 'Tramo RSH', 'SELECT', TRUE, '["40%","50%","60%","70%","80%","90%","100%"]', NULL, NULL, NULL, 2, TRUE, 'PUBLIC', '["APPLICANT"]'
  RETURNING 1
)

-- 4) Requerimientos de documentos de la convocatoria
, docreq AS (
  INSERT INTO call_document_requirements (call_id, type, required, accept, max_size_mb)
  SELECT (SELECT id FROM c), 'GRADES', TRUE, 'application/pdf', 10
  ON CONFLICT (call_id, type) DO NOTHING
  RETURNING 1
)

-- 5) Usuarios (ADMIN, REVIEWER)
, u_admin AS (
  INSERT INTO users (email, password_hash, full_name, role, is_active)
  SELECT 'admin@fcg.local', params.phc_admin, 'Admin FCG', 'ADMIN', TRUE FROM params
  ON CONFLICT (email) DO UPDATE SET updated_at=NOW()
  RETURNING id
), u_rev AS (
  INSERT INTO users (email, password_hash, full_name, role, is_active)
  SELECT 'reviewer@fcg.local', params.phc_reviewer, 'Reviewer FCG', 'REVIEWER', TRUE FROM params
  ON CONFLICT (email) DO UPDATE SET updated_at=NOW()
  RETURNING id
)

-- 6) Applicant + user APPLICANT + application demo
, a AS (
  -- RUT 12.345.678-5 (DV correcto)
  INSERT INTO applicants (rut_number, rut_dv, first_name, last_name, birth_date, email, commune, region)
  VALUES (12345678, '5', 'Postulante', 'Demo', '2004-05-10', 'postulante@fcg.local', 'Ovalle', 'Coquimbo')
  ON CONFLICT (rut_number, rut_dv) DO UPDATE SET updated_at=NOW()
  RETURNING id, email
), u_app AS (
  INSERT INTO users (email, password_hash, full_name, role, is_active, applicant_id)
  SELECT a.email, params.phc_applicant, 'Postulante Demo', 'APPLICANT', TRUE, a.id
  FROM a, params
  ON CONFLICT (email) DO UPDATE SET updated_at=NOW()
  RETURNING id, applicant_id
), app AS (
  INSERT INTO applications (applicant_id, call_id, institution_id, status, academic)
  SELECT u_app.applicant_id, (SELECT id FROM c), (SELECT id FROM inst), 'DRAFT',
         '{"promedio":5.5,"ranking":12}'::jsonb
  FROM u_app
  ON CONFLICT DO NOTHING
  RETURNING id
)
SELECT 'seed_ok' AS status;

COMMIT;

-- ==========================================================
-- NOTAS RÁPIDAS
-- ==========================================================
-- 1) Si usas RLS en producción:
--    ALTER TABLE applicants ENABLE ROW LEVEL SECURITY;
--    ... (igual para users, applications, documents, application_notes, etc.)
--    Y en tu backend, antes de cada query:
--      SELECT set_config('app.user_role',   '<ADMIN|REVIEWER|APPLICANT>', true);
--      SELECT set_config('app.user_id',     '<uuid>', true);
--      SELECT set_config('app.applicant_id','<uuid or empty>', true);
--
-- 2) Si tu backend aplica PEPPER/HMAC a tokens de password/invites:
--    - Actualmente los tokens no se seeded. Genera vía API para respetar tu PEPPER.
--
-- 3) Plan B (si tu verificación de password requiere otro hashing):
--    - Cambia el hash directamente:
--      UPDATE users SET password_hash = '<tu PHC Argon2id>' WHERE email='admin@fcg.local';
--    - O usa tu endpoint de "set password" con un password_set_token generado con tu PEPPER.
--
-- 4) Endpoints típicos para probar (según lo que ya corriste):
--    - Applicant login (ya lo probaste): POST /api/onboarding/login/applicant
--    - Documents: requiere que la application exista (ahora existe una).
--      Recuerda que el backend suele convertir KB -> bytes; en DB guardamos size_bytes.
--
-- 5) Si necesitas otra convocatoria OPEN, duplica el bloque de INSERT a "calls".
