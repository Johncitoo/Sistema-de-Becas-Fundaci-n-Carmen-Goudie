# 🎯 Sistema de Hitos y Formularios Dinámicos - Implementación Completa

## 📋 Resumen Ejecutivo

Se ha implementado un sistema completo de gestión de hitos (milestones) para convocatorias, permitiendo:
- Configurar etapas secuenciales para cada convocatoria
- Asociar formularios dinámicos a cada hito
- Subir archivos adjuntos vinculados a submissions de hitos
- Rastrear el progreso de postulantes en tiempo real
- Sistema de permisos flexible (quién puede completar cada hito)

---

## 🏗️ Arquitectura Implementada

### **Base de Datos (PostgreSQL)**

#### Nuevas Tablas Creadas

**1. `forms`** - Catálogo de formularios reutilizables
```sql
- id (uuid)
- name (text) - Nombre del formulario
- description (text) - Descripción opcional
- version (integer) - Versionado automático
- is_template (boolean) - Si es plantilla o instancia específica
- parent_form_id (uuid) - Referencia al formulario padre (para versionado)
- created_at, updated_at
```

**2. `milestones`** - Hitos de cada convocatoria
```sql
- id (uuid)
- call_id (uuid) - FK a calls
- form_id (uuid) - FK a forms (opcional)
- name (text) - Ej: "Postulación Inicial", "Entrevista"
- description (text)
- order_index (integer) - Orden secuencial (0, 1, 2...)
- required (boolean) - Si es obligatorio completarlo
- who_can_fill (text[]) - Array: ['APPLICANT', 'ADMIN', 'REVIEWER']
- due_date (timestamp) - Fecha límite (opcional)
- status (text) - 'ACTIVE', 'INACTIVE', 'ARCHIVED'
- created_at, updated_at
```

**3. `form_submissions`** - Instancias de formularios completados
```sql
- id (uuid)
- application_id (uuid) - FK a applications
- form_id (uuid) - FK a forms (opcional, puede ser formulario ad-hoc)
- milestone_id (uuid) - FK a milestones (opcional)
- form_data (jsonb) - Datos del formulario en JSON
- submitted_at (timestamp) - Cuándo se marcó como enviado
- submitted_by (uuid) - FK a users (quién lo envió)
- status (text) - 'DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED'
- created_at, updated_at
```

**4. `milestone_progress`** - Progreso de postulantes por hito
```sql
- id (uuid)
- application_id (uuid) - FK a applications
- milestone_id (uuid) - FK a milestones
- milestone_name (text) - Nombre del hito (desnormalizado para histórico)
- order_index (integer) - Orden (desnormalizado)
- required (boolean) - Si era requerido (desnormalizado)
- status (text) - 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED'
- started_at (timestamp)
- completed_at (timestamp)
- created_at, updated_at
```

#### Modificaciones a Tablas Existentes

**`files_metadata`** (en Storage Service)
```sql
+ milestone_submission_id (uuid) - Relaciona archivos con submissions de hitos
```

---

### **Backend (NestJS + TypeORM)**

#### Módulos Creados

**1. FormsModule** (`backend/src/forms/`)
- **Entity**: `Form` - Entidad TypeORM para formularios
- **Service**: `FormsService` - CRUD completo + versionado
  - `create()`, `findAll()`, `findOne()`, `update()`, `remove()`
  - `createVersion()` - Crea nueva versión basada en formulario existente
- **Controller**: `FormsController` - Endpoints REST
  ```
  POST   /api/forms
  GET    /api/forms?isTemplate=true
  GET    /api/forms/:id
  PATCH  /api/forms/:id
  DELETE /api/forms/:id
  POST   /api/forms/:id/version
  ```

**2. MilestonesModule** (`backend/src/milestones/`)
- **Entity**: `Milestone` - Entidad TypeORM para hitos
- **Service**: `MilestonesService` - CRUD + gestión de progreso
  - `findByCall(callId)` - Hitos ordenados por `orderIndex`
  - `getProgress(applicationId)` - Progreso completo con summary
  - `initializeProgress(applicationId, callId)` - Inicializa progreso para postulante
