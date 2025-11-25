-- ===========================
--  MIGRATION 004: Agregar Hitos de Ejemplo
--  Fecha: 2025-11-25
--  Descripción: Agrega hitos de prueba a las convocatorias existentes
-- ===========================

-- Agregar hitos típicos a cada convocatoria existente
DO $$
DECLARE
  call_record RECORD;
  form_postulacion UUID;
  form_documentos UUID;
  form_entrevista UUID;
BEGIN
  -- Para cada convocatoria activa
  FOR call_record IN 
    SELECT id, name, year 
    FROM public.calls 
    WHERE status = 'OPEN' OR status = 'ACTIVE'
    ORDER BY year DESC, id
    LIMIT 5 -- Solo las 5 más recientes para no llenar demasiado
  LOOP
    
    RAISE NOTICE 'Creando hitos para convocatoria: % %', call_record.name, call_record.year;
    
    -- 1. Crear formulario de postulación si no existe
    INSERT INTO public.forms (name, description, version)
    VALUES (
      'Formulario de Postulación - ' || call_record.year,
      'Formulario principal para iniciar la postulación',
      1
    )
    RETURNING id INTO form_postulacion;
    
    -- 2. Crear formulario de documentos
    INSERT INTO public.forms (name, description, version)
    VALUES (
      'Documentación Requerida - ' || call_record.year,
      'Formulario para subir documentos solicitados',
      1
    )
    RETURNING id INTO form_documentos;
    
    -- 3. Crear formulario de entrevista
    INSERT INTO public.forms (name, description, version)
    VALUES (
      'Registro de Entrevista - ' || call_record.year,
      'Información y respuestas de la entrevista personal',
      1
    )
    RETURNING id INTO form_entrevista;
    
    -- HITO 1: Postulación Inicial
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
      form_postulacion,
      '📝 Postulación Inicial',
      'Completa tu información personal y académica para iniciar el proceso',
      1,
      true,
      ARRAY['APPLICANT']::VARCHAR[],
      'ACTIVE'
    );
    
    -- HITO 2: Documentación
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
      form_documentos,
      '📄 Documentación Requerida',
      'Sube los documentos solicitados: certificados, comprobantes, etc.',
      2,
      true,
      ARRAY['APPLICANT']::VARCHAR[],
      'ACTIVE'
    );
    
    -- HITO 3: Verificación
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
      NULL,
      '✅ Verificación de Antecedentes',
      'Revisión interna de documentos y datos proporcionados',
      3,
      true,
      ARRAY['ADMIN', 'REVIEWER']::VARCHAR[],
      'ACTIVE'
    );
    
    -- HITO 4: Entrevista
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
      form_entrevista,
      '💬 Entrevista Personal',
      'Entrevista con el comité de selección',
      4,
      true,
      ARRAY['APPLICANT', 'ADMIN']::VARCHAR[],
      'ACTIVE'
    );
    
    -- HITO 5: Evaluación Final
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
      NULL,
      '⭐ Evaluación Final',
      'Evaluación y decisión del comité',
      5,
      true,
      ARRAY['ADMIN', 'REVIEWER']::VARCHAR[],
      'ACTIVE'
    );
    
    -- HITO 6: Resultado
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
      NULL,
      '🎓 Resultado',
      'Notificación de resultado final',
      6,
      false,
      ARRAY['ADMIN']::VARCHAR[],
      'ACTIVE'
    );
    
  END LOOP;
  
  RAISE NOTICE 'Hitos de prueba creados exitosamente';
END $$;
