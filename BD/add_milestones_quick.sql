-- ===========================
--  SCRIPT RÁPIDO: Agregar Hitos de Prueba
--  Instrucciones: Copia y pega este script en el Query Editor de Railway
-- ===========================

-- Primero, verificar qué convocatorias existen
-- SELECT id, name, year, status FROM calls ORDER BY year DESC LIMIT 5;

-- Usar la primera convocatoria disponible (ajusta el WHERE si necesitas otra)
DO $$
DECLARE
  v_call_id UUID;
  v_form1 UUID;
  v_form2 UUID;
  v_form3 UUID;
BEGIN
  -- Obtener la primera convocatoria (o cambia el ORDER BY para elegir otra)
  SELECT id INTO v_call_id 
  FROM calls 
  ORDER BY created_at DESC 
  LIMIT 1;
  
  IF v_call_id IS NULL THEN
    RAISE EXCEPTION 'No hay convocatorias en la base de datos. Crea una primero.';
  END IF;
  
  RAISE NOTICE 'Usando convocatoria ID: %', v_call_id;
  
  -- Crear formularios
  INSERT INTO forms (name, description) VALUES 
    ('Formulario de Postulación', 'Información personal y académica')
    RETURNING id INTO v_form1;
    
  INSERT INTO forms (name, description) VALUES 
    ('Documentación', 'Upload de documentos requeridos')
    RETURNING id INTO v_form2;
    
  INSERT INTO forms (name, description) VALUES 
    ('Entrevista', 'Registro de entrevista personal')
    RETURNING id INTO v_form3;
  
  -- Crear hitos
  INSERT INTO milestones (call_id, form_id, name, description, order_index, required, status) VALUES
    (v_call_id, v_form1, '📝 Postulación', 'Completa tu postulación inicial', 1, true, 'ACTIVE'),
    (v_call_id, v_form2, '📄 Documentos', 'Sube los documentos requeridos', 2, true, 'ACTIVE'),
    (v_call_id, NULL, '✅ Verificación', 'Revisión interna', 3, true, 'ACTIVE'),
    (v_call_id, v_form3, '💬 Entrevista', 'Entrevista personal', 4, true, 'ACTIVE'),
    (v_call_id, NULL, '⭐ Evaluación', 'Evaluación final del comité', 5, true, 'ACTIVE'),
    (v_call_id, NULL, '🎓 Resultado', 'Notificación de resultado', 6, false, 'ACTIVE');
  
  RAISE NOTICE '✅ 6 hitos creados exitosamente para la convocatoria';
END $$;

-- Verificar que se crearon
SELECT m.id, m.name, m.order_index, m.required, f.name as formulario
FROM milestones m
LEFT JOIN forms f ON m.form_id = f.id
ORDER BY m.order_index;