- **Controller**: `MilestonesController` - Endpoints REST
  ```
  POST   /api/milestones
  GET    /api/milestones/call/:callId
  GET    /api/milestones/:id
  PATCH  /api/milestones/:id
  DELETE /api/milestones/:id
  GET    /api/milestones/progress/:applicationId
  POST   /api/milestones/progress/initialize
  ```

**3. FormSubmissionsModule** (`backend/src/form-submissions/`)
- **Entity**: `FormSubmission` - Entidad TypeORM para submissions
- **Service**: `FormSubmissionsService` - CRUD + lógica de envío
  - `submit(id, userId)` - Marca como SUBMITTED y actualiza milestone_progress a COMPLETED
  - `findByApplication()`, `findByMilestone()` - Filtros
- **Controller**: `FormSubmissionsController` - Endpoints REST
  ```
  POST   /api/form-submissions
  GET    /api/form-submissions/application/:applicationId
  GET    /api/form-submissions/milestone/:milestoneId
  GET    /api/form-submissions/:id
  PATCH  /api/form-submissions/:id
  POST   /api/form-submissions/:id/submit
  DELETE /api/form-submissions/:id
  ```

**4. MilestoneProgressModule** (`backend/src/milestone-progress/`)
- **Entity**: `MilestoneProgress` - Entidad TypeORM para progreso

#### Modificaciones a Módulos Existentes

**StorageClientModule** (`backend/src/storage-client/`)
- **UploadFileDto**: Agregado campo `milestoneSubmissionId?: string`
- **UploadFileOptions**: Agregado campo `milestoneSubmissionId?: string`
- **uploadFile()**: Ahora envía `milestone_submission_id` al storage service

**AppModule** (`backend/src/app.module.ts`)
```typescript
imports: [
  // ... módulos existentes
  FormsModule,
  MilestonesModule,
  FormSubmissionsModule,
]
```

---

### **Frontend (React + TypeScript)**

#### Servicios Creados

**1. `forms.service.ts`** - Cliente API para formularios
```typescript
export const formsService = {
  create(data, token): Promise<Form>
  getAll(isTemplate?, token?): Promise<Form[]>
  getById(id, token): Promise<Form>
  update(id, data, token): Promise<Form>
  delete(id, token): Promise<void>
  createVersion(id, changes, token): Promise<Form>
}
```

**2. `milestones.service.ts`** - Cliente API para hitos
```typescript
export const milestonesService = {
  create(data, token): Promise<Milestone>
  getByCall(callId, token): Promise<Milestone[]>
  getById(id, token): Promise<Milestone>
  update(id, data, token): Promise<Milestone>
  delete(id, token): Promise<void>
  getProgress(applicationId, token): Promise<{
    progress: MilestoneProgress[],
    summary: ProgressSummary
  }>
  initializeProgress(applicationId, callId, token): Promise<void>
}

// Tipos exportados
interface ProgressSummary {
  total: number
  completed: number
  pending: number
  percentage: number
  currentMilestone: MilestoneProgress | null
}
```

**3. `formSubmissions.service.ts`** - Cliente API para submissions
```typescript
export const formSubmissionsService = {
  create(data, token): Promise<FormSubmission>
  getByApplication(applicationId, token): Promise<FormSubmission[]>
  getByMilestone(milestoneId, token): Promise<FormSubmission[]>
  getById(id, token): Promise<FormSubmission>
  update(id, data, token): Promise<FormSubmission>
  submit(id, userId, token): Promise<FormSubmission>
  delete(id, token): Promise<void>
}
```

#### Componentes Creados

**1. `MilestoneManagement.tsx`** - Página de administración de hitos
- **Ruta**: `/admin/calls/:callId/milestones`
- **Funcionalidad**:
  - Listar hitos de una convocatoria
  - Crear nuevos hitos
  - Editar hitos existentes
  - Eliminar hitos
  - Reordenar hitos (botones ↑ ↓)
  - Asignar formularios a hitos
  - Configurar permisos (whoCanFill: APPLICANT, ADMIN, REVIEWER)
  - Marcar como obligatorio/opcional
