# 🎯 Sistema de Invitación Integrado en Lista de Postulantes

## ✅ ¿Qué se implementó?

Agregué un **botón "Invitar"** directamente en cada fila de la tabla de postulantes, con las dos opciones que pediste:

1. **📧 Envío Automático**: Envía el email directamente por la API
2. **📋 Envío Manual**: Muestra el asunto, destinatario y cuerpo del mensaje para que copies

Además, después de invitar, aparece un **indicador visual** de que ya fue invitado.

---

## 📍 Ubicación

**Panel Admin** → **Postulantes** (sidebar)  
URL: `https://fcgfront.vercel.app/#/admin/applicants`

---

## 🎨 Interfaz Visual

### Tabla de Postulantes con Botón "Invitar"

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Nombre          RUT            Correo          Teléfono  Escuela  Invitación│
├────────────────────────────────────────────────────────────────────────────┤
│ Juan Pérez      12345678-9     juan@mail.com   +569...   —       [Invitar] │
│ María González  98765432-1     maria@mail.com  +569...   —       ✓ Invitado│
│ Pedro Ramírez   11223344-5     pedro@mail.com  +569...   —       [Invitar] │
└────────────────────────────────────────────────────────────────────────────┘
```

- **Botón azul "Invitar"**: Aparece si no ha sido invitado
- **✓ Invitado (verde)**: Aparece después de enviar invitación con el método usado

---

## 🔄 Flujo Completo

### 1️⃣ Click en "Invitar"

```
┌─────────────────────────────────────────────────┐
│ Invitar a Juan Pérez                        [X] │
├─────────────────────────────────────────────────┤
│                                                 │
│ Email: juan@mail.com                            │
│ Convocatoria: Becas FCG 2026                    │
│                                                 │
│ ¿Cómo deseas enviar la invitación?              │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ 📧 Enviar automáticamente por email         │ │
│ │ El sistema enviará un correo con el código  │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ 📋 Obtener cuerpo del mensaje (manual)      │ │
│ │ Se generará el código y verás el contenido  │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

### 2️⃣ Opción A: Envío Automático

**Click en "Enviar automáticamente"** →

```
┌─────────────────────────────────────────────────┐
│ Invitar a Juan Pérez                        [X] │
├─────────────────────────────────────────────────┤
│                                                 │
│ ✅ ¡Mensaje enviado!                            │
│                                                 │
│ El correo con el código de invitación ha sido  │
│ enviado a juan@mail.com                         │
│                                                 │
│                              [Cerrar]           │
└─────────────────────────────────────────────────┘
```

**Resultado en la tabla**:
```
│ Juan Pérez  12345678-9  juan@mail.com  +569...  —  ✓ Invitado (Email) │
```

---

### 2️⃣ Opción B: Envío Manual

**Click en "Obtener cuerpo del mensaje"** →

```
┌─────────────────────────────────────────────────┐
│ Invitar a Juan Pérez                        [X] │
├─────────────────────────────────────────────────┤
│                                                 │
│ ✅ Código generado                              │
│ Copia el siguiente contenido y envíalo manual  │
│                                                 │
│ ┌───────────────────────────────────────────┐   │
│ │ Asunto del correo              [Copiar]   │   │
│ │ ┌─────────────────────────────────────┐   │   │
│ │ │ Invitación para postular - Becas... │   │   │
│ │ └─────────────────────────────────────┘   │   │
│ └───────────────────────────────────────────┘   │
│                                                 │
│ ┌───────────────────────────────────────────┐   │
│ │ Correo del destinatario        [Copiar]   │   │
│ │ ┌─────────────────────────────────────┐   │   │
│ │ │ juan@mail.com                       │   │   │
│ │ └─────────────────────────────────────┘   │   │
│ └───────────────────────────────────────────┘   │
│                                                 │
│ ┌───────────────────────────────────────────┐   │
│ │ Cuerpo del mensaje             [Copiar]   │   │
│ │ ┌─────────────────────────────────────┐   │   │
│ │ │ ¡Hola Juan Pérez!                   │   │   │
│ │ │                                     │   │   │
│ │ │ Has sido invitado/a a postular...   │   │   │
│ │ │                                     │   │   │
│ │ │ Datos de acceso:                    │   │   │
│ │ │ Email: juan@mail.com                │   │   │
│ │ │ Código: TEST-ABC12345               │   │   │
│ │ │                                     │   │   │
│ │ │ Para postular, entra a: https://... │   │   │
│ │ └─────────────────────────────────────┘   │   │
│ └───────────────────────────────────────────┘   │
│                                                 │
│ [Copiar todo (asunto + cuerpo)]                 │
│                                                 │
│                              [Cerrar]           │
└─────────────────────────────────────────────────┘
```

**Resultado en la tabla**:
```
│ Juan Pérez  12345678-9  juan@mail.com  +569...  —  ✓ Invitado (Manual) │
```

---

## 📧 Contenido del Mensaje (Modo Manual)

### Asunto:
```
Invitación para postular - Becas FCG 2026
```

### Destinatario:
```
juan@mail.com
```

### Cuerpo:
```
¡Hola Juan Pérez!

Has sido invitado/a a postular a Becas FCG 2026 de la Fundación Carmen Goudie.

Datos de acceso:
Email: juan@mail.com
Código: TEST-ABC12345

Para postular, entra a: https://fcgfront.vercel.app/#/login

Instrucciones:
1. Ingresa al portal de postulaciones
2. Introduce tu código de invitación
3. Crea tu contraseña
4. Completa el formulario

¡Te esperamos!

Fundación Carmen Goudie
```

---

## ✨ Características

