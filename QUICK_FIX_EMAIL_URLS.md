# 🔧 FIX: URLs de Emails Corregidas

## ❌ Problema
Los emails enviados tenían enlaces apuntando a `localhost:5173` en vez de la URL de producción.

## ✅ Solución Aplicada

### 1. Código corregido (commit `f3f8888`)
```typescript
// Antes:
const baseUrl = this.config.get<string>('FRONTEND_URL') || 'http://localhost:5173';
const applyUrl = `${baseUrl}/apply`;

// Ahora:
const baseUrl = this.config.get<string>('FRONTEND_URL') || 'https://fcgfront.vercel.app';
const applyUrl = `${baseUrl}/#/login`;
```

### 2. Cambios aplicados
- ✅ URL default cambiada a `https://fcgfront.vercel.app`
- ✅ Ruta de invitación: `/#/login` (con hash para React Router)
- ✅ Ruta de password reset: `/#/set-password?token=...`
- ✅ `.env.example` actualizado

---

## ⚠️ ACCIÓN REQUERIDA: Actualizar Variable en Railway

### Paso 1: Ir a Railway
1. Ve a: https://railway.app/
2. Login con tu cuenta
3. Selecciona el proyecto del backend

### Paso 2: Configurar Variable de Entorno
1. Click en **"Variables"** en el menú lateral
2. Busca o agrega: `FRONTEND_URL`
3. Valor: `https://fcgfront.vercel.app`
4. Click **"Save"** o **"Add Variable"**

### Paso 3: Redeploy (si es necesario)
- Railway debería hacer redeploy automáticamente
- Si no, click en **"Deploy"** manualmente

---

## 🧪 Cómo Verificar

### Opción 1: Probar email de invitación
1. Ir a `/admin/applicants`
2. Click "Invitar" en un postulante
3. Elegir "Enviar automáticamente"
4. Revisar el email recibido
5. ✅ El botón "Iniciar Postulación" debe apuntar a: `https://fcgfront.vercel.app/#/login`

### Opción 2: Ver logs de Railway
1. En Railway, ve a **"Deployments"**
2. Click en el último deployment
3. Ve a **"Logs"**
4. Busca: `Email enviado exitosamente`
5. Verifica que no haya errores

---

## 📧 URLs Correctas

| Tipo de Email | URL Correcta |
|---------------|--------------|
| **Invitación** | `https://fcgfront.vercel.app/#/login` |
| **Password Reset** | `https://fcgfront.vercel.app/#/set-password?token=...` |

---

## 🔍 Detalles Técnicos

### Código corregido en `email.service.ts`

**Línea 69 - sendPasswordSetEmail**:
```typescript
const baseUrl = this.config.get<string>('FRONTEND_URL') || 'https://fcgfront.vercel.app';
const setPasswordUrl = `${baseUrl}/#/set-password?token=${token}`;
```

**Línea 128 - sendInitialInviteEmail**:
```typescript
const baseUrl = this.config.get<string>('FRONTEND_URL') || 'https://fcgfront.vercel.app';
const applyUrl = `${baseUrl}/#/login`;
```

### ¿Por qué `/#/` con hash?
React Router en modo hash usa `/#/ruta` en vez de `/ruta` para compatibilidad con hosting estático.

---

## ✅ Estado Actual

- ✅ **Código corregido**: Commit `f3f8888` en GitHub
- ✅ **Backend compilado**: Sin errores
- ⏳ **Railway**: Necesita variable `FRONTEND_URL` actualizada
- ⏳ **Redeploy**: Automático después de actualizar variable

---

## 📝 Nota Importante

**Si ya configuraste `FRONTEND_URL` en Railway**, verifica que el valor sea:
```
https://fcgfront.vercel.app
```

**Sin** `/` al final y **sin** `/#/` al final.

El código ya agrega el `/#/login` automáticamente.

---

## 🎯 Próximo Email de Prueba

Después de actualizar la variable en Railway:

1. Espera 1-2 minutos al redeploy
2. Envía un email de prueba de invitación
3. Verifica que el botón apunte correctamente
4. ✅ Confirma que funciona

---

**Railway debería hacer redeploy automáticamente** cuando cambies la variable. Si no lo hace, haz click en "Deploy" manualmente.
