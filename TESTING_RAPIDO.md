# 🧪 TESTING RÁPIDO - Sistema de Hitos

## 🚀 Comandos Rápidos

### Iniciar Ambientes Localmente

```powershell
# Terminal 1 - Backend
cd "c:\Users\YeCoBz\Desktop\App\Fundación Carmes Goudie 2\backend"
npm run start:dev

# Terminal 2 - Frontend
cd "c:\Users\YeCoBz\Desktop\App\Fundación Carmes Goudie 2\frontend"
npm run dev
```

### Compilar para Producción

```powershell
# Backend
cd backend
npm run build
# ✅ Verificar carpeta dist/ creada

# Frontend
cd frontend
npm run build
# ✅ Verificar carpeta dist/ creada
```

---

## 📡 Testing de API con cURL

### 1. Login y Obtener Token

```powershell
curl -X POST https://fcgback-production.up.railway.app/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"tu_email@example.com\",\"password\":\"tu_password\"}'
```

**Guardar el `accessToken` retornado**

### 2. Listar Convocatorias

```powershell
$token = "tu-token-aqui"

curl -X GET https://fcgback-production.up.railway.app/api/calls `
  -H "Authorization: Bearer $token"
```

**Guardar un `callId` de la respuesta**

### 3. Crear Hito

```powershell
$callId = "uuid-de-convocatoria"

curl -X POST https://fcgback-production.up.railway.app/api/milestones `
  -H "Authorization: Bearer $token" `
  -H "Content-Type: application/json" `
  -d "{
    \"callId\": \"$callId\",
    \"name\": \"Postulación Inicial\",
    \"description\": \"Formulario de inscripción\",
    \"orderIndex\": 0,
    \"required\": true,
    \"whoCanFill\": [\"APPLICANT\"],
    \"status\": \"ACTIVE\"
  }"
```

### 4. Listar Hitos de una Convocatoria

```powershell
curl -X GET "https://fcgback-production.up.railway.app/api/milestones/call/$callId" `
  -H "Authorization: Bearer $token"
```

### 5. Crear Form Submission

```powershell
$applicationId = "uuid-de-application"
$milestoneId = "uuid-de-milestone"

curl -X POST https://fcgback-production.up.railway.app/api/form-submissions `
  -H "Authorization: Bearer $token" `
  -H "Content-Type: application/json" `
  -d "{
    \"applicationId\": \"$applicationId\",
    \"milestoneId\": \"$milestoneId\",
    \"formData\": {
      \"nombre\": \"Juan Pérez\",
      \"email\": \"juan@example.com\",
      \"telefono\": \"+56912345678\"
    }
  }"
```

**Guardar el `id` del submission**

### 6. Enviar Submission (marcar completado)

```powershell
$submissionId = "uuid-de-submission"
$userId = "uuid-de-usuario"

curl -X POST "https://fcgback-production.up.railway.app/api/form-submissions/$submissionId/submit" `
  -H "Authorization: Bearer $token" `
  -H "Content-Type: application/json" `
  -d "{\"userId\": \"$userId\"}"
```

### 7. Ver Progreso de Postulante

```powershell
curl -X GET "https://fcgback-production.up.railway.app/api/milestones/progress/$applicationId" `
  -H "Authorization: Bearer $token"
```

---

## 🗄️ Queries SQL Rápidas

### Conectar a Base de Datos

```powershell
psql postgresql://postgres:LVMTmEztSWRfFHuJoBLRkLUUiVAByPuv@tramway.proxy.rlwy.net:30026/railway
```

### Verificar Tablas Creadas

```sql
-- Listar tablas nuevas
\dt forms
\dt milestones
\dt form_submissions
\dt milestone_progress

-- Ver estructura de milestone
\d milestones

-- Ver estructura de milestone_progress
\d milestone_progress
```

### Ver Hitos de una Convocatoria

```sql
-- Reemplazar 'uuid-de-convocatoria'
SELECT 
  id,
  name,
  order_index,
  required,
  who_can_fill,
  status
FROM milestones
WHERE call_id = 'uuid-de-convocatoria'
ORDER BY order_index;
```

### Ver Progreso de un Postulante

```sql
-- Reemplazar 'uuid-de-application'
SELECT 
  milestone_name,
  order_index,
  status,
  started_at,
  completed_at
FROM milestone_progress
WHERE application_id = 'uuid-de-application'
ORDER BY order_index;
```

### Ver Archivos de un Submission

```sql
-- Reemplazar 'uuid-de-submission'
SELECT 
  id,
  original_filename,
  file_size,
  mime_type,
  uploaded_at
FROM files_metadata
WHERE milestone_submission_id = 'uuid-de-submission';
```

### Estadísticas Globales

```sql
-- Cuántos postulantes en cada estado por hito
SELECT 
  m.name as milestone_name,
  mp.status,
  COUNT(*) as total_postulantes
FROM milestone_progress mp
JOIN milestones m ON mp.milestone_id = m.id
GROUP BY m.name, mp.status
ORDER BY m.name, mp.status;

-- Promedio de progreso por convocatoria
SELECT 
  c.name as convocatoria,
  COUNT(DISTINCT mp.application_id) as total_postulantes,
  AVG(CASE WHEN mp.status = 'COMPLETED' THEN 1.0 ELSE 0.0 END) * 100 as promedio_completado
FROM calls c
JOIN milestones m ON m.call_id = c.id
JOIN milestone_progress mp ON mp.milestone_id = m.id
GROUP BY c.name;
```

---

## 🌐 Testing en Navegador

### Frontend Local (http://localhost:5173)

**1. Ir a Configuración de Hitos**
```
http://localhost:5173/#/admin/calls/{callId}/milestones
```

**2. Widget de Progreso (agregar temporalmente en componente)**
```tsx
import ProgressTracker from '@/components/ProgressTracker'

