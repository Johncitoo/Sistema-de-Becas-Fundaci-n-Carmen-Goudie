# Control de Activación de Convocatorias

## 🎯 Objetivo

Evitar que postulantes rellenen formularios de convocatorias pasadas o futuras mediante un sistema híbrido de control automático por fechas y activación manual por administrador.

---

## 🏗️ Arquitectura

### Estrategia Híbrida (Recomendada)

Combina **fechas automáticas** + **control manual** para máxima flexibilidad:

1. **Fechas automáticas**: El sistema valida `start_date` y `end_date`
2. **Control manual**: Admin puede activar/desactivar con `is_active`
3. **Cierre automático**: Flag `auto_close` determina si cierra al llegar a `end_date`

---

## 📊 Cambios en Base de Datos

### Nuevos campos en tabla `calls`

```sql
start_date      TIMESTAMPTZ    -- Fecha de inicio (postulantes pueden comenzar)
end_date        TIMESTAMPTZ    -- Fecha de cierre
is_active       BOOLEAN        -- Control manual por admin
auto_close      BOOLEAN        -- Si cierra automáticamente al llegar a end_date
```

### Función: `is_call_active(call_id)`

Valida si una convocatoria está activa considerando:
- ✅ `is_active = true`
- ✅ `status = 'OPEN'`
- ✅ Fecha actual >= `start_date` (si está definida)
- ✅ Fecha actual <= `end_date` (si `auto_close = true`)

### Función: `auto_close_expired_calls()`

Cierra automáticamente convocatorias vencidas. Puede ejecutarse:
- Por cron job periódico
- Al consultar convocatorias activas

### Vista: `active_calls`

Vista con información completa:
- `is_currently_active`: Booleano calculado
- `has_started`: Si ya pasó la fecha de inicio
- `has_ended`: Si ya pasó la fecha de cierre
- `time_until_start`: Intervalo hasta inicio
- `time_until_end`: Intervalo hasta cierre

---

## 🎨 Interfaz de Administración

### Página: `/admin/activacion-convocatorias`

Componente: `CallActivationManager.tsx`

**Funcionalidades:**

1. **Tabla de convocatorias** con:
   - Estado visual (Activa/Programada/Vencida/Inactiva)
   - Fechas de inicio y cierre (editables en línea)
   - Toggle de cierre automático
   - Toggle de activación manual

2. **Edición en línea de fechas**:
   - Click en "Editar fechas"
   - Seleccionar `start_date` y `end_date` con datetime-local
   - Guardar o cancelar

3. **Toggles visuales**:
   - **Cierre Auto**: Si está ON, cierra automáticamente al llegar a `end_date`
   - **Activación**: Si está OFF, postulantes no pueden aplicar (independiente de fechas)

4. **Color coding**:
   - 🟢 Verde: Activa (dentro del rango de fechas, activada)
   - 🟡 Amarillo: Programada (aún no llega `start_date`)
   - 🔴 Rojo: Vencida (pasó `end_date` con cierre automático)
   - ⚫ Gris: Inactiva/Cerrada (desactivada o status != OPEN)

---

## 🔧 Backend (NestJS)

### Entidad `Call`

```typescript
@Column({ name: 'start_date', type: 'timestamp', nullable: true })
startDate: Date | null;

@Column({ name: 'end_date', type: 'timestamp', nullable: true })
endDate: Date | null;

@Column({ name: 'is_active', type: 'boolean', default: false })
isActive: boolean;

@Column({ name: 'auto_close', type: 'boolean', default: true })
autoClose: boolean;

// Computed property
get isCurrentlyActive(): boolean {
  if (!this.isActive || this.status !== CallStatus.OPEN) return false;
  const now = new Date();
  if (this.startDate && now < this.startDate) return false;
  if (this.autoClose && this.endDate && now > this.endDate) return false;
  return true;
}
```

### Servicio: `listCalls({ onlyActive: true })`

Cuando `onlyActive = true`, filtra con:

```typescript
queryBuilder
  .where('c.status = :status', { status: 'OPEN' })
  .andWhere('c.isActive = :isActive', { isActive: true })
  .andWhere('(c.startDate IS NULL OR c.startDate <= :now)', { now: new Date() })
  .andWhere('(c.autoClose = false OR c.endDate IS NULL OR c.endDate > :now)', { now: new Date() });
```

### Endpoint: `PATCH /api/calls/:id`

Actualiza campos de activación:

```typescript
if (body.startDate !== undefined) call.startDate = body.startDate;
if (body.endDate !== undefined) call.endDate = body.endDate;
if (body.isActive !== undefined) call.isActive = body.isActive;
if (body.autoClose !== undefined) call.autoClose = body.autoClose;
```

---

## 🎨 Frontend (React)

### Componente: `CallStatusBadge`

Muestra badge visual con estado de la convocatoria:

```tsx
<CallStatusBadge /> // Solo badge
<CallStatusBadge showDetails={true} /> // Badge + explicación
```

Estados posibles:
- ✅ **Activa**: Verde, postulantes pueden aplicar
- 📅 **Programada**: Amarillo, aún no abre
- ⏰ **Vencida**: Rojo, ya cerró
- ⭕ **Inactiva**: Gris, desactivada por admin
- 🔒 **Cerrada**: Gris, status != OPEN

### Hook: `useCallStatus()`

