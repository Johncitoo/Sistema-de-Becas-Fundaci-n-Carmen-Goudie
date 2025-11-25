# 🔄 Diagrama de Flujo - Sistema de Invitaciones (Actualizado)

## 📊 Flujo ANTERIOR (Con problemas)

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUJO ANTIGUO (PROBLEMÁTICO)              │
└─────────────────────────────────────────────────────────────┘

1. Admin crea invitación
   └─> DB: invites.code = "ABC123", used_at = NULL
   
2. Postulante ingresa código "ABC123"
   └─> POST /invites/consume { code, email }
   
3. Backend valida código
   ├─> ✅ Código válido
   ├─> ❌ MARCA COMO USADO (used_at = NOW())  <-- PROBLEMA
   ├─> Crea usuario
   ├─> Crea applicant
   └─> Devuelve tokens JWT

4. Postulante puede iniciar sesión
   └─> PERO si no completa formulario:
       └─> ❌ Código YA FUE QUEMADO
       └─> ❌ No puede volver a usarlo
       └─> ❌ No puede pedir uno nuevo

❌ RESULTADO: Postulantes perdían acceso si no completaban el formulario
```

---

## ✅ Flujo NUEVO (Corregido)

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUJO NUEVO (CORRECTO)                    │
└─────────────────────────────────────────────────────────────┘

FASE 1: VALIDACIÓN DE CÓDIGO
──────────────────────────────

1. Admin crea invitación
   ├─> DB: invites.id = "uuid-1"
   ├─> DB: invites.code = "ABC123" (hash)
   ├─> DB: invites.used_at = NULL
   └─> DB: invites.applicant_id = NULL

2. Postulante ingresa código "ABC123" + email
   └─> POST /onboarding/validate-invite { code, email }
   
3. Backend valida código (TRANSACCIÓN)
   ├─> Verificar código existe y no usado
   ├─> Verificar no expirado
   ├─> ✅ CÓDIGO NO SE QUEMA AQUÍ  <-- CLAVE
   │
   ├─> Crear usuario (si no existe)
   │   └─> DB: users.email, role=APPLICANT, password_hash=NULL
   │
   ├─> Crear applicant
   │   ├─> DB: applicants.user_id
   │   ├─> DB: applicants.rut (generado con timestamp+random)
   │   └─> UPDATE invites.applicant_id = applicant.id
   │
   ├─> Crear application
   │   ├─> DB: applications.applicant_id
   │   ├─> DB: applications.call_id (convocatoria activa)
   │   └─> DB: applications.status = 'DRAFT'
   │
   ├─> Generar token de contraseña
   │   ├─> DB: password_tokens.token (32 bytes)
   │   ├─> DB: password_tokens.user_id
   │   └─> DB: password_tokens.expires_at (+24h)
   │
   ├─> Enviar email con Brevo
   │   ├─> Template HTML con link
   │   └─> Link: https://frontend/auth/set-password?token=XXX
   │
   └─> Registrar en audit_logs
       └─> DB: audit_logs.action = 'invite_validated'

4. Backend devuelve success
   └─> { success: true, message: "Revisa tu email" }
   └─> ✅ invites.used_at SIGUE SIENDO NULL


FASE 2: ESTABLECER CONTRASEÑA
──────────────────────────────

5. Postulante revisa email
   └─> Click en link con token

6. Frontend muestra formulario de contraseña
   └─> Validación en cliente:
       ├─> Mínimo 8 caracteres
       ├─> Mayúsculas + minúsculas
       ├─> Números + símbolos
       └─> Confirmación de contraseña

7. Postulante envía nueva contraseña
   └─> POST /onboarding/set-password { token, password }

8. Backend procesa contraseña
   ├─> Validar token no expirado
   ├─> Validar complejidad (IsStrongPassword)
   ├─> Hash con Argon2
   ├─> UPDATE users.password_hash
   ├─> UPDATE password_tokens.used_at
   └─> Registrar en audit_logs
       └─> DB: audit_logs.action = 'password_set'

9. Frontend redirige a login
   └─> Postulante puede iniciar sesión


FASE 3: COMPLETAR FORMULARIO
─────────────────────────────

10. Postulante inicia sesión
    └─> POST /auth/login { email, password }
    └─> Backend devuelve JWT tokens
    └─> Registrar en audit_logs
        └─> DB: audit_logs.action = 'login_success'

11. Postulante navega a formulario
    └─> GET /applications/my-active
    └─> Backend devuelve application en DRAFT

12. Postulante llena formulario
    ├─> PATCH /applications/:id (auto-save)
    └─> DB: applications.academic (JSONB)
    └─> DB: applications.household (JSONB)

13. Postulante envía formulario
    └─> POST /applications/:id/submit

14. Backend procesa submit
    ├─> Validar ownership
    ├─> Validar estado (DRAFT → SUBMITTED)
    ├─> UPDATE applications.status = 'SUBMITTED'
    ├─> INSERT application_status_history
    └─> Registrar en audit_logs
        └─> DB: audit_logs.action = 'form_submitted'

15. Frontend llama a completar invitación
    └─> POST /applications/:id/complete-invite

16. Backend marca código como usado
    ├─> Buscar invitación del usuario
    └─> ✅ UPDATE invites.used_at = NOW()  <-- AQUÍ SE QUEMA
    └─> ✅ Código finalmente marcado como usado


FASE 4: REGENERACIÓN (SI ES NECESARIO)
───────────────────────────────────────

17. Si postulante pierde código ANTES de completar:
    └─> Admin llama: POST /invites/:id/regenerate { newCode }

18. Backend regenera código (TRANSACCIÓN)
    ├─> Buscar invitación original
    ├─> UPDATE invites.code = NULL (invalidar)
    ├─> INSERT nuevo invite
    │   ├─> Mismo call_id
    │   ├─> Mismo institution_id
    │   ├─> Nuevo code (hash)
    │   └─> used_at = NULL
    ├─> Enviar email con nuevo código
    └─> Registrar en audit_logs
        └─> DB: audit_logs.action = 'invite_regenerated'

✅ RESULTADO: Postulante puede completar en múltiples sesiones sin perder acceso
```

