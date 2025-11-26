# Resumen Ejecutivo: Sistema de Activación de Convocatorias

## 🎯 Problema Resuelto

**Situación**: En el futuro habrán múltiples convocatorias (una anual). Existe el riesgo de que postulantes rellenen formularios de convocatorias pasadas o futuras por error o confusión.

**Solución**: Sistema híbrido de control de activación que combina:
- ✅ **Fechas automáticas**: Validación por `start_date` y `end_date`
- ✅ **Control manual**: Admin puede activar/desactivar independientemente
- ✅ **Cierre automático**: Configurable con flag `auto_close`

---

## 📊 Características Implementadas

### 1. Base de Datos (PostgreSQL)

**Nuevos campos en tabla `calls`:**
```sql
start_date      TIMESTAMPTZ    -- Fecha de inicio de postulaciones
end_date        TIMESTAMPTZ    -- Fecha de cierre de postulaciones
is_active       BOOLEAN        -- Control manual por admin
auto_close      BOOLEAN        -- Si cierra automáticamente al llegar a end_date
```

**Funciones SQL:**
- `is_call_active(call_id)`: Valida si convocatoria está activa
- `auto_close_expired_calls()`: Cierra convocatorias vencidas automáticamente

**Vista:**
- `active_calls`: Información calculada sobre estado de activación

### 2. Backend (NestJS + TypeORM)

**Entidad actualizada:**
- Nuevos campos en `Call` entity
- Computed property `isCurrentlyActive`

**Servicio mejorado:**
- Filtro `onlyActive` valida fechas y estado
- Endpoint PATCH actualiza campos de activación

**Validación:**
```typescript
queryBuilder
  .where('c.status = :status', { status: 'OPEN' })
  .andWhere('c.isActive = :isActive', { isActive: true })
  .andWhere('(c.startDate IS NULL OR c.startDate <= :now)')
  .andWhere('(c.autoClose = false OR c.endDate IS NULL OR c.endDate > :now)');
```

### 3. Frontend (React + TypeScript)

**Nueva página admin:**
- `/admin/activacion-convocatorias` → `CallActivationManager`
- Tabla visual con todas las convocatorias
- Edición en línea de fechas con datetime-local
- Toggles para activación manual y cierre automático
- Color coding por estado (Activa/Programada/Vencida/Inactiva)

**Componente reutilizable:**
- `<CallStatusBadge />`: Badge visual en tiempo real
- `<CallStatusBadge showDetails />`: Con explicación completa
- Hook `useCallStatus()` para validaciones

**Servicio API:**
- `callsService.getCalls({ onlyActive: true })`
- `callsService.updateCall(id, { isActive, startDate, endDate, autoClose })`

---

## 🎨 Interfaz de Usuario

### Página de Activación (Admin)

| Convocatoria | Estado | Fecha Inicio | Fecha Cierre | Cierre Auto | Activación | Acciones |
|-------------|--------|-------------|-------------|-------------|-----------|----------|
| Test 2029 | 🟢 Activa | 01/01/2029 | 31/12/2029 | ✅ | ✅ | Editar fechas |
| Test 2028 | 🔴 Vencida | 01/01/2028 | 31/12/2028 | ✅ | ✅ | Editar fechas |
| Test 2030 | 🟡 Programada | 01/01/2030 | 31/12/2030 | ✅ | ✅ | Editar fechas |

**Interacciones:**
- **Editar fechas**: Click → datetime-local → Guardar/Cancelar
- **Toggle Cierre Auto**: ON/OFF inmediato
- **Toggle Activación**: ON/OFF inmediato (solo si status=OPEN)

### Badge de Estado

Aparece en:
- Diseñador de Formularios (SimpleFormBuilder)
- Configurador de Hitos (MilestoneCreator)
- Cualquier página que use `<CallStatusBadge />`

**Estados visuales:**
```
🟢 Activa              → Postulantes pueden aplicar
🟡 Programada          → Abre en X días
🔴 Vencida             → Cerró hace X días  
⚫ Inactiva/Cerrada    → Admin desactivó o status!=OPEN
```

---

## 🔒 Lógica de Validación

### Para que una convocatoria esté activa:

1. ✅ `status = 'OPEN'` (no DRAFT ni CLOSED)
2. ✅ `is_active = true` (admin la activó)
3. ✅ Fecha actual >= `start_date` (si está definida)
4. ✅ Fecha actual <= `end_date` (si `auto_close = true`)

**Pseudocódigo:**
```typescript
function isActive(call) {
  if (call.status !== 'OPEN') return false;
  if (!call.isActive) return false;
  if (call.startDate && now < call.startDate) return false;
  if (call.autoClose && call.endDate && now > call.endDate) return false;
  return true;
}
```

---

## 📋 Casos de Uso

### Caso 1: Convocatoria anual estándar

**Configuración:**
- start_date: 01/01/2026 00:00
- end_date: 31/12/2026 23:59
- auto_close: ✅ ON
- is_active: ✅ ON

