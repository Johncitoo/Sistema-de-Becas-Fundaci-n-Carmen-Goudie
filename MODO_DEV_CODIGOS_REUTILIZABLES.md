# 🔧 Modo Desarrollo - Códigos de Invitación Reutilizables

**Fecha**: 6 de diciembre de 2025  
**Estado**: ✅ ACTIVO - SOLO PARA DESARROLLO

---

## ⚠️ IMPORTANTE

Este archivo documenta las modificaciones realizadas al sistema de códigos de invitación para **facilitar el testing durante el desarrollo**. 

**ESTOS CAMBIOS DEBEN SER REVERTIDOS ANTES DE PASAR A PRODUCCIÓN.**

---

## 📋 Cambios Realizados

### Archivo: `backend/src/onboarding/onboarding.service.ts`

#### 1. **Validación de Expiración (COMENTADA)**

**Líneas ~125-130**

```typescript
// ⚠️ COMENTADO PARA FACILITAR TESTING - DESCOMENTAR EN PRODUCCIÓN
// if (invite.expiresAt && invite.expiresAt < new Date()) {
//   throw new BadRequestException('El código ha expirado');
// }
```

**Qué hace**: Permite usar códigos expirados durante el desarrollo.

---

#### 2. **Validación de Código Ya Usado (COMENTADA)**

**Líneas ~130-136**

```typescript
// ⚠️ COMENTADO PARA FACILITAR TESTING - DESCOMENTAR EN PRODUCCIÓN
// NUEVO: Verificar que el código NO haya sido usado
// if (invite.usedAt || invite.usedByApplicant) {
//   throw new BadRequestException('Este código ya ha sido utilizado...');
// }
```

**Qué hace**: Permite reutilizar el mismo código infinitas veces.

---

#### 3. **Búsqueda de Invitaciones (MODIFICADA)**

**Función**: `findInviteByCode()` - Líneas ~42-60

```typescript
// ⚠️ MODO DEV: Obtener TODAS las invitaciones (incluso las usadas)
// En producción, descomentar la línea de abajo y comentar la siguiente
// const invites = await this.inviteRepo.find({ where: { usedAt: null as any } });
const invites = await this.inviteRepo.find(); // ⚠️ DEV MODE: acepta códigos usados
```

**Qué hace**: Busca códigos en TODAS las invitaciones, no solo las no usadas.

---

#### 4. **Marcado de Código como Usado (DESACTIVADO)**

**Función**: `markInviteAsCompleted()` - Líneas ~445-453

```typescript
async markInviteAsCompleted(inviteId: string): Promise<void> {
  // ⚠️ COMENTADO PARA FACILITAR TESTING - Los códigos nunca se marcan como usados
  // await this.inviteRepo.update(inviteId, {
  //   usedAt: new Date(),
  // });
  this.logger.log(`⚠️ [DEV MODE] Invitación NO marcada como usada: ${inviteId}`);
}
```

**Qué hace**: Nunca marca los códigos como usados en la base de datos.

---

## 🎯 Beneficios para Testing

Con estos cambios, durante el desarrollo puedes:

1. ✅ **Reutilizar el mismo código** múltiples veces sin necesidad de crear nuevos
2. ✅ **Usar códigos expirados** sin problemas
3. ✅ **Probar flujos repetidamente** con el mismo código
4. ✅ **No preocuparte por limpiar la BD** constantemente

---

## 🚨 Antes de Producción - Checklist

Antes de desplegar a producción, **DEBES** revertir estos cambios:

### Paso 1: Descomentar Validación de Expiración

```typescript
// Cambiar de:
// if (invite.expiresAt && invite.expiresAt < new Date()) {
//   throw new BadRequestException('El código ha expirado');
// }

// A:
if (invite.expiresAt && invite.expiresAt < new Date()) {
  throw new BadRequestException('El código ha expirado');
}
```

### Paso 2: Descomentar Validación de Código Usado