---

## 🔐 Puntos de Auditoría

Todos registrados en tabla `audit_logs`:

| Acción | Evento | Usuario | Datos |
|--------|--------|---------|-------|
| `invite_validated` | Código validado | applicant | code, email, ip |
| `password_set` | Contraseña establecida | applicant | user_id |
| `login_success` | Login exitoso | applicant/staff | user_id, role, ip |
| `login_failed` | Login fallido | N/A | email, ip |
| `form_submitted` | Formulario enviado | applicant | application_id |
| `application_status_changed` | Estado cambió | applicant/admin | old_status → new_status |
| `invite_regenerated` | Código regenerado | admin | old_code → new_code |

---

## 🔄 Estados de Invitación

```
┌──────────────┐
│   CREADO     │  invites.code = hash, used_at = NULL, applicant_id = NULL
└──────┬───────┘
       │
       │ POST /onboarding/validate-invite
       │
       ↓
┌──────────────┐
│  VALIDADO    │  invites.applicant_id = uuid, used_at = NULL  <-- NO USADO
└──────┬───────┘
       │
       │ (Postulante puede reintentar, cerrar navegador, etc.)
       │
       │ POST /applications/:id/complete-invite
       │
       ↓
┌──────────────┐
│   USADO      │  invites.used_at = timestamp  <-- QUEMADO
└──────────────┘
```

---

## 📧 Flujo de Emails

### Email 1: Establecer Contraseña
```
Enviado: Después de validar código
Destinatario: email del postulante
Asunto: "Establece tu contraseña - Fundación Carmen Goudie"
Contenido:
  - Link: https://frontend/auth/set-password?token=XXX
  - Token válido por: 24 horas
  - Call to action: "Establecer Contraseña"
```

### Email 2: Código Regenerado
```
Enviado: Cuando admin regenera código
Destinatario: email del postulante
Asunto: "Nuevo código de invitación - Fundación Carmen Goudie"
Contenido:
  - Código nuevo: ABC123
  - Mensaje: "Tu código anterior ha sido reemplazado"
  - Call to action: "Ingresar Código"
```

---

## 🛡️ Puntos de Seguridad

### Validaciones en Backend:
1. ✅ Código no expirado (`invites.expires_at > NOW()`)
2. ✅ Código no usado (`invites.used_at IS NULL`)
3. ✅ Email válido (formato + longitud)
4. ✅ Contraseña fuerte (8+ chars, compleja)
5. ✅ Rate limiting (10 req/seg, 100 req/min)
6. ✅ CORS whitelist
7. ✅ Helmet headers
8. ✅ SQL injection protegido (TypeORM)
9. ✅ Transacciones atómicas
10. ✅ Auditoría completa

---

## 🔍 Queries de Verificación

```sql
-- Verificar código NO usado después de validar
SELECT code, used_at, applicant_id 
FROM invites 
WHERE id = 'uuid-1';
-- Esperado: used_at = NULL, applicant_id = uuid

-- Verificar código USADO después de submit
SELECT code, used_at, applicant_id 
FROM invites 
WHERE id = 'uuid-1';
-- Esperado: used_at = timestamp, applicant_id = uuid

-- Ver auditoría completa de una invitación
SELECT * FROM audit_logs 
WHERE details->>'inviteId' = 'uuid-1' 
ORDER BY timestamp ASC;

-- Ver todos los estados de una aplicación
SELECT * FROM application_status_history 
WHERE application_id = 'app-uuid' 
ORDER BY changed_at ASC;
```

---

**Última actualización:** Diciembre 2024  
**Validado:** ✅ Lógica correcta  
**Testeado:** ⏳ Pendiente testing E2E
