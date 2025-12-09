-- Agregar campos adicionales a instituciones
-- Ejecutar en Railway SQL Query

ALTER TABLE institutions 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS director_name TEXT,
ADD COLUMN IF NOT EXISTS website TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Índices para búsqueda más rápida
CREATE INDEX IF NOT EXISTS idx_institutions_commune ON institutions(commune);
CREATE INDEX IF NOT EXISTS idx_institutions_region ON institutions(region);
CREATE INDEX IF NOT EXISTS idx_institutions_type ON institutions(type);

COMMENT ON COLUMN institutions.email IS 'Email de contacto de la institución';
COMMENT ON COLUMN institutions.phone IS 'Teléfono de contacto';
COMMENT ON COLUMN institutions.address IS 'Dirección física completa';
COMMENT ON COLUMN institutions.director_name IS 'Nombre del director/a';
COMMENT ON COLUMN institutions.website IS 'Sitio web institucional';
COMMENT ON COLUMN institutions.notes IS 'Notas adicionales o información relevante';
