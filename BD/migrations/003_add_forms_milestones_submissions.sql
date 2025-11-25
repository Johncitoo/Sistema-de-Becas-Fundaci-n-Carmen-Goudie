-- ===========================
--  MIGRATION 003: Forms, Milestones & Submissions Architecture
--  Fecha: 2025-11-25
--  Descripción: Refactorización completa para soportar múltiples formularios,
--               hitos (milestones) y separación de metadata vs datos
-- ===========================

-- 1. CREAR TABLA FORMS (Formularios reutilizables)
CREATE TABLE IF NOT EXISTS public.forms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  version INTEGER DEFAULT 1,
  is_template BOOLEAN DEFAULT false,
  parent_form_id UUID REFERENCES public.forms(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. MODIFICAR FORM_SECTIONS Y FORM_FIELDS para referenciar FORMS
ALTER TABLE public.form_sections ADD COLUMN IF NOT EXISTS form_id UUID REFERENCES public.forms(id) ON DELETE CASCADE;
ALTER TABLE public.form_fields ADD COLUMN IF NOT EXISTS form_id UUID REFERENCES public.forms(id) ON DELETE CASCADE;

-- Crear índices para performance
CREATE INDEX IF NOT EXISTS idx_form_sections_form ON public.form_sections(form_id);
CREATE INDEX IF NOT EXISTS idx_form_fields_form ON public.form_fields(form_id);

-- 3. CREAR TABLA MILESTONES (Hitos configurables por convocatoria)
CREATE TABLE IF NOT EXISTS public.milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id UUID NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
  form_id UUID REFERENCES public.forms(id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  required BOOLEAN DEFAULT true,
  who_can_fill VARCHAR[] DEFAULT ARRAY['APPLICANT']::VARCHAR[],
  due_date TIMESTAMPTZ,
  status VARCHAR(50) DEFAULT 'ACTIVE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT milestones_order_check CHECK (order_index >= 0)
);

CREATE INDEX IF NOT EXISTS idx_milestones_call ON public.milestones(call_id, order_index);
CREATE INDEX IF NOT EXISTS idx_milestones_form ON public.milestones(form_id);

-- 4. CREAR TABLA FORM_SUBMISSIONS (Respuestas de formularios)
CREATE TABLE IF NOT EXISTS public.form_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  form_id UUID REFERENCES public.forms(id) ON DELETE SET NULL,
  milestone_id UUID REFERENCES public.milestones(id) ON DELETE SET NULL,
  form_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  submitted_at TIMESTAMPTZ,
  submitted_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'DRAFT',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_submissions_application ON public.form_submissions(application_id);
CREATE INDEX IF NOT EXISTS idx_submissions_milestone ON public.form_submissions(milestone_id);
CREATE INDEX IF NOT EXISTS idx_submissions_form ON public.form_submissions(form_id);

-- 5. CREAR TABLA MILESTONE_PROGRESS (Progreso del aplicante en cada hito)
CREATE TABLE IF NOT EXISTS public.milestone_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  milestone_id UUID NOT NULL REFERENCES public.milestones(id) ON DELETE CASCADE,
  form_submission_id UUID REFERENCES public.form_submissions(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'PENDING',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_milestone_progress UNIQUE (application_id, milestone_id)
);

CREATE INDEX IF NOT EXISTS idx_progress_application ON public.milestone_progress(application_id);
CREATE INDEX IF NOT EXISTS idx_progress_milestone ON public.milestone_progress(milestone_id);
CREATE INDEX IF NOT EXISTS idx_progress_status ON public.milestone_progress(status);

-- 6. MODIFICAR FILES_METADATA para soportar milestone_submissions
ALTER TABLE public.files_metadata ADD COLUMN IF NOT EXISTS milestone_submission_id UUID REFERENCES public.form_submissions(id) ON DELETE CASCADE;
ALTER TABLE public.files_metadata ADD COLUMN IF NOT EXISTS mime_type_category VARCHAR(50);

CREATE INDEX IF NOT EXISTS idx_files_milestone_submission ON public.files_metadata(milestone_submission_id);
CREATE INDEX IF NOT EXISTS idx_files_entity ON public.files_metadata(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_files_uploader ON public.files_metadata(uploaded_by);

-- 7. MIGRAR DATOS EXISTENTES: Crear formulario por defecto para cada convocatoria
DO $$
DECLARE
  call_record RECORD;
  new_form_id UUID;
  new_milestone_id UUID;
BEGIN
  -- Para cada convocatoria existente
  FOR call_record IN SELECT id, name, year FROM public.calls LOOP
    
    -- Crear un formulario por defecto
    INSERT INTO public.forms (name, description, version)
    VALUES (
      call_record.name || ' ' || call_record.year || ' - Formulario Principal',
      'Formulario migrado automáticamente',
      1
    )
    RETURNING id INTO new_form_id;
    
    -- Asociar form_sections y form_fields existentes a este form
    UPDATE public.form_sections
    SET form_id = new_form_id
    WHERE call_id = call_record.id AND form_id IS NULL;
    
    UPDATE public.form_fields
    SET form_id = new_form_id
    WHERE call_id = call_record.id AND form_id IS NULL;
    
    -- Crear un milestone por defecto "Postulación"
    INSERT INTO public.milestones (
      call_id,
      form_id,
      name,
      description,
      order_index,
      required,
      who_can_fill,
      status
    )
    VALUES (
      call_record.id,
      new_form_id,
      'Postulación',
      'Formulario principal de postulación',
      1,
      true,
      ARRAY['APPLICANT']::VARCHAR[],
      'ACTIVE'
    )
    RETURNING id INTO new_milestone_id;
    
    -- Crear form_submissions para applications existentes con datos
    INSERT INTO public.form_submissions (
      application_id,
      form_id,
      milestone_id,
      form_data,
      submitted_at,
      status
    )
    SELECT
      id,
      new_form_id,
      new_milestone_id,
      COALESCE(
        jsonb_build_object(
          'academic', academic,
          'household', household,
          'participation', participation,
          'texts', texts,
          'builder_extra', builder_extra
        ),
        '{}'::jsonb
      ),
      submitted_at,
      CASE WHEN submitted_at IS NOT NULL THEN 'SUBMITTED' ELSE 'DRAFT' END
    FROM public.applications
    WHERE call_id = call_record.id
      AND (academic IS NOT NULL OR household IS NOT NULL OR participation IS NOT NULL 
           OR texts IS NOT NULL OR builder_extra IS NOT NULL);
    
    -- Crear milestone_progress para applications existentes
    INSERT INTO public.milestone_progress (
      application_id,
      milestone_id,
      form_submission_id,
      status,
      completed_at
    )
    SELECT
      a.id,
      new_milestone_id,
      fs.id,
      CASE 
        WHEN a.submitted_at IS NOT NULL THEN 'COMPLETED'
        WHEN fs.id IS NOT NULL THEN 'IN_PROGRESS'
        ELSE 'PENDING'
      END,
      a.submitted_at
    FROM public.applications a
    LEFT JOIN public.form_submissions fs ON fs.application_id = a.id AND fs.milestone_id = new_milestone_id
    WHERE a.call_id = call_record.id;
    
  END LOOP;
END $$;

-- 8. LIMPIAR APPLICATIONS: Eliminar columnas JSONB migradas (comentado por seguridad)
-- IMPORTANTE: Descomentar SOLO después de verificar que la migración fue exitosa
-- ALTER TABLE public.applications DROP COLUMN IF EXISTS academic;
-- ALTER TABLE public.applications DROP COLUMN IF EXISTS household;
-- ALTER TABLE public.applications DROP COLUMN IF EXISTS participation;
-- ALTER TABLE public.applications DROP COLUMN IF EXISTS texts;
-- ALTER TABLE public.applications DROP COLUMN IF EXISTS builder_extra;

-- 9. TRIGGERS para updated_at
CREATE TRIGGER set_updated_at_forms
  BEFORE UPDATE ON public.forms
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_milestones
  BEFORE UPDATE ON public.milestones
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_submissions
  BEFORE UPDATE ON public.form_submissions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_progress
  BEFORE UPDATE ON public.milestone_progress
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 10. CONSTRAINTS adicionales para integridad
ALTER TABLE public.form_submissions 
  ADD CONSTRAINT chk_submission_status 
  CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED'));

ALTER TABLE public.milestone_progress 
  ADD CONSTRAINT chk_progress_status 
  CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'SKIPPED', 'BLOCKED'));

-- 11. COMENTARIOS para documentación
COMMENT ON TABLE public.forms IS 'Formularios reutilizables y versionables';
COMMENT ON TABLE public.milestones IS 'Hitos configurables por convocatoria con orden secuencial';
COMMENT ON TABLE public.form_submissions IS 'Respuestas de formularios ligadas a applications y milestones';
COMMENT ON TABLE public.milestone_progress IS 'Progreso del aplicante en cada hito del proceso';
COMMENT ON COLUMN public.files_metadata.milestone_submission_id IS 'Liga archivos a una submission específica';
COMMENT ON COLUMN public.files_metadata.mime_type_category IS 'Categoría del archivo: image, document, pdf, video, audio';

-- ===========================
--  FIN MIGRATION 003
-- ===========================