- **Características**:
  - Interfaz drag-free (botones en lugar de drag & drop)
  - Formulario inline para crear/editar
  - Validaciones en tiempo real
  - Integración con FormsService

**2. `ProgressTracker.tsx`** - Widget de progreso para postulantes
- **Props**: `{ applicationId: string }`
- **Funcionalidad**:
  - Muestra barra de progreso con porcentaje
  - Timeline visual con iconos de estado:
    - ✅ COMPLETED (verde)
    - ⏰ IN_PROGRESS (azul)
    - ⭕ PENDING (gris)
    - ⚠️ BLOCKED (rojo)
  - Muestra fechas de inicio/completado
  - Resalta hito actual
  - Mensaje de felicitación al 100%
- **Uso**: Se puede integrar en `ApplicantHome` o `ApplicationDetailPage`

**3. `progress.tsx`** - Componente UI reutilizable
- Barra de progreso basada en Radix UI
- Props: `value` (0-100)

**4. `select.tsx`** - Componente Select reutilizable
- Dropdown basado en Radix UI
- Componentes: `Select`, `SelectTrigger`, `SelectValue`, `SelectContent`, `SelectItem`

#### Routing

**Nuevas Rutas Agregadas**:
```typescript
// En AdminLayout
{
  path: 'calls/:callId/milestones',
  element: <MilestoneManagement />
}
```

---

## 🔄 Flujos de Trabajo

### **Flujo 1: Configuración de Convocatoria (Admin)**

1. Admin crea una convocatoria en `/admin/calls`
2. Admin navega a `/admin/calls/:callId/milestones`
3. Admin configura hitos:
   - Hito 1: "Postulación Inicial" → Formulario de inscripción → Obligatorio → Puede completar: APPLICANT
   - Hito 2: "Entrevista" → Sin formulario → Obligatorio → Puede completar: ADMIN
   - Hito 3: "Documentación Final" → Formulario de docs → Obligatorio → Puede completar: APPLICANT
4. Sistema guarda configuración en DB

### **Flujo 2: Postulación (Applicant)**

1. Postulante crea una `application` para una convocatoria
2. Sistema llama automáticamente a `milestonesService.initializeProgress(applicationId, callId)`
   - Crea registros en `milestone_progress` para cada hito
   - Estado inicial: `PENDING`
3. Postulante ve su progreso en `<ProgressTracker />`
4. Postulante completa hito 1:
   - Llena formulario de postulación
   - Sistema crea `form_submission` con `status='DRAFT'`
   - Postulante sube archivos (CV, carta motivación)
     - Archivos se vinculan con `milestone_submission_id`
   - Postulante hace "Enviar"
     - Sistema llama `formSubmissionsService.submit(submissionId, userId)`
     - Backend actualiza `form_submission.status = 'SUBMITTED'`
     - Backend actualiza `milestone_progress.status = 'COMPLETED'`
5. Sistema automáticamente marca siguiente hito como `IN_PROGRESS`

### **Flujo 3: Seguimiento (Admin/Reviewer)**

1. Admin ve lista de postulantes en `/admin/applications`
2. Puede ver progreso de cada postulante:
   ```
   Juan Pérez: 66% (2/3 hitos completados)
   ✅ Postulación Inicial
   ✅ Entrevista
   ⏰ Documentación Final (en progreso)
   ```
3. Admin puede descargar archivos adjuntos
4. Admin puede aprobar/rechazar submissions

---

## 📁 Integración con Storage

### **Flujo de Upload con Hitos**

```typescript
// En FormPage.tsx (ejemplo de integración futura)
import { FileUpload } from '@/components/FileUpload'
import { formSubmissionsService } from '@/services/formSubmissions.service'

function FormPage() {
  const [submissionId, setSubmissionId] = useState<string>()

  // Cuando postulante comienza a llenar formulario
  useEffect(() => {
    const initSubmission = async () => {
      const submission = await formSubmissionsService.create({
        applicationId,
        milestoneId,
        formId,
        formData: {}
      }, token)
      setSubmissionId(submission.id)
    }
    initSubmission()
  }, [])

  return (
    <form>
      {/* Campos normales del formulario */}
      <Input name="nombre" />
      <Input name="email" />
      
      {/* Campo de archivos */}
      <FileUpload
        label="Curriculum Vitae"
        accept=".pdf,.doc,.docx"
        maxSizeMB={5}
        uploadPath={`applications/${applicationId}`}
        metadata={{
          milestoneSubmissionId: submissionId,  // ← Vinculación clave
          fileType: 'cv',
          applicantId: userId
        }}
        onUploadSuccess={(file) => {
          console.log('Archivo subido:', file)
        }}
      />

      <Button onClick={handleSubmit}>Enviar Postulación</Button>
    </form>
  )
}
```