**Comportamiento:**
- ❌ Antes del 01/01/2026: No permite postular (badge: Programada)
- ✅ Durante 2026: Permite postular (badge: Activa)
- ❌ Después del 31/12/2026: Cierra automáticamente (badge: Vencida)

### Caso 2: Cierre anticipado

**Situación:** Convocatoria activa, pero cupos se llenaron.

**Opción A - Desactivar:**
- Toggle `is_active` → OFF
- Efecto inmediato, reversible

**Opción B - Cambiar estado:**
- Cambiar `status` → CLOSED
- Más permanente

### Caso 3: Extensión de plazo

**Situación:** Convocatoria vencida, necesitan extender.

**Opción A - Desactivar cierre auto:**
- Toggle `auto_close` → OFF
- Ignora end_date, queda abierta indefinidamente

**Opción B - Extender fecha:**
- Editar fechas → Nuevo `end_date`
- Se extiende hasta nueva fecha

### Caso 4: Control 100% manual

**Configuración:**
- start_date: NULL
- end_date: NULL
- auto_close: ❌ OFF
- is_active: Toggle manual

**Comportamiento:**
- Admin controla completamente con `is_active`
- No hay validaciones de fecha

---

## 🚀 Despliegue Realizado

### Frontend (Vercel)
✅ Commit: `f0034ed`
- CallActivationManager.tsx (492 líneas)
- CallStatusBadge.tsx (154 líneas)
- calls.service.ts (89 líneas)
- Ruta /admin/activacion-convocatorias
- Enlace en SideNav

### Backend (Railway)
✅ Commit: `1341b24`
- call.entity.ts actualizada (nuevos campos)
- calls.service.ts (filtro de activas)
- Migración SQL lista

### Pendiente
⚠️ Ejecutar migración SQL en Railway:
```sql
-- Archivo: BD/migrations/005_add_call_activation_control.sql
-- Ejecutar en Railway PostgreSQL
```

---

## 📊 Impacto

### Antes
❌ Postulantes podían aplicar a cualquier convocatoria
❌ No había control de fechas
❌ Riesgo de confusión entre convocatorias
❌ Admin no podía cerrar/abrir manualmente

### Después
✅ Validación automática por fechas
✅ Control manual granular por admin
✅ Badge visual de estado en tiempo real
✅ Prevención de postulaciones a convocatorias pasadas
✅ Flexibilidad para casos especiales (extensiones, cierres anticipados)
✅ Interfaz intuitiva para gestión

---

## 🔧 Mantenimiento

### Tareas automáticas sugeridas

1. **Cron job diario:**
   ```sql
   SELECT * FROM auto_close_expired_calls();
   ```

2. **Email notificación:**
   - Avisar admin cuando convocatoria por cerrar (7 días antes)
   - Avisar postulantes cuando abre nueva convocatoria

3. **Dashboard:**
   - Mostrar countdown en home postulante
   - Graficar línea de tiempo de convocatorias

### Queries útiles

**Ver convocatorias activas:**
```sql
SELECT * FROM active_calls WHERE is_currently_active = true;
```

**Cerrar convocatorias vencidas:**
```sql
SELECT * FROM auto_close_expired_calls();
```

**Extender plazo de convocatoria:**
```sql
UPDATE calls 
SET end_date = '2026-01-15 23:59:59'::timestamptz 
WHERE id = 'xxx';
```

**Activar/Desactivar:**
```sql
UPDATE calls SET is_active = false WHERE id = 'xxx';
```

---

## 📚 Documentación

### Archivos de referencia

- 📖 `GUIA_ACTIVACION_CONVOCATORIAS.md` - Guía técnica completa
- 📄 `RESUMEN_EJECUTIVO_ACTIVACION.md` - Este documento
- 🗃️ `BD/migrations/005_add_call_activation_control.sql` - Migración SQL
- 🎨 `frontend/src/pages/admin/CallActivationManager.tsx` - Interfaz admin
- 🔧 `backend/src/calls/entities/call.entity.ts` - Entidad actualizada

---

## ✅ Checklist de Despliegue

- [x] Código frontend desplegado (Vercel)
- [x] Código backend desplegado (Railway)
- [ ] Migración SQL ejecutada en Railway
- [ ] Probar activación/desactivación de convocatoria
- [ ] Probar edición de fechas
- [ ] Verificar badge en SimpleFormBuilder
- [ ] Confirmar postulantes no pueden aplicar a convocatorias inactivas

---

## 🎯 Próximos Pasos Recomendados

1. **Ejecutar migración en Railway** (script listo en backend)
2. **Configurar fechas de convocatorias existentes**
3. **Probar flujo completo**: Admin activa → Postulante aplica → Admin desactiva → Postulante bloqueado
4. **Documentar proceso para equipo de fundación**
5. **Considerar automatizaciones** (emails, cron jobs)

---

**Estado:** ✅ IMPLEMENTADO (pendiente migración SQL)  
**Versión:** 1.0.0  
**Fecha:** 25 de noviembre de 2025
