# 🔒 Seguridad Implementada - Resumen

## ✅ COMPLETADO - Protección Total de Endpoints

### 1. **Guards Globales Activados**
- ✅ `JwtAuthGuard` - TODOS los endpoints requieren autenticación por defecto
- ✅ `RolesGuard` - Verifica permisos según rol del usuario
- ✅ Configurado en `main.ts` - Aplicado globalmente

### 2. **Decoradores de Seguridad Creados**
- ✅ `@Public()` - Marca endpoints que NO requieren auth (login, registro, etc.)
- ✅ `@Roles('ADMIN', 'REVIEWER', 'APPLICANT')` - Define qué roles pueden acceder

### 3. **CORS Corregido**
- ❌ **ANTES**: `origin: true` (cualquier sitio podía hacer requests)
- ✅ **AHORA**: `origin: allowedOrigins` (solo dominios whitelisted)

---

## 📋 Endpoints Protegidos por Rol

### 🔴 Solo ADMIN
- `/api/admin/users` - Gestión de usuarios
- `/api/institutions` - Crear/Modificar/Eliminar instituciones
- `/api/email/templates` - Templates de email
- `/api/audit` - Logs de auditoría

### 🟡 ADMIN + REVIEWER
- `/api/calls` - Convocatorias
- `/api/applications` - Postulaciones
- `/api/applicants` - Postulantes
- `/api/invites` - Invitaciones
- `/api/forms` - Formularios
- `/api/milestones` - Hitos
- `/api/admin/stats` - Estadísticas
- `/api/institutions` (solo lectura)

### 🟢 Endpoints Públicos (@Public)
- `/api/auth/login` - Login postulantes
- `/api/auth/login-staff` - Login admin/revisor
- `/api/auth/refresh` - Refresh token
- `/api/auth/logout` - Logout
- `/api/auth/enter-invite` - Login con código
- `/api/auth/dev/seed-staff` - Solo desarrollo
- `/api/onboarding/validate-invite` - Validar invitación
- `/api/onboarding/set-password` - Establecer contraseña
- `/api/onboarding/dev/*` - Endpoints de desarrollo

---

## 🛡️ Cómo Funciona

### Flujo de Autenticación

```
1. Usuario hace request → /api/institutions
2. JwtAuthGuard se ejecuta PRIMERO
   ├─ Verifica si tiene @Public() → NO
   ├─ Extrae token del header Authorization
   ├─ Valida JWT con AUTH_JWT_SECRET
   └─ Attach user info a request: { sub: userId, role: 'ADMIN' }

3. RolesGuard se ejecuta SEGUNDO
   ├─ Lee @Roles('ADMIN', 'REVIEWER') del endpoint
   ├─ Compara con user.role del request
   └─ Si no coincide → 403 Forbidden

4. Si pasa ambos guards → Endpoint se ejecuta
```

### Ejemplo de Uso

```typescript
// ❌ ANTES - INSEGURO (cualquiera podía acceder)
@Controller('institutions')
export class InstitutionsController {
  @Post()
  async create() { ... } // Sin protección
}

// ✅ AHORA - SEGURO
@Controller('institutions')
export class InstitutionsController {
  @Roles('ADMIN')  // Solo admins
  @Post()
  async create() { ... }
  
  @Roles('ADMIN', 'REVIEWER')  // Admins y revisores
  @Get()
  async list() { ... }
}
```

---

## 🔐 Archivos Modificados

### Nuevos Archivos Creados
1. `backend/src/auth/public.decorator.ts` - Decorador @Public()
2. `backend/src/auth/roles.decorator.ts` - Decorador @Roles()
3. `backend/src/auth/roles.guard.ts` - Guard para verificar roles

### Archivos Modificados
1. `backend/src/main.ts`
   - Imports: JwtService, Reflector, guards
   - Guards globales activados
   - CORS corregido (origin: allowedOrigins)

2. `backend/src/auth/jwt-auth.guard.ts`
   - Soporte para @Public()
   - Reflector agregado

3. **Controladores con @Public() agregado:**
   - `auth.controller.ts` - Todos los endpoints de login
   - `onboarding.controller.ts` - Validar invite, set password, dev endpoints