### **Consultas de Archivos por Hito**

```typescript
// Obtener todos los archivos de un hito específico
const files = await filesService.listFiles({
  filters: {
    milestone_submission_id: submissionId
  }
}, token)
```

---

## 🎨 Ejemplo de UI - Progress Tracker

```
┌─────────────────────────────────────────────────┐
│ Tu Progreso                                     │
│ 2 de 3 hitos completados                        │
├─────────────────────────────────────────────────┤
│ 66% Completado              1 pendiente         │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░                       │
├─────────────────────────────────────────────────┤
│ ● ✅ 1. Postulación Inicial *                   │
│ │     Completado                                │
│ │     Completado: 15/12/2024                    │
│ │                                               │
│ ● ✅ 2. Entrevista *                            │
│ │     Completado                                │
│ │     Completado: 20/12/2024                    │
│ │                                               │
│ ● ⏰ 3. Documentación Final *         [Actual]  │
│       En progreso                               │
│       Iniciado: 22/12/2024                      │
└─────────────────────────────────────────────────┘
```

---

## 🔧 Configuración Técnica

### **Variables de Entorno**

```env
# Backend
DATABASE_URL=postgresql://postgres:pass@tramway.proxy.rlwy.net:30026/railway
STORAGE_SERVICE_URL=https://fcgstorage-production.up.railway.app

# Frontend
VITE_API_URL=https://fcgback-production.up.railway.app/api
```

### **Dependencias Adicionales**

#### Backend
```json
{
  "@nestjs/typeorm": "^10.x",
  "typeorm": "^0.3.x",
  "pg": "^8.x"
}
```

#### Frontend
```bash
npm install @radix-ui/react-progress @radix-ui/react-select
npm install lucide-react
```

---

## 📊 Migración de Datos

**Script**: `BD/migrations/003_add_forms_milestones_submissions.sql`

**Acciones Realizadas**:
1. ✅ Crear tablas: `forms`, `milestones`, `form_submissions`, `milestone_progress`
2. ✅ Agregar columna `milestone_submission_id` a `files_metadata`
3. ✅ Migrar datos existentes:
   - Crear formulario default para cada convocatoria
   - Migrar `applications.form_data` → `form_submissions.form_data`
   - Crear hito "Postulación Inicial" para convocatorias existentes
   - Inicializar `milestone_progress` para applications existentes
4. ✅ Crear índices para performance
5. ✅ Crear triggers `updated_at`
6. ✅ Agregar constraints y foreign keys

**Ejecutado**:
```bash
psql -h tramway.proxy.rlwy.net -p 30026 -U postgres -d railway \
     -f migrations/003_add_forms_milestones_submissions.sql
```

---

## ✅ Checklist de Implementación

### Backend
- [x] Crear entidades TypeORM (Form, Milestone, FormSubmission, MilestoneProgress)
- [x] Crear módulos NestJS (FormsModule, MilestonesModule, FormSubmissionsModule)
- [x] Implementar servicios con lógica de negocio
- [x] Implementar controllers con endpoints REST
- [x] Actualizar StorageClientModule para milestone_submission_id
- [x] Registrar módulos en AppModule
- [x] Ejecutar migración SQL

### Frontend
- [x] Crear servicios TypeScript (forms.service.ts, milestones.service.ts, formSubmissions.service.ts)
- [x] Crear componente MilestoneManagement (admin)
- [x] Crear componente ProgressTracker (widget)
- [x] Crear componentes UI (Progress, Select)
- [x] Agregar rutas al router
- [ ] Integrar FileUpload en FormPage con milestone_submission_id
- [ ] Integrar ProgressTracker en ApplicantHome
- [ ] Testing end-to-end

