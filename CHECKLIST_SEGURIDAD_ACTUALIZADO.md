# 🔐 Checklist de Seguridad Completo

## ✅ IMPLEMENTADO - Protecciones Activas

### 1. Autenticación y Autorización
- ✅ **Guards globales activados** - Todos los endpoints requieren JWT
- ✅ **JwtAuthGuard** - Valida tokens en cada request
- ✅ **RolesGuard** - Verifica permisos (ADMIN, REVIEWER, APPLICANT)
- ✅ **@Public()** - Endpoints públicos marcados explícitamente
- ✅ **@Roles()** - Control granular por rol
- ✅ **JWT expiration** - 15 min access, 15 días refresh
- ✅ **Argon2** - Hash resistente a GPU cracking

### 2. Rate Limiting
- ✅ Login staff: 5/min
- ✅ Login applicant: 5/min
- ✅ Enter invite: 5/min
- ✅ Validate invite: 5/min
- ✅ Global: 500 requests/15min

### 3. CORS
- ✅ Whitelist estricta (5 dominios)
- ✅ Credentials habilitado
- ❌ **ANTES**: `origin: true` 🔴

### 4. Headers (Helmet)
- ✅ X-Frame-Options
- ✅ X-Content-Type-Options
- ✅ HSTS
- ✅ CSP

### 5. Validación
- ✅ ValidationPipe global
- ✅ whitelist + forbidNonWhitelisted
- ✅ class-validator en DTOs

### 6. SSL/TLS
- ✅ Validación en prod: `rejectUnauthorized: true`
- ✅ Dev: `false`

---

## ⚠️ VULNERABILIDADES CRÍTICAS PENDIENTES

### 🔴 URGENTE - Hoy

#### 1. Credenciales Hardcodeadas (40+ archivos)
```bash
# Solución rápida
mkdir backend/scripts-inseguros
mv backend/*.js backend/scripts-inseguros/
echo "backend/scripts-inseguros/" >> .gitignore
```
Ver: `URGENTE_CREDENCIALES_EXPUESTAS.md`

### 🟡 ALTO - Esta semana

#### 2. CSRF Protection
```typescript
import * as csurf from 'csurf';
app.use(csurf({ cookie: true }));
```

#### 3. SQL Injection Audit
Revisar queries con strings directos:
```typescript
// ❌ INSEGURO
.query(`SELECT * FROM users WHERE id = '${id}'`)

// ✅ SEGURO
.query(`SELECT * FROM users WHERE id = $1`, [id])
```

#### 4. Logging Estructurado
- [ ] Winston/Pino
- [ ] Log intentos fallidos
- [ ] Alertas en tiempo real

---

## 📊 Endpoints Protegidos

### 🔴 Solo ADMIN (4)
- `/api/admin/users`
- `/api/email/templates`
- `/api/email/logs`
- `/api/audit`

### 🟡 ADMIN + REVIEWER (38)
- `/api/calls`
- `/api/applications`
- `/api/applicants`
- `/api/invites`
- `/api/forms`
- `/api/milestones`
- `/api/admin/stats`
- `/api/institutions` (GET)
- `/api/form-submissions`

### 🟢 APPLICANT (4)
- `/api/profile/applicant`
- `/api/calls/:id/form`
- `/api/calls/applicant/...`

### ⚪ Público (8)
- `/api/auth/login`
- `/api/auth/login-staff`
- `/api/auth/refresh`
- `/api/onboarding/validate-invite`
- `/api/public/form`
- `/api/health`

---

## 🧪 Testing

### 1. Sin token
```bash
curl http://localhost:3000/api/institutions
# Esperado: 401
```

### 2. Token inválido
```bash
curl -H "Authorization: Bearer fake" http://localhost:3000/api/institutions
# Esperado: 401
```

### 3. Rol incorrecto
```bash
curl -H "Authorization: Bearer <applicant_token>" \
  http://localhost:3000/api/admin/users
# Esperado: 403
```

### 4. Rate limit
```bash
for i in {1..6}; do curl -X POST http://localhost:3000/api/auth/login \
  -d '{"email":"x","password":"x"}' -H "Content-Type: application/json"; done
# Request 6: 429
```

---

## 📚 OWASP Top 10 Coverage

- [x] A01 - Broken Access Control → ✅ Guards + Roles
- [x] A02 - Crypto Failures → ✅ Argon2 + SSL
- [ ] A03 - Injection → ⚠️ Parcial
- [x] A05 - Security Misconfiguration → ✅ Helmet + CORS
- [x] A07 - Auth Failures → ✅ JWT + Rate limit
- [ ] A08 - Data Integrity → ❌ Pendiente

---

## 🚀 Próximos Pasos

### Esta Semana
1. Cambiar password Railway
2. Mover scripts inseguros
3. CSRF protection
4. SQL audit
5. Logging

### Próxima Semana
1. Penetration testing
2. 2FA para admins
3. Secrets management
4. npm audit fix

---

**Fecha**: 10 dic 2024  
**Estado**: 🟡 BÁSICO IMPLEMENTADO  
**Acción**: Arreglar credenciales hardcodeadas HOY
