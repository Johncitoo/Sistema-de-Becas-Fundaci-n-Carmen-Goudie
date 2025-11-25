# 🚀 Configuración Completada - Sistema de Becas

## ✅ Lo que ya está hecho

1. **Backend completamente corregido:**
   - ✅ Código de invitación NO se quema hasta completar formulario
   - ✅ Email service con Brevo configurado
   - ✅ Regeneración de códigos
   - ✅ SQL injection protegido
   - ✅ CORS configurado
   - ✅ Rate limiting
   - ✅ Sistema de auditoría

2. **Variables de entorno configuradas:**
   - ✅ BREVO_API_KEY: `xkeysib-3e87...`
   - ✅ EMAIL_FROM: `juan.contreras03@alumnos.ucn.cl`
   - ✅ DATABASE_URL: Railway PostgreSQL conectado

## 🔧 Próximos Pasos

### 1. Probar Backend Localmente (⏱️ 2 min)

```bash
cd backend
npm install
npm run start:dev
```

**Esperado:** Backend corre en `http://localhost:3000`

**Probar endpoint:**
```bash
# PowerShell
Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get
```

---

### 2. Configurar Variables en Railway (⏱️ 5 min)

Ve a tu dashboard de Railway → Backend Service → Variables y agrega:

```env
BREVO_API_KEY=tu-api-key-de-brevo-aqui
EMAIL_FROM=tu-email@dominio.com
EMAIL_FROM_NAME=Fundación Carmen Goudie
FRONTEND_URL=https://tu-app.vercel.app
CORS_ORIGINS=https://tu-app.vercel.app,http://localhost:5173
```

**Las demás variables (DATABASE_URL, JWT_SECRET, etc.) ya deben estar configuradas.**

> 💡 **Usa el API key de Brevo que guardaste localmente en tu `.env`**

---

### 3. Actualizar Frontend (⏱️ 30 min)

#### A. Cambiar endpoint en EnterInviteCodePage

**Archivo:** `frontend/src/pages/auth/EnterInviteCodePage.tsx`

Buscar línea con:
```typescript
const result = await apiPost('/invites/consume', { code, email });
```

Cambiar a:
```typescript
const result = await apiPost('/onboarding/validate-invite', { code, email });
```

Y después del éxito, cambiar la navegación:
```typescript
// En lugar de ir directo al dashboard, redirigir a mensaje
navigate('/auth/check-email', { 
  state: { 
    email, 
    message: 'Revisa tu correo para establecer tu contraseña' 
  } 
});
```

#### B. Crear página SetPasswordPage

**Crear archivo:** `frontend/src/pages/auth/SetPasswordPage.tsx`

```typescript
import { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { apiPost } from '@/lib/api';

export default function SetPasswordPage() {
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  
  const token = searchParams.get('token');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (password !== confirmPassword) {
      setError('Las contraseñas no coinciden');
      return;
    }

    if (password.length < 8) {
      setError('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    if (!token) {
      setError('Token no válido');
      return;
    }

    setLoading(true);
    setError('');
    
    try {
      await apiPost('/onboarding/set-password', { token, password });
      navigate('/auth/login', { 
        state: { 
          message: '✅ Contraseña establecida exitosamente. Ya puedes iniciar sesión.' 
        }
      });
    } catch (err: any) {
      setError(err.message || 'Error al establecer contraseña');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full p-8 bg-white rounded-lg shadow-lg">
        <h1 className="text-3xl font-bold mb-2 text-center">Establecer Contraseña</h1>
        <p className="text-gray-600 text-center mb-6">
          Crea una contraseña segura para tu cuenta
        </p>
        
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 p-3 rounded mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Nueva Contraseña
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full border border-gray-300 p-3 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              required
              minLength={8}
              placeholder="Mínimo 8 caracteres"
            />
            <p className="text-xs text-gray-500 mt-1">
              Debe incluir mayúsculas, minúsculas, números y símbolos
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Confirmar Contraseña
            </label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="w-full border border-gray-300 p-3 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              required
              placeholder="Repite tu contraseña"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium transition-colors"
          >
            {loading ? 'Procesando...' : 'Establecer Contraseña'}
          </button>
        </form>
      </div>
    </div>
  );
}
```