```tsx
const { isActive, status } = useCallStatus();

if (!isActive) {
  // Deshabilitar formularios, mostrar advertencia
}
```

### Servicio: `callsService`

```typescript
// Obtener convocatorias activas
await callsService.getActiveCalls();

// Actualizar fechas
await callsService.updateCall(callId, {
  startDate: '2025-01-01T00:00:00Z',
  endDate: '2025-12-31T23:59:59Z',
  isActive: true,
  autoClose: true
});
```

---

## 📋 Flujo de Uso

### Escenario 1: Convocatoria con fechas automáticas

1. Admin crea convocatoria 2026
2. Configura:
   - `start_date`: 01/01/2026
   - `end_date`: 31/12/2026
   - `auto_close`: ON
   - `is_active`: ON
3. Sistema automáticamente:
   - ❌ Antes del 01/01/2026: No permite postular
   - ✅ Entre 01/01 y 31/12/2026: Permite postular
   - ❌ Después del 31/12/2026: Cierra y no permite postular

### Escenario 2: Cierre anticipado

1. Convocatoria está activa (dentro del rango de fechas)
2. Admin quiere cerrar anticipadamente
3. Opciones:
   - **Cambiar `is_active` a OFF**: Cierra inmediatamente (reversible)
   - **Cambiar `status` a CLOSED**: Cierra permanentemente
   - **Adelantar `end_date`**: Si `auto_close=ON`, cierra al llegar a nueva fecha

### Escenario 3: Extensión de plazo

1. Convocatoria vencida (`end_date` pasó)
2. Admin quiere extender
3. Opciones:
   - **Cambiar `auto_close` a OFF**: Ignora `end_date`, queda abierta
   - **Extender `end_date`**: Nueva fecha de cierre

### Escenario 4: Convocatoria manual (sin fechas)

1. Admin no configura `start_date` ni `end_date`
2. Control 100% manual con `is_active`
3. Activa/desactiva cuando quiera

---

## 🔒 Seguridad

### Validación en Backend

```typescript
// En endpoints de formularios/postulaciones
const call = await callsService.getCallById(callId);
if (!call.isCurrentlyActive) {
  throw new ForbiddenException('Esta convocatoria no está activa');
}
```

### Validación en Frontend

```tsx
const { isActive } = useCallStatus();

if (!isActive) {
  return <div>Esta convocatoria no está disponible</div>;
}
```

---

## 📦 Archivos Creados/Modificados

### Backend
- ✅ `BD/migrations/005_add_call_activation_control.sql` (migración)
- ✅ `backend/src/calls/entities/call.entity.ts` (nuevos campos + computed property)
- ✅ `backend/src/calls/calls.service.ts` (filtro de activas + actualización)
- ✅ `backend/run-activation-migration.js` (script para ejecutar migración)

### Frontend
- ✅ `frontend/src/services/calls.service.ts` (nuevo servicio)
- ✅ `frontend/src/pages/admin/CallActivationManager.tsx` (interfaz admin)
- ✅ `frontend/src/components/CallStatusBadge.tsx` (badge + hook)
- ✅ `frontend/src/pages/admin/SimpleFormBuilder.tsx` (muestra badge)
- ✅ `frontend/src/App.tsx` (ruta `/admin/activacion-convocatorias`)
- ✅ `frontend/src/components/SideNav.tsx` (enlace en menú)

---

## 🚀 Despliegue

### 1. Ejecutar migración en Railway

```bash
cd backend
node run-activation-migration.js
```

Esto:
- ✅ Agrega columnas a tabla `calls`
- ✅ Crea función `is_call_active()`
- ✅ Crea función `auto_close_expired_calls()`
- ✅ Crea vista `active_calls`
- ✅ Actualiza convocatorias existentes (OPEN → is_active=true)

### 2. Desplegar backend

```bash
cd backend
git add .
git commit -m "feat: sistema de activación de convocatorias"
git push origin main
```

### 3. Desplegar frontend

```bash
cd frontend
npm run build
git add .
git commit -m "feat: interfaz de activación de convocatorias"
git push origin main
```

---

## ✅ Ventajas de este enfoque

1. **Flexibilidad**: Fechas automáticas + control manual
2. **Escalabilidad**: Soporta múltiples convocatorias simultáneas
3. **Transparencia**: Postulantes ven claramente si pueden aplicar
4. **Auditoría**: Cambios quedan registrados en `updated_at`
5. **Reversibilidad**: Admin puede reactivar convocatoria cerrada
6. **Prevención**: Imposible aplicar a convocatorias inactivas

---

## 🎯 Próximos pasos sugeridos

1. **Email automático**: Notificar cuando convocatoria abre/cierra
2. **Dashboard**: Contador de días hasta cierre en home postulante
3. **Cron job**: Ejecutar `auto_close_expired_calls()` diariamente
4. **Logs**: Registrar cambios de activación en tabla de auditoría
5. **Roles**: Permitir a REVIEWER ver pero no modificar activación

---

## 📚 Referencias

- Migración SQL: `BD/migrations/005_add_call_activation_control.sql`
- Componente Admin: `frontend/src/pages/admin/CallActivationManager.tsx`
- Badge de estado: `frontend/src/components/CallStatusBadge.tsx`
- Entidad backend: `backend/src/calls/entities/call.entity.ts`
