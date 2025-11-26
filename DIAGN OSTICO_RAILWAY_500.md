# 🚨 DIAGNÓSTICO: Error 500 Persistente en Railway

## ✅ LO QUE FUNCIONA

1. **Backend responde** → `GET /api` retorna 200 ✅
2. **Código compila localmente** → `npm run build` exitoso ✅
3. **Simulación local exitosa** → Hash verification funciona ✅
4. **Base de datos limpia** → No hay conflictos ni datos duplicados ✅
5. **Commits pusheados** → Todos los cambios en GitHub ✅

## ❌ PROBLEMA

`POST /api/auth/enter-invite` con código válido → **500 Internal Server Error**

## 🔍 POSIBLES CAUSAS

### 1. **Railway Cache no Limpiado**
Railway podría estar usando una versión cacheada del build anterior.

**Solución:**
- Accede al dashboard de Railway
- Ve al proyecto `fcgback-production`
- Busca "Redeploy" o "Restart"
- Forzar un redeploy limpio

### 2. **Variables de Entorno Faltantes**
El código puede estar fallando porque falta alguna variable en Railway.

**Verificar en Railway:**
```
AUTH_JWT_SECRET
REFRESH_TOKEN_PEPPER
REFRESH_TOKEN_TTL_DAYS
DATABASE_URL
FRONTEND_URL (para CORS y emails)
SMTP_* (para envío de emails)
```

### 3. **Error en Validación de DTO**
El decorador `@IsOptional()` debe ir ANTES de `@IsEmail()`.

**Estado actual (commit 138b155):**
```typescript
@IsOptional() // ✅ CORRECTO - está primero
@IsEmail()
email?: string;
```

### 4. **Error de Runtime en EmailService**
El envío de email podría estar fallando y causando el 500.

**Verificar:** ¿Están configuradas las variables SMTP en Railway?

## 📋 COMMITS RECIENTES

```
9cd2d26 - feat: envío automático de email al completar formulario
138b155 - fix: orden correcto de decoradores en ValidateInviteDto
afac21d - chore: forzar redeploy de Railway para aplicar cambios
86fc52d - fix: permitir login con código sin email
```

## 🧪 PRUEBAS REALIZADAS

1. ✅ Hash de código válido → `argon2.verify()` retorna `true`
2. ✅ Invite existe en BD → ID: `12a3da4a-0250-4aa1-b4d8-a133a5385d24`
3. ✅ Meta tiene email → `{ testEmail: "postulante.prueba@test.cl" }`
4. ✅ No hay usuarios duplicados en BD
5. ✅ Simulación de flujo completo exitosa localmente

## 🎯 ACCIÓN REQUERIDA

**NECESITAS ACCEDER AL DASHBOARD DE RAILWAY Y REVISAR LOS LOGS:**

1. Ve a: https://railway.app/
2. Selecciona proyecto: `fcgback-production`
3. Pestaña "Deployments"
4. Click en el deploy más reciente
5. Ver "Logs" para encontrar el error exacto

**Busca en los logs:**
- Stack trace del error 500
- Mensaje de error específico
- Línea de código que está fallando

## 🔧 WORKAROUND TEMPORAL

Mientras se resuelve el problema de Railway, puedes:

1. **Ejecutar backend localmente:**
   ```bash
   cd backend
   npm run start:dev
   ```

2. **Actualizar frontend para usar localhost:**
   ```typescript
   // frontend/src/config.ts
   export const API_URL = 'http://localhost:3000/api'
   ```

3. **Probar el flujo completo en local**

## 📞 SIGUIENTE PASO

**Por favor comparte los logs de Railway para poder diagnosticar el problema exacto.**

Sin los logs, no podemos determinar si es:
- Error de validación
- Error de base de datos
- Error de SMTP/Email
- Error de configuración

---

**Códigos de prueba disponibles:**
- `TEST-SCU7LNOB`
- `TEST-BHY8V0MA`

Ambos con email: `postulante.prueba@test.cl`
