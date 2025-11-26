# 🎯 Guía: Invitar Postulantes al Sistema

## 📍 Ubicación
**Panel Admin** → **Invitar Postulante**  
URL: `https://fcgfront.vercel.app/#/admin/invite-applicant`

---

## ✨ ¿Qué hace esta página?

Te permite **crear invitaciones** para postulantes de forma rápida y elegir cómo enviar el código:

1. **Automático**: El sistema envía un email con el código
2. **Manual**: Se genera el código y tú lo copias para enviarlo por WhatsApp, SMS, etc.

---

## 📝 Pasos para invitar un postulante

### 1️⃣ Selecciona la convocatoria
- Usa el selector de convocatorias en el menú lateral
- Debe estar en estado **OPEN** (abierta)

### 2️⃣ Completa el formulario

| Campo | Descripción | Requerido |
|-------|-------------|-----------|
| **Nombre** | Ej: Juan | ✅ Sí |
| **Apellido** | Ej: Pérez | ✅ Sí |
| **Email** | ejemplo@email.com | ✅ Sí |
| **Método de envío** | Automático o Manual | ✅ Sí |

### 3️⃣ Elige el método de envío

#### 🔵 Opción 1: Copiar código (envío manual)
- ✅ **Recomendado** para invitaciones urgentes o personalizadas
- El sistema genera el código instantáneamente
- Aparece una tarjeta con:
  - Código de invitación
  - Datos del postulante
  - Botón **"Copiar mensaje completo"**
- El mensaje copiado incluye:
  ```
  ¡Hola Juan!
  
  Has sido invitado/a a postular a Becas FCG 2026.
  
  Datos de acceso:
  Email: juan@ejemplo.com
  Código: TEST-ABC12345
  
  Entra aquí: https://fcgfront.vercel.app/#/login
  ```

#### 📧 Opción 2: Enviar automáticamente por email
- El sistema envía un correo electrónico profesional con:
  - Saludo personalizado con el nombre
  - Código de invitación destacado
  - Instrucciones de acceso
  - Enlace directo al formulario
- ⚠️ **Importante**: Verifica que el email esté correcto, no se puede reenviar

---

## 🔄 Flujo completo

```
1. Admin selecciona convocatoria
         ↓
2. Completa formulario (nombre, apellido, email)
         ↓
3. Elige método de envío
         ↓
4a. Automático              4b. Manual
    → Email enviado             → Código generado
    → Mensaje de éxito          → Copiar y enviar manual
```

---

## 🎨 Características de la interfaz

### ✅ Estados visuales
- **✅ Verde**: Invitación enviada exitosamente
- **❌ Rojo**: Error en el envío
- **📋 Azul**: Código generado listo para copiar
- **⏳ Gris**: Cargando...

### 🔒 Validaciones
- Email debe ser válido
- Todos los campos son obligatorios
- Convocatoria debe estar seleccionada

### 📋 Funcionalidades extras
- Botón **"Copiar mensaje completo"** con feedback visual
- Auto-limpieza del formulario después de envío exitoso (automático)
- Persistencia del código generado (manual) para poder copiarlo varias veces
- Integración con CallStatusBadge (muestra convocatoria seleccionada)

---

## 🔧 Detalles técnicos

### Backend: `POST /api/invites`

**Request Body:**
```json
{
  "callId": "uuid-convocatoria",
  "firstName": "Juan",
  "lastName": "Pérez",
  "email": "juan@ejemplo.com",
  "sendEmail": true  // false para modo manual
}
```

**Response (modo manual):**
```json
{
  "id": "uuid-invite",
  "callId": "uuid-convocatoria",
  "code": "TEST-ABC12345",
  "invitationCode": "TEST-ABC12345",
  "expiresAt": "2025-12-26T...",
  ...
}
```

### Generación de código
- Formato: `TEST-XXXXXXXX` (8 caracteres alfanuméricos)
- Automático si no se proporciona
- Hash almacenado en DB con Argon2

### Metadata guardada
```json
{
  "meta": {
    "firstName": "Juan",
    "lastName": "Pérez"
  }
}
```

---

## 📊 Ventajas vs invitaciones antiguas

| Aspecto | Sistema Anterior | Sistema Nuevo ✨ |
|---------|------------------|------------------|
| Interfaz | Script manual `create-test-invite.js` | Página web intuitiva |
| Envío de emails | Manual | Automático O Manual |
| Personalización | No | Sí (nombre en email) |
| UX Admin | Terminal | Formulario visual |
| Validaciones | Pocas | Completas |
| Feedback | Console logs | Mensajes visuales |
| Copia rápida | No | Botón copiar todo |

---

## 🚀 Próximas mejoras sugeridas

- [ ] Listado de invitaciones enviadas
- [ ] Reenvío de invitaciones expiradas
- [ ] Templates personalizables de email
- [ ] Invitaciones masivas (CSV upload)
- [ ] Tracking de apertura de emails
- [ ] Recordatorios automáticos

---

## 🔗 Enlaces relacionados

- **Gestión de invitaciones**: `/admin/invites` (lista todas las invitaciones)
- **Postulantes**: `/admin/applicants` (ver quiénes han usado sus códigos)
- **Form Builder**: `/admin/form-builder` (diseñar formulario de postulación)

---

## ✅ Estado actual

- ✅ Frontend desplegado (commit `a8293f2`)
- ✅ Backend desplegado (commit `7baa0dd`)
- ✅ Integración completa con email service
- ✅ Validaciones funcionando
- ✅ Generación automática de códigos
- ✅ Modo manual con copia de mensaje

**Listo para usar en producción** 🎉
