# 🔒 Restricción: Una Sola Convocatoria Activa

## 🎯 Problema Resuelto

**Situación:** En un sistema donde los códigos de invitación y formularios están vinculados a una convocatoria específica, tener múltiples convocatorias activas simultáneamente causaría:
- ❌ Confusión sobre qué formularios llenar
- ❌ Códigos de invitación apuntando a convocatorias incorrectas
- ❌ Postulantes aplicando a la convocatoria equivocada

**Solución:** Restricción técnica que **solo permite UNA convocatoria activa a la vez**.

---

## ✅ Cómo Funciona

### Validación en Frontend
Cuando el admin intenta activar una convocatoria:

1. **Sistema verifica** si ya hay otra activa
2. **Si hay una activa:**
   - ❌ Muestra mensaje de error
   - 📢 Indica qué convocatoria está activa
   - 💡 Pide desactivar primero la actual
3. **Si NO hay otra activa:**
   - ✅ Permite activar la nueva
   - 🎉 Muestra mensaje de éxito

### Validación en Backend
Doble capa de seguridad:

1. **Backend verifica** antes de guardar cambios
2. **Si encuentra otra activa:**
   - ❌ Retorna error 400 (Bad Request)
   - 📝 Mensaje: "Solo puede haber una convocatoria activa a la vez"
3. **Si validación pasa:**
   - ✅ Guarda la activación
   - 🔄 Actualiza la base de datos

---

## 🎨 Interfaz Visual

### Alerta de Convocatoria Activa (Verde)
```
┌──────────────────────────────────────────────────────┐
│ ✅ Convocatoria Activa: Becas FCG 2026                │
│                                                       │
│ Esta es la convocatoria actualmente disponible para  │
│ postulantes. Los códigos de invitación y formularios │
│ están vinculados a esta convocatoria.                │
└──────────────────────────────────────────────────────┘
```

### Alerta Sin Convocatoria Activa (Amarillo)
```
┌──────────────────────────────────────────────────────┐
│ ⚠️ No hay convocatoria activa                         │
│                                                       │
│ Los postulantes no pueden aplicar hasta que actives  │
│ una convocatoria. Solo puede haber una convocatoria  │
│ activa a la vez.                                      │
└──────────────────────────────────────────────────────┘
```

### Mensaje de Error al Intentar Activar Segunda
```
❌ Solo puede haber una convocatoria activa a la vez.
   "Becas FCG 2026" ya está activa.
```

---

## 📋 Flujo de Trabajo Típico

### Escenario 1: Cambiar de Convocatoria 2025 → 2026

```
1. Admin entra a /admin/activacion-convocatorias
2. Ve alerta verde: "Becas FCG 2025" está activa
3. Desactiva Becas FCG 2025 (toggle OFF)
4. Activa Becas FCG 2026 (toggle ON)
5. Ve alerta verde: "Becas FCG 2026" está activa
✅ Los códigos nuevos ahora apuntan a 2026
```

### Escenario 2: Intento de Activar Dos Simultáneamente

```
1. Admin ve: "Becas FCG 2025" activa
2. Intenta activar "Becas FCG 2026" sin desactivar 2025
3. ❌ Sistema muestra error:
   "Solo puede haber una convocatoria activa a la vez.
    Becas FCG 2025 ya está activa"
4. Admin debe desactivar 2025 primero
5. Luego puede activar 2026
```

---

## 🔧 Detalles Técnicos

### Frontend Validation
**Archivo:** `frontend/src/pages/admin/CallActivationManager.tsx`

```typescript
const handleToggleActive = async (callId: string, currentValue: boolean) => {
  const newValue = !currentValue;
  
  // Si intenta ACTIVAR, verificar que no haya otra activa
  if (newValue === true) {
    const activeCall = calls.find(c => 
      c.isActive && c.status === "OPEN" && c.id !== callId
    );
    
    if (activeCall) {
      toast.error(
        `Solo puede haber una convocatoria activa a la vez. 
         "${activeCall.name} ${activeCall.year}" ya está activa.`,
        { duration: 5000 }
      );
      return;
    }
  }
  
  // Proceder con la activación...
};
```