```typescript
// Cambiar de:
// if (invite.usedAt || invite.usedByApplicant) {
//   throw new BadRequestException('Este código ya ha sido utilizado...');
// }

// A:
if (invite.usedAt || invite.usedByApplicant) {
  throw new BadRequestException('Este código ya ha sido utilizado. Si necesitas acceso nuevamente, contacta con el administrador para obtener un nuevo código.');
}
```

### Paso 3: Restaurar Búsqueda de Invitaciones

```typescript
// Cambiar de:
const invites = await this.inviteRepo.find();

// A:
const invites = await this.inviteRepo.find({
  where: { usedAt: null as any },
});
```

### Paso 4: Reactivar Marcado de Código Usado

```typescript
// Cambiar de:
async markInviteAsCompleted(inviteId: string): Promise<void> {
  // await this.inviteRepo.update(inviteId, { usedAt: new Date() });
  this.logger.log(`⚠️ [DEV MODE] Invitación NO marcada como usada: ${inviteId}`);
}

// A:
async markInviteAsCompleted(inviteId: string): Promise<void> {
  await this.inviteRepo.update(inviteId, {
    usedAt: new Date(),
  });
  this.logger.log(`Invitación marcada como completada: ${inviteId}`);
}
```

---

## 🔍 Cómo Verificar el Estado Actual

### Verificar si está en Modo DEV

Busca en el archivo `backend/src/onboarding/onboarding.service.ts` la cadena:

```bash
# Windows PowerShell
Select-String -Path "backend\src\onboarding\onboarding.service.ts" -Pattern "DEV MODE"

# Resultado esperado en DEV:
# Línea X: // ⚠️ DEV MODE: acepta códigos usados
# Línea Y: this.logger.log(`⚠️ [DEV MODE] Invitación NO marcada como usada...`)
```

Si encuentras estas líneas, **estás en modo desarrollo**.

### Verificar si está Listo para Producción

Si NO encuentras "DEV MODE" y todas las validaciones están descomentadas, el sistema está listo para producción.

---

## 📊 Testing Durante Desarrollo

### Ejemplo de Flujo de Testing

```bash
# 1. Crear un código de prueba
POST /api/invites
{
  "callId": "uuid-de-convocatoria",
  "code": "TEST123",
  "ttlDays": 30,
  "email": "test@example.com"
}

# 2. Usar el código múltiples veces
POST /api/onboarding/validate-invite
{
  "code": "TEST123",
  "email": "test@example.com"
}
# ✅ Funciona la primera vez

POST /api/onboarding/validate-invite
{
  "code": "TEST123",
  "email": "otro@example.com"
}
# ✅ Funciona de nuevo con el mismo código (modo DEV)
# ❌ En producción fallaría con "código ya utilizado"
```

---

## 🎓 Notas Adicionales

### Por Qué Es Necesario en Desarrollo

- **Testing de formularios**: Necesitas completar formularios múltiples veces para probar validaciones
- **Testing de flujos**: Probar diferentes escenarios con el mismo código
- **Debugging**: Reproducir bugs sin necesidad de crear códigos nuevos cada vez
- **Demos**: Mostrar el sistema sin preocuparte por códigos quemados

### Por Qué Debe Revertirse en Producción

- **Seguridad**: Un código usado no debería permitir acceso nuevamente
- **Control de acceso**: Cada código debería dar acceso a UN solo postulante
- **Auditoría**: Necesitas saber cuándo y por quién se usó cada código
- **Prevención de fraude**: Evita que códigos filtrados se usen múltiples veces

---

## 🔗 Archivos Relacionados

- `backend/src/onboarding/onboarding.service.ts` - Archivo modificado
- `backend/src/onboarding/entities/invite.entity.ts` - Entidad de invitación
- `backend/src/onboarding/invites.controller.ts` - Controller de invitaciones

---

## 📞 Soporte

Si tienes dudas sobre estos cambios o cómo revertirlos, revisa:
1. Los comentarios `⚠️ DEV MODE` en el código
2. Los comentarios `⚠️ COMENTADO PARA FACILITAR TESTING`
3. Este documento

**Última actualización**: 6 de diciembre de 2025
