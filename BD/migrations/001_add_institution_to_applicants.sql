-- Migración: Agregar columna institution_id a tabla applicants
-- Fecha: 2025-11-25

-- Verificar si la columna ya existe antes de agregarla
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'applicants' AND column_name = 'institution_id'
  ) THEN
    ALTER TABLE applicants
    ADD COLUMN institution_id UUID REFERENCES institutions(id) ON DELETE SET NULL;
    
    RAISE NOTICE 'Columna institution_id agregada a tabla applicants';
  ELSE
    RAISE NOTICE 'Columna institution_id ya existe en tabla applicants';
  END IF;
END $$;