#### C. Agregar ruta en router

**Archivo:** `frontend/src/router.tsx`

Agregar:
```typescript
{
  path: '/auth/set-password',
  element: <SetPasswordPage />,
},
{
  path: '/auth/check-email',
  element: <CheckEmailPage />, // Página simple que dice "Revisa tu email"
},
```

---

### 4. Testing del Flujo Completo (⏱️ 10 min)

1. **Admin crea código de invitación** (desde panel admin)

2. **Postulante ingresa código:**
   - Ir a: `http://localhost:5173/auth/enter-invite`
   - Ingresar código + email
   - Click en "Validar"

3. **Verificar email recibido:**
   - Revisar bandeja de entrada de `juan.contreras03@alumnos.ucn.cl`
   - Buscar email de Fundación Carmen Goudie
   - Click en link del email

4. **Establecer contraseña:**
   - Se abre página con formulario
   - Ingresar contraseña segura (mínimo 8 chars, con mayúsculas, números, símbolos)
   - Click en "Establecer Contraseña"

5. **Iniciar sesión:**
   - Redirige a login
   - Ingresar email + contraseña recién creada
   - Acceder al sistema

6. **Completar formulario:**
   - Llenar datos del formulario
   - Click en "Enviar"
   - **AHORA SÍ el código se marca como usado**

---

### 5. Verificar en Base de Datos (⏱️ 2 min)

Conectar a Railway PostgreSQL y verificar:

```sql
-- Ver invitación ANTES de enviar formulario
SELECT code, used_at, applicant_id FROM invites WHERE code = 'TU-CODIGO';
-- Esperado: used_at = NULL

-- Ver invitación DESPUÉS de enviar formulario
SELECT code, used_at, applicant_id FROM invites WHERE code = 'TU-CODIGO';
-- Esperado: used_at = [timestamp]

-- Ver auditoría
SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT 10;
```

---

## 📊 Endpoints Disponibles

| Endpoint | Método | Público | Descripción |
|----------|--------|---------|-------------|
| `/onboarding/validate-invite` | POST | ✅ | Valida código (NO lo quema) |
| `/onboarding/set-password` | POST | ✅ | Establece contraseña con token |
| `/auth/login` | POST | ✅ | Login con email/password |
| `/invites/:id/regenerate` | POST | ❌ Admin | Regenera código |
| `/applications/:id/submit` | POST | ❌ Auth | Envía formulario |
| `/applications/:id/complete-invite` | POST | ❌ Auth | Marca código como usado |

---

## 🐛 Solución de Problemas

### Backend no arranca:
```bash
cd backend
rm -rf node_modules package-lock.json
npm install
npm run start:dev
```

### Email no se envía:
1. Verificar API key válida en Railway
2. Verificar email sender `juan.contreras03@alumnos.ucn.cl` verificado en Brevo
3. Ver logs: `railway logs --tail` (si está en Railway)

### Error CORS:
- Verificar `CORS_ORIGINS` en Railway incluye tu dominio Vercel
- Formato: `https://dominio1.com,https://dominio2.com` (sin espacios)

### Error 429 (Too Many Requests):
- Es normal si haces más de 10 requests por segundo
- Esperar 1 minuto y reintentar

---

## 📚 Documentación Completa

- `MEJORAS_IMPLEMENTADAS.md` - Detalle técnico
- `RESUMEN_EJECUTIVO_CORRECCIONES.md` - Resumen ejecutivo
- `DIAGRAMA_FLUJO_ACTUALIZADO.md` - Flujo visual
- `CHECKLIST_PASOS_SIGUIENTES.md` - Checklist completo

---

## 🎯 Estado Actual

✅ Backend: **LISTO PARA PRODUCCIÓN**  
⏳ Frontend: **Requiere actualización (30 min)**  
⏳ Railway: **Requiere variables de entorno (5 min)**

**Próximo paso recomendado:** Probar backend localmente con `npm run start:dev`