### Testing
- [ ] Compilar backend (`npm run build`)
- [ ] Compilar frontend (`npm run build`)
- [ ] Testing de endpoints con Postman
- [ ] Testing de UI en navegador
- [ ] Testing de flujo completo

### Deployment
- [ ] Commit y push a GitHub
- [ ] Deploy backend a Railway
- [ ] Deploy frontend a Vercel
- [ ] Verificar en producción

---

## 🚀 Próximos Pasos

### Prioridad Alta
1. **Compilar y verificar** que no haya errores TypeScript
2. **Instalar dependencias faltantes** (@radix-ui packages)
3. **Integrar FileUpload** en FormPage con milestone_submission_id
4. **Integrar ProgressTracker** en página de postulantes

### Prioridad Media
5. Crear página de administración de formularios dinámicos
6. Implementar notificaciones al completar hitos
7. Agregar fechas límite con alerts
8. Dashboard de estadísticas (cuántos postulantes en cada hito)

### Prioridad Baja
9. Exportar progreso a PDF
10. Notificaciones por email automáticas
11. Sistema de comentarios en cada hito
12. Audit log de cambios en hitos

---

## 🎓 Documentación Técnica

### **Conceptos Clave**

**Milestone (Hito)**
- Etapa secuencial en el proceso de postulación
- Puede tener un formulario asociado
- Tiene permisos configurables (whoCanFill)
- Puede ser obligatorio u opcional

**Form Submission**
- Instancia de un formulario completado
- Almacena datos en JSONB
- Estados: DRAFT → SUBMITTED → APPROVED/REJECTED
- Se vincula a un milestone y application

**Milestone Progress**
- Rastrea el avance de un postulante en cada hito
- Estados: PENDING → IN_PROGRESS → COMPLETED/BLOCKED
- Se desnormalizan datos para histórico

**File Metadata**
- Archivos adjuntos vinculados a submissions
- Campo `milestone_submission_id` relaciona archivo con submission
- Permite consultas eficientes

### **Decisiones de Diseño**

1. **¿Por qué desnormalizar milestone_name en milestone_progress?**
   - Para mantener histórico: si admin renombra un hito, no afecta registros pasados

2. **¿Por qué JSONB para form_data?**
   - Flexibilidad: formularios dinámicos con campos variables
   - Performance: PostgreSQL tiene excelentes índices JSONB

3. **¿Por qué separar Form de FormSubmission?**
   - Reutilización: un formulario puede usarse en múltiples convocatorias
   - Versionado: puedes crear nuevas versiones sin perder datos históricos

4. **¿Por qué array whoCanFill?**
   - Flexibilidad: un hito puede ser completado por múltiples roles
   - Ejemplo: entrevista puede ser agendada por ADMIN o APPLICANT

---

## 📞 Soporte

Para preguntas o issues:
- Backend: Revisar logs en Railway
- Frontend: Revisar console del navegador
- Database: Conectar con psql y revisar datos

**Conexión DB**:
```bash
psql postgresql://postgres:LVMTmEztSWRfFHuJoBLRkLUUiVAByPuv@tramway.proxy.rlwy.net:30026/railway
```

**Consultas útiles**:
```sql
-- Ver hitos de una convocatoria
SELECT * FROM milestones WHERE call_id = 'uuid-aqui' ORDER BY order_index;

-- Ver progreso de un postulante
SELECT * FROM milestone_progress WHERE application_id = 'uuid-aqui' ORDER BY order_index;

-- Ver archivos de un submission
SELECT * FROM files_metadata WHERE milestone_submission_id = 'uuid-aqui';
```

---

## 🎉 Conclusión

El sistema de hitos está completamente arquitecturado y listo para:
1. Gestión flexible de procesos de postulación
2. Rastreo de progreso en tiempo real
3. Integración con archivos adjuntos
4. Escalabilidad a futuros requerimientos

**Estado**: ✅ Backend implementado | ⏳ Frontend en progreso | 🔄 Integración pendiente