### ✅ Validaciones
- Verifica que haya convocatoria seleccionada
- Valida que el postulante tenga email
- Muestra errores claros si algo falla

### 📋 Botones de Copiar
En modo manual:
- **Copiar** asunto individualmente
- **Copiar** email del destinatario
- **Copiar** cuerpo del mensaje
- **Copiar todo**: Asunto + cuerpo juntos

### 🎨 Indicadores Visuales

| Estado | Icono | Color | Texto |
|--------|-------|-------|-------|
| No invitado | Botón | Azul | "Invitar" |
| Invitado (Email) | ✓ | Verde | "Invitado (Email)" |
| Invitado (Manual) | ✓ | Verde | "Invitado (Manual)" |

### 🔄 Persistencia por Sesión
- Los estados de "Ya invitado" se mantienen mientras estés en la página
- Se resetean al recargar (para poder re-invitar si es necesario)

---

## 🎯 Ventajas vs Sistema Anterior

| Aspecto | Antes | Ahora ✨ |
|---------|-------|----------|
| **Ubicación** | Página separada | En la lista de postulantes |
| **Contexto** | Necesitas buscar al postulante | Lo ves directamente |
| **Workflow** | 1. Ir a invitar<br>2. Llenar datos<br>3. Enviar | 1. Click "Invitar"<br>2. Elegir método<br>3. Listo |
| **Tracking** | Sin indicador | ✓ "Ya invitado" visible |
| **Velocidad** | 3 pasos | 2 clicks |

---

## 🔧 Detalles Técnicos

### Estado Local (React)
```typescript
// Modal
const [inviteModalOpen, setInviteModalOpen] = useState(false)
const [selectedApplicant, setSelectedApplicant] = useState<ApplicantRow | null>(null)

// Tracking de invitaciones
const [inviteStatuses, setInviteStatuses] = useState<InviteStatus>({})
// InviteStatus = { [applicantId]: { invited: bool, method: 'auto'|'manual', timestamp } }

// Modo manual
const [generatedCode, setGeneratedCode] = useState<string | null>(null)
const [emailSubject, setEmailSubject] = useState('')
const [emailBody, setEmailBody] = useState('')
```

### Endpoints Utilizados
```typescript
// POST /api/invites
{
  callId: string,
  firstName: string,
  lastName: string,
  email: string,
  sendEmail: boolean  // true = automático, false = manual
}
```

### Personalización del Mensaje
```typescript
const name = firstName && lastName 
  ? `${firstName} ${lastName}` 
  : fullName || 'Postulante'

const subject = `Invitación para postular - ${callName}`

const body = `¡Hola ${name}!

Has sido invitado/a a postular a ${callName}...

Código: ${code}
...`
```

---

## 📊 Casos de Uso

### Caso 1: Invitación Urgente
**Escenario**: Necesitas invitar rápido a un postulante  
**Solución**: Click "Invitar" → "Automático" → ✅ Email enviado en 2 segundos

### Caso 2: Envío por WhatsApp
**Escenario**: Prefieres enviar por WhatsApp para asegurar que lo vea  
**Solución**: Click "Invitar" → "Manual" → Copiar cuerpo → Pegar en WhatsApp → ✅

### Caso 3: Batch de Invitaciones
**Escenario**: Tienes 10 postulantes para invitar  
**Solución**: Recorre la lista, click "Invitar" en cada uno, elige método, listo. Los indicadores ✓ te muestran a quién ya invitaste.

---

## 🚀 Próximas Mejoras Sugeridas

- [ ] **Persistir estados** en localStorage (mantener "Ya invitado" entre sesiones)
- [ ] **Filtro** para ver solo "Invitados" o "No invitados"
- [ ] **Invitación masiva** (checkbox múltiple + enviar a todos)
- [ ] **Ver código generado** después (consultar invitación existente)
- [ ] **Re-enviar** invitación (para códigos expirados)
- [ ] **Historial** de invitaciones por postulante

---

## ✅ Estado Actual

- ✅ **Frontend desplegado** (commit `f898c9c`)
- ✅ **Backend funcionando** (usa endpoint de commit `7baa0dd`)
- ✅ **Integración completa** con CallContext
- ✅ **Tabla con columna** "Invitación"
- ✅ **Modal con dos opciones**
- ✅ **Indicadores visuales** funcionando
- ✅ **Botones de copiar** con feedback

**LISTO PARA USAR** 🎉

---

## 🧪 Cómo Probar

1. **Ir a**: https://fcgfront.vercel.app/#/admin/applicants
2. **Login**: john@example.com / admin123
3. **Seleccionar** convocatoria "Becas FCG 2026" (menú lateral)
4. **Buscar** un postulante en la tabla
5. **Click** en botón "Invitar"
6. **Probar** ambos modos:
   - **Automático**: Ve el mensaje "¡Mensaje enviado!"
   - **Manual**: Copia el asunto, email y cuerpo

---

## 📸 Screenshots (Descripción)

### Vista de Lista
- Tabla con columna adicional "Invitación"
- Botón azul "Invitar" en cada fila
- Después de invitar: ✓ verde "Invitado (Email/Manual)"

### Modal - Elección de Método
- Header con nombre del postulante
- Dos botones grandes con íconos
- Email y convocatoria mostrados

### Modal - Éxito Automático
- Checkmark verde
- Mensaje de confirmación
- Email del destinatario destacado

### Modal - Código Manual
- Sección para asunto (con botón copiar)
- Sección para email destinatario (con botón copiar)
- Sección para cuerpo (con botón copiar)
- Botón "Copiar todo" al final

---

¡Exactamente lo que pediste! 🎯
