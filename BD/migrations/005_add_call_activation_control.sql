-- =============================
-- Migración: Control de activación de convocatorias
-- =============================
-- Propósito: Evitar que postulantes rellenen formularios de convocatorias pasadas
-- Estrategia híbrida: Fechas automáticas + control manual

BEGIN;

-- 1. Agregar campos de fecha y control de activación
ALTER TABLE calls 
  ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS auto_close BOOLEAN DEFAULT true;

-- 2. Comentarios para claridad
COMMENT ON COLUMN calls.start_date IS 'Fecha de inicio de la convocatoria (postulantes pueden comenzar a postular)';
COMMENT ON COLUMN calls.end_date IS 'Fecha de cierre de la convocatoria (después de esta fecha, solo lectura)';
COMMENT ON COLUMN calls.is_active IS 'Control manual: Admin puede activar/desactivar independientemente de las fechas';
COMMENT ON COLUMN calls.auto_close IS 'Si es true, el sistema cierra automáticamente la convocatoria al llegar a end_date';

-- 3. Índices para consultas eficientes
CREATE INDEX IF NOT EXISTS idx_calls_active ON calls(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_calls_dates ON calls(start_date, end_date);

-- 4. Función helper: Determinar si una convocatoria está activa
CREATE OR REPLACE FUNCTION is_call_active(call_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  call_record RECORD;
  now_time TIMESTAMPTZ := NOW();
BEGIN
  SELECT 
    is_active, 
    start_date, 
    end_date, 
    auto_close,
    status
  INTO call_record
  FROM calls
  WHERE id = call_id;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Si el admin la desactivó manualmente, no está activa
  IF call_record.is_active = false THEN
    RETURN false;
  END IF;
  
  -- Si está en DRAFT o CLOSED, no está activa
  IF call_record.status IN ('DRAFT', 'CLOSED') THEN
    RETURN false;
  END IF;
  
  -- Si tiene fechas configuradas, validar rango
  IF call_record.start_date IS NOT NULL THEN
    IF now_time < call_record.start_date THEN
      RETURN false;  -- Aún no ha comenzado
    END IF;
  END IF;
  
  IF call_record.end_date IS NOT NULL AND call_record.auto_close = true THEN
    IF now_time > call_record.end_date THEN
      RETURN false;  -- Ya cerró automáticamente
    END IF;
  END IF;
  
  -- Pasó todas las validaciones
  RETURN true;
END;
$$ LANGUAGE plpgsql STABLE;

-- 5. Función para cerrar automáticamente convocatorias vencidas
-- (Puede ejecutarse con un cron job o al consultar)
CREATE OR REPLACE FUNCTION auto_close_expired_calls()
RETURNS TABLE(closed_call_id UUID, call_name TEXT) AS $$
BEGIN
  RETURN QUERY
  UPDATE calls
  SET 
    status = 'CLOSED',
    is_active = false,
    updated_at = NOW()
  WHERE 
    auto_close = true
    AND end_date < NOW()
    AND status = 'OPEN'
    AND is_active = true
  RETURNING id, name;
END;
$$ LANGUAGE plpgsql;

-- 6. Actualizar convocatorias existentes
-- Por defecto, marcamos las que están OPEN como activas
UPDATE calls
SET 
  is_active = CASE 
    WHEN status = 'OPEN' THEN true 
    ELSE false 
  END,
  auto_close = true
WHERE is_active IS NULL;

-- 7. Vista conveniente para consultas del frontend
CREATE OR REPLACE VIEW active_calls AS
SELECT 
  c.*,
  is_call_active(c.id) AS is_currently_active,
  CASE 
    WHEN c.start_date IS NULL THEN true
    WHEN NOW() < c.start_date THEN false
    ELSE true
  END AS has_started,
  CASE 
    WHEN c.end_date IS NULL THEN false
    WHEN NOW() > c.end_date THEN true
    ELSE false
  END AS has_ended,
  CASE 
    WHEN c.start_date IS NOT NULL THEN c.start_date - NOW()
    ELSE NULL
  END AS time_until_start,
  CASE 
    WHEN c.end_date IS NOT NULL THEN c.end_date - NOW()
    ELSE NULL
  END AS time_until_end
FROM calls c;

COMMENT ON VIEW active_calls IS 'Vista con información completa sobre el estado de activación de cada convocatoria';

COMMIT;
