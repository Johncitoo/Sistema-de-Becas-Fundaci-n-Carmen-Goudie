# ✅ Checklist de Pasos Siguientes

## 🚀 PASOS INMEDIATOS (Alta Prioridad)

### 1. Configurar variables de entorno en Railway ⏱️ 5 min
- [ ] Ir al dashboard de Railway → Seleccionar backend service
- [ ] Agregar variable `BREVO_API_KEY` con tu API key de Brevo
  - Obtener en: https://app.brevo.com/settings/keys/api
- [ ] Agregar variable `EMAIL_FROM` (ej: `noreply@fundacioncarmengoudie.cl`)
- [ ] Verificar variable `FRONTEND_URL` apunte a tu dominio Vercel
- [ ] Agregar variable `CORS_ORIGINS` con:
  ```
  https://tu-dominio.vercel.app,http://localhost:5173
  ```
- [ ] Redeploy del backend en Railway

### 2. Instalar dependencias del backend ⏱️ 2 min
```bash
cd backend
npm install
```
**Nota:** Si hay problemas, eliminar `node_modules` y `package-lock.json`, luego `npm install` nuevamente.

### 3. Verificar compilación del backend ⏱️ 1 min
```bash
cd backend
npm run build
```
**Esperado:** Compilación exitosa sin errores.

### 4. Probar backend localmente ⏱️ 5 min
```bash
cd backend
# Copiar .env.example a .env y llenar variables
cp .env.example .env
# Editar .env con tus credenciales
npm run start:dev
```

- [ ] Backend corre en `http://localhost:3000`
- [ ] Verificar endpoint: `GET http://localhost:3000/health`
- [ ] Probar validación de código (si tienes uno de prueba):
  ```bash
  curl -X POST http://localhost:3000/onboarding/validate-invite \
    -H "Content-Type: application/json" \
    -d '{"code":"TU-CODIGO","email":"test@example.com"}'
  ```

---

## 🔧 CONFIGURACIÓN FRONTEND (Media Prioridad)

### 5. Actualizar endpoint en frontend ⏱️ 10 min

**Archivo:** `frontend/src/pages/auth/EnterInviteCodePage.tsx`

**Cambiar de:**
```typescript
const result = await apiPost('/invites/consume', { code, email });
```

**A:**
```typescript
const result = await apiPost('/onboarding/validate-invite', { code, email });
```

**Luego del submit exitoso, redirigir a:**
```typescript
// Redirigir a página de establecer contraseña
navigate('/auth/set-password', { 
  state: { email, message: 'Revisa tu email para establecer tu contraseña' } 
});
```

### 6. Crear página de establecer contraseña ⏱️ 20 min

