-- Script de verificación y actualización de instituciones
-- Ejecutar en consola SQL de Railway

-- 1. Ver estructura actual de la tabla
\d institutions

-- 2. Verificar si los campos ya existen
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'institutions';

-- 3. Agregar campos si no existen
ALTER TABLE institutions 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS director_name TEXT,
ADD COLUMN IF NOT EXISTS website TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT;

-- 4. Crear índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_institutions_commune ON institutions(commune);
CREATE INDEX IF NOT EXISTS idx_institutions_region ON institutions(region);
CREATE INDEX IF NOT EXISTS idx_institutions_type ON institutions(type);

-- 5. Verificar que se agregaron correctamente
SELECT 
  id,
  name,
  code,
  commune,
  email,
  phone,
  director_name,
  active,
  created_at
FROM institutions
LIMIT 5;

-- 6. Estadísticas
SELECT 
  type,
  COUNT(*) as total,
  COUNT(email) as con_email,
  COUNT(phone) as con_telefono
FROM institutions
GROUP BY type;