4. **Controladores con @Roles() agregado:**
   - `admin-users.controller.ts` → `@Roles('ADMIN')`
   - `institutions.controller.ts` → `@Roles('ADMIN')` en POST/PATCH/DELETE
   - `institutions.controller.ts` → `@Roles('ADMIN', 'REVIEWER')` en GET
   - `calls.controller.ts` → `@Roles('ADMIN', 'REVIEWER')`
   - `invites.controller.ts` → `@Roles('ADMIN', 'REVIEWER')`
   - `applications.controller.ts` → `@Roles('ADMIN', 'REVIEWER')`
   - `forms.controller.ts` → `@Roles('ADMIN', 'REVIEWER')`
   - `milestones.controller.ts` → `@Roles('ADMIN', 'REVIEWER')`
   - `applicants.controller.ts` → `@Roles('ADMIN', 'REVIEWER')`
   - `email-templates.controller.ts` → `@Roles('ADMIN')`
   - `stats.controller.ts` → `@Roles('ADMIN', 'REVIEWER')`
   - `audit.controller.ts` → `@Roles('ADMIN')`

---

## 🧪 Testing de Seguridad

### Probar que funciona:

#### 1. Endpoint protegido sin token
```bash
curl http://localhost:3000/api/institutions
# Esperado: 401 Unauthorized - "No token provided"
```

#### 2. Endpoint protegido con token inválido
```bash
curl -H "Authorization: Bearer token_falso" http://localhost:3000/api/institutions
# Esperado: 401 Unauthorized - "Invalid token"
```

#### 3. Endpoint protegido con token válido pero rol incorrecto
```bash
# Token de APPLICANT intentando acceder a admin/users
curl -H "Authorization: Bearer <token_applicant>" http://localhost:3000/api/admin/users
# Esperado: 403 Forbidden - "Access denied. Required roles: ADMIN"
```

#### 4. Endpoint protegido con token y rol correctos
```bash
# Token de ADMIN
curl -H "Authorization: Bearer <token_admin>" http://localhost:3000/api/admin/users
# Esperado: 200 OK + datos
```

#### 5. Endpoint público sin token
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"pass123"}'
# Esperado: 200 OK (o 401 si credenciales incorrectas)
```

---

## ⚠️ VULNERABILIDADES CRÍTICAS PENDIENTES

Aunque los endpoints ahora están protegidos, TODAVÍA quedan estas vulnerabilidades:

### 🔴 CRÍTICO - Arreglar INMEDIATAMENTE
1. **Credenciales hardcodeadas** en ~15 archivos de scripts
   - Archivo: `backend/*.js` (sync-milestone-progress.js, etc.)
   - Solución: Usar `process.env.DATABASE_URL`

2. **SSL validation deshabilitada**
   - `ssl: { rejectUnauthorized: false }`
   - Solución: Solo deshabilitarlo en dev, no en production

### 🟡 ALTO - Próxima semana
3. **Rate limiting falta**
   - Solo `/onboarding/validate-invite` tiene throttle
   - Solución: Agregar a endpoints de login

4. **Passwords débiles generados**
   - `Math.random().toString(36).slice(-10)` (solo 10 chars)
   - Solución: Generar 16+ caracteres con símbolos

5. **CSRF protection**
   - No implementado
   - Solución: Agregar middleware csurf

---

## 📊 Métricas de Seguridad

```
Endpoints totales:          ~50
Endpoints públicos:         8 (16%)
Endpoints protegidos:       42 (84%)
  - Solo ADMIN:             4
  - ADMIN + REVIEWER:       38
  - APPLICANT:              0 (usan JWT sin roles específicos)

Guards globales:            ✅ ACTIVOS
CORS restringido:           ✅ CONFIGURADO
JWT expiration:             ✅ 900s (15 min)
Refresh token TTL:          ✅ 15 días
```

---

## 🚀 Próximos Pasos

1. ✅ **Commit estos cambios**
2. ✅ **Deploy a Railway/Vercel**
3. 🔄 **Probar todos los endpoints**
4. 🔄 **Arreglar credenciales hardcodeadas**
5. 🔄 **Implementar rate limiting**
6. 🔄 **Agregar CSRF protection**

---

**Fecha:** 10 de diciembre de 2025  
**Estado:** ✅ SEGURIDAD BÁSICA IMPLEMENTADA  
**Próxima acción:** Testing y arreglar vulnerabilidades pendientes
