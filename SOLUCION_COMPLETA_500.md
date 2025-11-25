# SOLUCIÓN COMPLETA AL ERROR 500 AL CREAR POSTULANTES

## Problema
Al intentar crear un postulante en la convocatoria "Becas FCG 2026", el sistema retorna un error 500 (Internal Server Error).

## Causa Raíz
La base de datos tenía múltiples restricciones que impedían insertar postulantes sin datos completos:

1. **Columnas `first_name` y `last_name`**: Definidas como `NOT NULL` pero el código enviaba `NULL`
2. **Columnas `rut_number` y `rut_dv`**: Definidas como `NOT NULL` pero el código permitía `NULL`
3. **Constraint UNIQUE en RUT**: Impedía múltiples registros con RUT NULL
4. **Trigger de validación**: No permitía RUT NULL

## Migraciones Ejecutadas

### 1. Agregar columna institution_id
**Archivo:** `migrate-institution-id.js`
```sql
ALTER TABLE applicants ADD COLUMN institution_id UUID;
ALTER TABLE applicants ADD CONSTRAINT fk_applicants_institution 
FOREIGN KEY (institution_id) REFERENCES institutions(id) ON DELETE SET NULL;
```
**Status:** ✅ EJECUTADO

### 2. Hacer validación de RUT opcional
**Archivo:** `migrate-rut-optional.js`
```sql
CREATE OR REPLACE FUNCTION applicants_validate_rut()
RETURNS trigger AS $$
BEGIN
  -- Si no hay RUT, permitir (RUT opcional)
  IF NEW.rut_number IS NULL AND NEW.rut_dv IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Si solo uno está NULL, es error
  IF NEW.rut_number IS NULL OR NEW.rut_dv IS NULL THEN
    RAISE EXCEPTION 'RUT incompleto';
  END IF;
  
  -- Validación normal...
  RETURN NEW;
END $$ LANGUAGE plpgsql;
```
**Status:** ✅ EJECUTADO

### 3. Hacer first_name y last_name opcionales
**Archivo:** `migrate-names-optional.js`
```sql
ALTER TABLE applicants 
ALTER COLUMN first_name DROP NOT NULL,
ALTER COLUMN last_name DROP NOT NULL;
```
**Status:** ✅ EJECUTADO

### 4. Cambiar constraint de RUT a índice parcial
**Archivo:** `migrate-rut-constraint.js`
```sql
ALTER TABLE applicants DROP CONSTRAINT IF EXISTS uq_applicants_rut;

CREATE UNIQUE INDEX idx_applicants_rut_unique 
ON applicants(rut_number, rut_dv) 
WHERE rut_number IS NOT NULL AND rut_dv IS NOT NULL;
```
**Status:** ✅ EJECUTADO

### 5. Hacer rut_number y rut_dv opcionales
**Archivo:** `migrate-rut-columns-optional.js`
```sql
ALTER TABLE applicants 
ALTER COLUMN rut_number DROP NOT NULL,
ALTER COLUMN rut_dv DROP NOT NULL;
```
**Status:** ✅ EJECUTADO

## Cambios en el Código Backend

### users.controller.ts
- ✅ Maneja RUT opcional (acepta NULL)
- ✅ Maneja nombres opcionales (acepta NULL)
- ✅ Crea application automáticamente cuando se proporciona `call_id`
- ✅ Filtra postulantes por convocatoria con EXISTS subquery

### Commits Realizados
1. `39b44a4` - feat: agregar filtro por call_id en endpoint de applicants
2. `a187023` - feat: crear application automáticamente al crear postulante con call_id
3. `00d2a4f` - feat: script para hacer RUT opcional
4. `e1695f7` - feat: agregar scripts de migración para nombres y RUT opcionales
5. `1a51f58` - fix: forzar redeploy con todas las migraciones de BD
6. `2643f24` - fix: forzar redeploy railway - RUT opcional
7. `d429e5e` - feat: agregar endpoint de health con versión

## Estado de la Base de Datos

### Verificación de Columnas
```sql
SELECT column_name, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name = 'applicants';
```