**Crear:** `frontend/src/pages/auth/SetPasswordPage.tsx`

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

    if (!token) {
      setError('Token no válido');
      return;
    }

    setLoading(true);
    try {
      await apiPost('/onboarding/set-password', { token, password });
      navigate('/auth/login', { 
        state: { message: 'Contraseña establecida. Ya puedes iniciar sesión.' }
      });
    } catch (err: any) {
      setError(err.message || 'Error al establecer contraseña');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="max-w-md w-full p-6 bg-white rounded-lg shadow">
        <h1 className="text-2xl font-bold mb-4">Establecer Contraseña</h1>
        
        {error && (
          <div className="bg-red-50 text-red-600 p-3 rounded mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block mb-2">Nueva Contraseña</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full border p-2 rounded"
              required
              minLength={8}
            />
            <p className="text-sm text-gray-500 mt-1">
              Mínimo 8 caracteres, incluyendo mayúsculas, minúsculas, números y símbolos
            </p>
          </div>

          <div className="mb-4">
            <label className="block mb-2">Confirmar Contraseña</label>
            <input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="w-full border p-2 rounded"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white p-2 rounded hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Procesando...' : 'Establecer Contraseña'}
          </button>
        </form>
      </div>
    </div>
  );
}
```

### 7. Agregar ruta en router ⏱️ 2 min

**Archivo:** `frontend/src/router.tsx`

```typescript
{
  path: '/auth/set-password',
  element: <SetPasswordPage />,
},
```

---

## 🧪 TESTING (Media Prioridad)

### 8. Probar flujo completo end-to-end ⏱️ 15 min

- [ ] **Admin:** Crear código de invitación
- [ ] **Postulante:** Ingresar código en frontend
- [ ] **Sistema:** Verificar que NO se queme el código (verificar en DB: `invites.used_at` debe ser NULL)
- [ ] **Postulante:** Revisar email recibido
- [ ] **Postulante:** Click en link del email
- [ ] **Postulante:** Establecer contraseña
- [ ] **Postulante:** Iniciar sesión
- [ ] **Postulante:** Completar formulario
- [ ] **Postulante:** Enviar formulario
- [ ] **Sistema:** Llamar a `POST /applications/:id/complete-invite`
- [ ] **Sistema:** Verificar código quemado (verificar en DB: `invites.used_at` debe tener timestamp)

### 9. Probar regeneración de código ⏱️ 5 min

- [ ] **Admin:** Llamar a `POST /invites/:id/regenerate` con body:
  ```json
  { "newCode": "NUEVO-CODIGO-2024" }
  ```
- [ ] **Sistema:** Verificar código anterior invalidado
- [ ] **Sistema:** Verificar nuevo código creado
- [ ] **Sistema:** Verificar email enviado al postulante
- [ ] **Sistema:** Verificar registro en `audit_logs`

---

## 🔍 VERIFICACIONES DE SEGURIDAD (Alta Prioridad)

### 10. Verificar CORS configurado ⏱️ 3 min

Desde consola del navegador en dominio NO autorizado:
```javascript
fetch('https://tu-backend.railway.app/api/calls')
  .then(r => console.log('ERROR: CORS permitió request'))
  .catch(e => console.log('✅ CORS bloqueó request'));
```

**Esperado:** Error CORS bloqueado.

### 11. Verificar rate limiting ⏱️ 3 min

```bash
# Enviar 15 requests rápidos
for i in {1..15}; do
  curl -X POST https://tu-backend.railway.app/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"wrong"}'
done
```

**Esperado:** Después del request #10, recibir HTTP 429 (Too Many Requests).

### 12. Verificar auditoría funcionando ⏱️ 5 min

```sql
-- Conectar a Railway PostgreSQL
SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT 10;
```

**Esperado:** Ver logs de:
- `invite_validated`
- `login_success` / `login_failed`
- `password_set`
- `application_status_changed`

---

## 📝 MIGRACIONES PENDIENTES (Baja Prioridad)

### 13. Migrar queries SQL en applications.service.ts ⏱️ 60 min

**Archivos a modificar:**
- `backend/src/applications/applications.service.ts`

**Métodos a migrar:**
- `listApplications()` - línea ~12
- `getOrCreate()` - línea ~63
- `getById()` - línea ~135
- `patch()` - línea ~180

**Pasos:**
1. Crear entidad `Application` en `applications/entities/application.entity.ts`
2. Registrar en `applications.module.ts`
3. Inyectar `Repository<Application>` en `ApplicationsService`
4. Reescribir métodos usando query builders

---

## 📊 MONITOREO POST-DEPLOY (Continuo)

### 14. Configurar alertas en Railway ⏱️ 10 min

- [ ] Configurar notificación de errores
- [ ] Configurar alerta de uso de CPU > 80%
- [ ] Configurar alerta de uso de memoria > 80%

### 15. Monitorear logs de producción ⏱️ Continuo

```bash
# Railway CLI
railway logs --tail
```

**Buscar:**
- ❌ Errores de autenticación
- ❌ Errores de email (BREVO_API_KEY inválido)
- ❌ Timeouts de base de datos
- ✅ Logs de `AuditService` (invite_validated, login_success, etc.)

---

## 🎯 CHECKLIST FINAL

### Antes de considerar "COMPLETO":
- [ ] Todas las variables de entorno configuradas en Railway
- [ ] Backend compilando sin errores
- [ ] Frontend actualizado con nuevos endpoints
- [ ] Flujo completo testeado end-to-end
- [ ] CORS verificado
- [ ] Rate limiting verificado
- [ ] Auditoría verificada en DB
- [ ] Email de prueba enviado y recibido
- [ ] Documentación actualizada

### Cuando todo esté ✅:
- [ ] Hacer merge de la rama feat/SDBCG-15-crud-postulantes
- [ ] Crear tag de release v1.1.0
- [ ] Notificar al equipo del deploy
- [ ] Monitorear logs por 24h

---

## 📞 SOPORTE

### Si encuentras errores:

**Error de compilación TypeScript:**
```bash
cd backend
rm -rf node_modules package-lock.json
npm install
npm run build
```

**Error de Brevo API:**
- Verificar API key válido en Railway
- Verificar sender email verificado en Brevo
- Ver logs: `railway logs --tail | grep BREVO`

**Error de CORS:**
- Verificar `CORS_ORIGINS` incluye tu dominio Vercel
- Formato: `https://dominio1.com,https://dominio2.com` (sin espacios)

**Error de rate limiting (429):**
- Normal después de 10 requests/segundo
- Esperar 1 minuto y reintentar
- Para desarrollo local, comentar temporalmente ThrottlerGuard en `app.module.ts`

---

**Última actualización:** Diciembre 2024  
**Tiempo total estimado:** 2-3 horas (sin migraciones pendientes)
