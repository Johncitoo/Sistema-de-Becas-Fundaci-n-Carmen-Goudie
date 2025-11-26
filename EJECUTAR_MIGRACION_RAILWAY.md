# Guía Rápida: Ejecutar Migración en Railway

## Opción 1: Desde Railway Dashboard (Recomendado)

1. Ve a [Railway Dashboard](https://railway.app)
2. Selecciona tu proyecto PostgreSQL
3. Click en pestaña "Query"
4. Copia y pega el contenido de `BD/migrations/005_add_call_activation_control.sql`
5. Click "Run Query"
6. Verifica que aparezca: ✅ COMMIT

## Opción 2: Desde pgAdmin / DBeaver / TablePlus

1. Conecta a Railway con estas credenciales:
   - Host: `tramway.proxy.rlwy.net`
   - Port: `30026`
   - Database: `railway`
   - User: `postgres`
   - Password: (obtener de Railway Variables)

2. Abre archivo SQL:
   ```
   BD/migrations/005_add_call_activation_control.sql
   ```

3. Ejecuta el script completo

4. Verifica las columnas nuevas:
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'calls' 
   ORDER BY ordinal_position;
   ```

## Opción 3: Desde PowerShell con psql

```powershell
# Instalar psql si no lo tienes
winget install PostgreSQL.PostgreSQL

# Conectar y ejecutar
$env:PGPASSWORD="TU_PASSWORD_DE_RAILWAY"
psql -h tramway.proxy.rlwy.net -p 30026 -U postgres -d railway -f "BD/migrations/005_add_call_activation_control.sql"
```

## Verificación Post-Migración

Ejecuta estas queries para confirmar:

```sql
-- Ver nuevas columnas
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'calls'
AND column_name IN ('start_date', 'end_date', 'is_active', 'auto_close');

-- Ver funciones creadas
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name IN ('is_call_active', 'auto_close_expired_calls');

-- Ver vista creada
SELECT table_name 
FROM information_schema.views 
WHERE table_name = 'active_calls';

-- Ver estado de convocatorias
SELECT id, name, year, status, is_active, start_date, end_date, auto_close
FROM calls;
```

## Resultado Esperado

```
✅ 4 nuevas columnas agregadas a 'calls'
✅ Función is_call_active() creada
✅ Función auto_close_expired_calls() creada
✅ Vista active_calls creada
✅ Convocatorias existentes con status=OPEN tienen is_active=true
```

## Si algo sale mal

**Error: "column already exists"**
- La migración ya se ejecutó antes
- Puedes ignorar o hacer rollback:
  ```sql
  ALTER TABLE calls DROP COLUMN IF EXISTS start_date;
  ALTER TABLE calls DROP COLUMN IF EXISTS end_date;
  ALTER TABLE calls DROP COLUMN IF EXISTS is_active;
  ALTER TABLE calls DROP COLUMN IF EXISTS auto_close;
  DROP FUNCTION IF EXISTS is_call_active(UUID);
  DROP FUNCTION IF EXISTS auto_close_expired_calls();
  DROP VIEW IF EXISTS active_calls;
  ```

**Error: "permission denied"**
- Asegúrate de estar usando el usuario `postgres`
- Verifica la contraseña en Railway Variables

## Contacto

Si tienes problemas, revisa:
- 📖 `GUIA_ACTIVACION_CONVOCATORIAS.md` - Documentación técnica completa
- 📄 `RESUMEN_EJECUTIVO_ACTIVACION.md` - Resumen ejecutivo