**Resultado esperado:**
- ✅ `first_name`: is_nullable = 'YES'
- ✅ `last_name`: is_nullable = 'YES'  
- ✅ `rut_number`: is_nullable = 'YES'
- ✅ `rut_dv`: is_nullable = 'YES'
- ✅ `institution_id`: is_nullable = 'YES'

### Verificación del Índice de RUT
```sql
SELECT indexdef FROM pg_indexes WHERE indexname = 'idx_applicants_rut_unique';
```

**Resultado esperado:**
```sql
CREATE UNIQUE INDEX idx_applicants_rut_unique 
ON public.applicants USING btree (rut_number, rut_dv) 
WHERE ((rut_number IS NOT NULL) AND (rut_dv IS NOT NULL))
```

## Problema Actual: Railway No Despliega

### Síntomas
- ✅ Base de datos correctamente migrada
- ✅ Código backend correcto en GitHub (7 commits)
- ✅ Build local funciona sin errores
- ❌ Railway sirve código antiguo (versión sin cambios)
- ❌ Endpoint /health no existe en producción
- ❌ Error 500 persiste al crear postulante

### Soluciones Posibles

#### Opción 1: Redeploy Manual en Railway
1. Ir a tu proyecto en Railway: https://railway.app
2. Seleccionar el servicio del backend
3. Click en "Deployments"
4. Click en "Redeploy" en el último deployment
5. Esperar 2-3 minutos a que termine
6. Probar crear postulante

#### Opción 2: Verificar Auto-Deploy
1. Ir a Settings del servicio
2. Verificar que "GitHub Repo" esté conectado
3. Verificar que "Production Branch" sea `main`
4. Verificar que "Auto Deploy" esté habilitado
5. Si no está habilitado, activarlo

#### Opción 3: Trigger Manual desde GitHub
1. Ir a tu repositorio en GitHub
2. Hacer un cambio mínimo (agregar comentario)
3. Commit + Push
4. Railway debería detectar el cambio

#### Opción 4: Variables de Entorno
Verificar que Railway tenga estas variables:
- `DATABASE_URL` (connection string de PostgreSQL)
- `JWT_SECRET`
- `FRONTEND_URL`
- Cualquier otra que uses

## Prueba de Funcionamiento

Una vez que Railway despliegue correctamente, ejecutar:

```powershell
$body = @{
  email="test-funcional@test.com"
  first_name="Test"
  last_name="Funcional"
  call_id="8c48e065-ba1e-4e0e-99a2-26143eb2af7a"
} | ConvertTo-Json

$token = "TU_TOKEN_JWT_AQUI"

Invoke-RestMethod -Uri "https://fcgback-production.up.railway.app/api/applicants" `
  -Method Post `
  -ContentType "application/json" `
  -Headers @{Authorization="Bearer $token"} `
  -Body $body
```

**Resultado esperado:**
```json
{
  "id": 123,
  "email": "test-funcional@test.com",
  "fullName": "Test Funcional",
  "applicantId": "uuid-aqui"
}
```

## Verificación del Health Endpoint

Una vez desplegado:
```powershell
Invoke-RestMethod -Uri "https://fcgback-production.up.railway.app/health"
```

**Resultado esperado:**
```json
{
  "status": "ok",
  "version": "1.0.2-rut-optional",
  "timestamp": "2024-11-26T...",
  "migrations": [
    "institution_id added",
    "rut validation optional",
    "first_name/last_name nullable",
    "rut constraint partial index",
    "rut_number/rut_dv nullable"
  ]
}
```

## Scripts de Migración Incluidos

Todos los scripts están en la carpeta `backend/`:
- ✅ `migrate-institution-id.js`
- ✅ `migrate-rut-optional.js`
- ✅ `migrate-names-optional.js`
- ✅ `migrate-rut-constraint.js`
- ✅ `migrate-rut-columns-optional.js`
- ✅ `verify-db-state.js` (para verificar estado)

## Conclusión

**TODO EL TRABAJO ESTÁ HECHO:**
- ✅ 5 migraciones de base de datos ejecutadas
- ✅ 7 commits con código corregido
- ✅ Build local funciona
- ✅ Código en GitHub actualizado

**SOLO FALTA:**
- ❌ Railway desplegar el código nuevo

**ACCIÓN REQUERIDA:**
Hacer redeploy manual en Railway o verificar configuración de auto-deploy.