### Backend Validation
**Archivo:** `backend/src/calls/calls.service.ts`

```typescript
async updateCall(id: string, body: any) {
  // Validación: Solo puede haber una convocatoria activa a la vez
  if (body.isActive === true) {
    const existingActive = await this.callRepo.findOne({
      where: {
        isActive: true,
        status: CallStatus.OPEN,
      },
    });

    if (existingActive && existingActive.id !== id) {
      throw new BadRequestException(
        `Solo puede haber una convocatoria activa a la vez. 
         "${existingActive.name} ${existingActive.year}" ya está activa. 
         Desactívala primero.`
      );
    }
  }
  
  // Proceder con la actualización...
}
```

---

## 🎯 Beneficios

### Para Administradores
- ✅ **Claridad total:** Siempre saben cuál es LA convocatoria activa
- ✅ **Sin errores:** Imposible activar dos por accidente
- ✅ **Control simple:** Un toggle = una acción clara

### Para el Sistema
- ✅ **Integridad de datos:** Códigos siempre apuntan a convocatoria correcta
- ✅ **Sin conflictos:** Formularios vinculados a convocatoria única
- ✅ **Trazabilidad:** Fácil auditar qué convocatoria estaba activa cuándo

### Para Postulantes
- ✅ **Sin confusión:** Solo ven una convocatoria disponible
- ✅ **Experiencia clara:** Saben exactamente a qué están aplicando
- ✅ **Sin errores:** Imposible aplicar a convocatoria equivocada

---

## 📊 Estado Actual

### Base de Datos
```sql
-- Solo UNA fila puede tener is_active = true Y status = 'OPEN'
SELECT id, name, year, status, is_active
FROM calls
WHERE is_active = true AND status = 'OPEN';

-- Resultado esperado: 0 o 1 fila (NUNCA 2+)
```

### Query de Verificación
```sql
-- Verificar que no hay múltiples activas (debe retornar 0 o 1)
SELECT COUNT(*) as active_count
FROM calls
WHERE is_active = true AND status = 'OPEN';
```

---

## 🚀 Despliegue

### Backend
- **Commit:** `276045e`
- **Mensaje:** "feat: restricción de una sola convocatoria activa"
- **Estado:** ✅ Desplegado en Railway

### Frontend
- **Commit:** `378ccb2`
- **Mensaje:** "feat: restricción de una sola convocatoria activa"
- **Estado:** ✅ Desplegado en Vercel

---

## 💡 Casos de Uso Reales

### Caso 1: Nueva Convocatoria Anual
```
Diciembre 2025:
1. Admin cierra Becas FCG 2025 (toggle OFF)
2. Admin activa Becas FCG 2026 (toggle ON)
✅ Códigos nuevos de enero apuntan a 2026
```

### Caso 2: Convocatoria Especial Mid-Year
```
Junio 2026:
1. Admin desactiva Becas FCG 2026 temporalmente
2. Admin activa "Becas Especiales Julio 2026"
3. Envía códigos para convocatoria especial
4. Termina convocatoria especial
5. Reactiva Becas FCG 2026
✅ Control total del flujo
```

### Caso 3: Testing Antes de Abrir
```
Pre-apertura:
1. Convocatoria 2026 en DRAFT + Inactiva
2. Admin testea internamente
3. Cuando listo: Cambia a OPEN + Activa
✅ Sin riesgo de postulaciones accidentales durante testing
```

---

## 📝 Resumen Ejecutivo

**Pregunta:** ¿Puedo tener dos convocatorias activas simultáneamente?  
**Respuesta:** ❌ No. El sistema **solo permite UNA** convocatoria activa a la vez.

**Razón:** Los códigos de invitación y formularios de postulación están vinculados a LA convocatoria activa. Múltiples activas causarían conflictos y confusión.

**Cómo cambiar:** Desactiva la actual → Activa la nueva

**Protección:** Validación tanto en frontend como backend

---

**Estado:** ✅ IMPLEMENTADO Y OPERACIONAL  
**Fecha:** 25 de noviembre de 2025  
**Versión:** 1.0.0