<ProgressTracker applicationId="uuid-aqui" />
```

### Frontend Producción (https://fcgfront.vercel.app)

**1. Login**
```
https://fcgfront.vercel.app/#/auth/login
```

**2. Configurar Hitos**
```
https://fcgfront.vercel.app/#/admin/calls/{callId}/milestones
```

---

## 🔍 Debugging

### Ver Logs Backend (Railway)

1. Ir a https://railway.app
2. Seleccionar proyecto
3. Click en servicio Backend
4. Pestaña "Logs"

**Buscar**:
- `[MilestonesService]` - Logs de servicio de hitos
- `[FormSubmissionsService]` - Logs de submissions
- Errores TypeORM: `QueryFailedError`

### Ver Logs Frontend (Vercel)

1. Ir a https://vercel.com
2. Seleccionar proyecto
3. Click en último deployment
4. Pestaña "Logs" o "Functions"

**Buscar**:
- Build errors
- Runtime errors

### Console del Navegador

**F12 → Console**

**Verificar**:
```javascript
// Ver token
localStorage.getItem('accessToken')

// Ver llamadas a API
// Network tab → filtrar por "milestones", "form-submissions"

// Ver errores de componentes
// Buscar en Console tab
```

---

## ✅ Checklist de Verificación

### Backend
- [ ] `npm run build` sin errores
- [ ] Endpoint GET /api/milestones/call/:id funciona
- [ ] Endpoint POST /api/milestones crea hito
- [ ] Endpoint POST /api/form-submissions/:id/submit actualiza progreso
- [ ] Query SQL muestra milestone_progress actualizado

### Frontend
- [ ] Página /admin/calls/:id/milestones carga sin errores
- [ ] Formulario de crear hito funciona
- [ ] Lista de hitos se actualiza después de crear
- [ ] Botones de reordenar funcionan
- [ ] Widget ProgressTracker se renderiza correctamente
- [ ] Barra de progreso muestra porcentaje correcto

### Integración
- [ ] Login funciona
- [ ] Token se guarda en localStorage
- [ ] Llamadas a API incluyen Authorization header
- [ ] Datos se persisten en base de datos
- [ ] Archivos subidos tienen milestone_submission_id

---

## 🐛 Errores Comunes y Soluciones

### Error: "401 Unauthorized"

**Causa**: Token expirado o inválido

**Solución**:
```javascript
// En console del navegador
localStorage.removeItem('accessToken')
// Luego hacer login nuevamente
```

### Error: "404 Not Found" en endpoint

**Causa**: Ruta incorrecta o backend no está corriendo

**Solución**:
1. Verificar backend está corriendo: `npm run start:dev`
2. Verificar URL: `https://fcgback-production.up.railway.app/api/milestones`
3. Verificar en Railway que servicio está deployed

### Error: "Cannot read property 'id' of undefined"

**Causa**: Datos no cargados aún

**Solución**:
```tsx
// Agregar validación
if (!applicationId) return <div>Cargando...</div>

return <ProgressTracker applicationId={applicationId} />
```

### Error: "milestone_submission_id column does not exist"

**Causa**: Migración SQL no ejecutada

**Solución**:
```powershell
cd BD
psql postgresql://postgres:...@tramway.proxy.rlwy.net:30026/railway `
  -f migrations/003_add_forms_milestones_submissions.sql
```

### Error: Módulo Radix UI no encontrado

**Causa**: Dependencias no instaladas

**Solución**:
```powershell
cd frontend
npm install @radix-ui/react-progress @radix-ui/react-select
```

---

## 🚀 Deploy Rápido

### Commit y Push

```powershell
cd "c:\Users\YeCoBz\Desktop\App\Fundación Carmes Goudie 2"

git add .
git commit -m "feat: sistema de hitos y formularios dinámicos completo"
git push origin main
```

**Railway y Vercel detectarán cambios y harán redeploy automático**

### Verificar Deploy

**Backend (Railway)**:
```powershell
curl https://fcgback-production.up.railway.app/api/milestones/call/test-id
# Debe retornar 401 o 200 (no 404)
```

**Frontend (Vercel)**:
```
https://fcgfront.vercel.app
# Debe cargar sin errores 404 en console
```

---

## 📊 Testing de Carga (Opcional)

### Crear Múltiples Hitos (Script)

```powershell
$token = "tu-token"
$callId = "uuid-convocatoria"

# Crear 5 hitos
1..5 | ForEach-Object {
  $body = @{
    callId = $callId
    name = "Hito $_"
    description = "Descripción del hito $_"
    orderIndex = $_ - 1
    required = $true
    whoCanFill = @("APPLICANT")
    status = "ACTIVE"
  } | ConvertTo-Json

  Invoke-RestMethod `
    -Uri "https://fcgback-production.up.railway.app/api/milestones" `
    -Method POST `
    -Headers @{Authorization="Bearer $token"; "Content-Type"="application/json"} `
    -Body $body
  
  Write-Host "Hito $_ creado"
}
```

### Verificar Performance

```sql
-- Tiempo de query para progreso
EXPLAIN ANALYZE
SELECT * FROM milestone_progress 
WHERE application_id = 'uuid-test';

-- Debe ser < 10ms
```

---

## 🎉 Todo Listo!

**Si todos los checks pasan** ✅:
→ Sistema completamente funcional
→ Listo para producción
→ Documentación completa

**Próximo mensaje ideal**:
"Probé todo y funciona perfecto, gracias! 🎉"
