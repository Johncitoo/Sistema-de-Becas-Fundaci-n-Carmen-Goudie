# 🚨 SOLUCIÓN: Error CORS - Frontend (Vercel) → Backend (Railway)

## 📋 PROBLEMA IDENTIFICADO

### Error en la Consola:
```
Access to fetch at 'http://localhost:3000/api/calls?onlyActive=true&count=1' 
from origin 'https://fcgfront.vercel.app' has been blocked by CORS policy: 
Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

---

## 🔍 ANÁLISIS DEL PROBLEMA

### Había 2 Problemas:

#### 1. **Backend sin CORS configurado** ❌
- El backend en Railway no tenía CORS habilitado
- No permitía peticiones desde dominios externos
- Bloqueaba todas las requests desde Vercel

#### 2. **Frontend apuntando a localhost** ⚠️
- El archivo `.env` apuntaba a: `VITE_API_URL=http://localhost:3000`
- Debería apuntar a: `VITE_API_URL=https://fcgback-production.up.railway.app`

---

## ✅ SOLUCIONES APLICADAS

### **Solución 1: Configurar CORS en el Backend**

**Archivo modificado**: `backend/src/main.ts`

**Cambio realizado**:
```typescript
// ✅ AGREGADO: Configuración de CORS
app.enableCors({
  origin: [
    'https://fcgfront.vercel.app',          // Producción en Vercel
    'http://localhost:5173',                // Desarrollo local
    'http://localhost:3000',                // Desarrollo local alternativo
    /\.vercel\.app$/,                       // Cualquier preview de Vercel
  ],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  credentials: true,
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  exposedHeaders: ['Content-Disposition'],
});
```

**Qué hace esto:**
- ✅ Permite peticiones desde `https://fcgfront.vercel.app`
- ✅ Permite peticiones desde `localhost` (desarrollo)
- ✅ Permite cualquier preview de Vercel (ej: `tu-app-git-branch.vercel.app`)
- ✅ Habilita cookies y autenticación (`credentials: true`)
- ✅ Permite todos los métodos HTTP necesarios

---

### **Solución 2: Verificar URL del Backend**

**Archivo verificado**: `frontend/.env`

**Contenido actual**:
```bash
VITE_API_URL=https://fcgback-production.up.railway.app
```

✅ **CORRECTO** - Ya apunta a Railway, no a localhost

---

## 🚀 PASOS PARA APLICAR LA SOLUCIÓN

### **Paso 1: Desplegar Backend a Railway**

```powershell
# Ir a la carpeta del backend
cd "C:\Users\YeCoBz\Desktop\App\Fundación Carmes Goudie 2\backend"

# Commit de cambios
git add .
git commit -m "fix: Configurar CORS para permitir peticiones desde Vercel"
git push origin feat/SDBCG-15-crud-postulantes
```

**Railway desplegará automáticamente** (1-2 minutos)

---

### **Paso 2: Verificar que funciona**

1. Espera a que Railway termine de desplegar
2. Ve a: https://fcgfront.vercel.app/admin/forms
3. **Debería cargar correctamente** sin errores CORS

---

## 🔍 CÓMO VERIFICAR SI FUNCIONÓ

### **1. Ver logs de Railway**

1. Ve a Railway Dashboard
2. Selecciona tu proyecto backend
3. Click en "Deployments"
4. Verifica que el deploy fue exitoso

### **2. Probar en el navegador**

Abre la consola (F12) en:
- https://fcgfront.vercel.app/admin/forms

**ANTES** veías:
```
❌ CORS policy: No 'Access-Control-Allow-Origin' header
```

**DESPUÉS** deberías ver:
```
✅ Status 200 OK (o los datos cargando normalmente)
```

---

## 🛠️ QUÉ ES CORS Y POR QUÉ PASÓ ESTO

### **¿Qué es CORS?**

**CORS** = Cross-Origin Resource Sharing (Compartir Recursos entre Orígenes)

Es una **medida de seguridad del navegador** que:
- Bloquea peticiones entre dominios diferentes
- Protege contra ataques maliciosos
- Requiere que el servidor **permita explícitamente** los orígenes

### **¿Por qué pasó?**

```
Frontend: https://fcgfront.vercel.app    (origen 1)
Backend:  https://fcgback....railway.app  (origen 2)
                    ↓
        Orígenes DIFERENTES
                    ↓
        CORS necesario ✅
```

Sin CORS configurado:
```
Frontend → Backend: "Dame los datos"
Backend → Frontend: 🚫 "No te conozco, bloqueado"
```

Con CORS configurado:
```
Frontend → Backend: "Dame los datos"
Backend → Frontend: ✅ "Aquí están, eres de confianza"
```

---

## 📊 COMPARACIÓN: ANTES vs DESPUÉS

### **ANTES ❌**

```typescript
// backend/src/main.ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  // ❌ SIN CORS
  await app.listen(3000);
}
```

**Resultado:**
- ❌ Frontend no puede conectarse al backend
- ❌ Errores CORS en consola
- ❌ No cargan datos
- ❌ Formularios vacíos

### **DESPUÉS ✅**

```typescript
// backend/src/main.ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // ✅ CON CORS
  app.enableCors({
    origin: ['https://fcgfront.vercel.app', ...],
    credentials: true,
  });
  
  await app.listen(3000);
}
```

**Resultado:**
- ✅ Frontend se conecta al backend
- ✅ Sin errores CORS
- ✅ Datos cargan correctamente
- ✅ Formularios funcionan

---

## 🎯 CONFIGURACIÓN RECOMENDADA

### **Para Producción (Railway)**

Variables de entorno en Railway:

```bash
NODE_ENV=production
DATABASE_URL=postgresql://...
PORT=3000
CORS_ORIGINS=https://fcgfront.vercel.app
```

### **Para Desarrollo Local**

Variables de entorno en `.env.local`:

```bash
NODE_ENV=development
DATABASE_URL=postgresql://localhost:5432/...
PORT=3000
CORS_ORIGINS=http://localhost:5173,http://localhost:3000
```

---

## 🔐 SEGURIDAD: Orígenes Permitidos

### **Configuración Actual (Segura)**

```typescript
origin: [
  'https://fcgfront.vercel.app',    // ✅ Solo tu app en Vercel
  'http://localhost:5173',           // ✅ Solo desarrollo local
  /\.vercel\.app$/,                  // ✅ Solo previews de Vercel
],
```

### **❌ NO HACER (Inseguro)**

```typescript
origin: '*',  // ❌ Permite CUALQUIER origen (peligroso)
```

Esto permitiría que **cualquier sitio web** haga peticiones a tu backend.

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### **Si aún no funciona después de desplegar:**

#### **1. Verificar que Railway desplegó correctamente**

```bash
# Ver logs en Railway
# Dashboard → Tu proyecto → Deployments → View Logs

# Buscar:
✅ "Application is running on: http://[::]:3000"
✅ "Nest application successfully started"
```

#### **2. Verificar la URL del backend**

En Railway Dashboard:
- Settings → Domains
- Copia la URL (ej: `fcgback-production.up.railway.app`)

En `frontend/.env`:
```bash
VITE_API_URL=https://fcgback-production.up.railway.app
```

Deben coincidir ✅

#### **3. Limpiar caché**

Si aún ves errores:

```powershell
# Frontend: Reconstruir
cd frontend
npm run build

# Vercel: Redeploy
# Dashboard → Deployments → ... → Redeploy
```

#### **4. Verificar que el backend está UP**

```bash
# Abrir en navegador:
https://fcgback-production.up.railway.app/api

# Deberías ver algo como:
{"message": "API is running"}
# O cualquier respuesta (no error)
```

---

## 📝 CHECKLIST POST-DEPLOYMENT

```
Backend (Railway):
□ Código con CORS subido a GitHub
□ Railway desplegó automáticamente
□ Logs muestran "successfully started"
□ URL del backend funciona (abre en navegador)

Frontend (Vercel):
□ .env tiene la URL correcta de Railway
□ No hay errores CORS en consola
□ Datos cargan correctamente
□ Formularios muestran información

Si TODO está ✅: ¡FUNCIONANDO!
```

---

## 🎓 PARA ENTENDER MEJOR

### **Analogía Simple:**

Imagina que:
- **Frontend** = Tu casa
- **Backend** = Un banco
- **CORS** = La política de seguridad del banco

**Sin CORS:**
```
Tú (frontend): "Quiero mi dinero"
Banco (backend): "No te conozco, no tienes permiso" 🚫
```

**Con CORS:**
```
Tú (frontend): "Quiero mi dinero"
Banco (backend): "Estás en mi lista de confianza, aquí está" ✅
```

---

## 🚀 SIGUIENTE PASO

**Ejecuta estos comandos AHORA:**

```powershell
# 1. Ir a backend
cd "C:\Users\YeCoBz\Desktop\App\Fundación Carmes Goudie 2\backend"

# 2. Commit
git add .
git commit -m "fix: Configurar CORS para Vercel"

# 3. Push (Railway desplegará automáticamente)
git push origin feat/SDBCG-15-crud-postulantes

# 4. Espera 1-2 minutos

# 5. Prueba tu app
# Abre: https://fcgfront.vercel.app/admin/forms
```

---

## ✅ RESULTADO ESPERADO

Después de desplegar, cuando abras:
- https://fcgfront.vercel.app/admin/forms

**Verás:**
- ✅ Lista de convocatorias
- ✅ Botones funcionando
- ✅ Datos cargando
- ✅ Sin errores CORS

**Consola (F12):**
- ✅ Status 200 OK en las peticiones
- ✅ Sin mensajes de error rojo

---

## 📞 SI AÚN NO FUNCIONA

Comparte:
1. **Logs de Railway** (últimas 50 líneas)
2. **Consola del navegador** (F12 → Console)
3. **URL del backend en Railway**
4. **Contenido de `frontend/.env`**

---

**¡Aplica la solución y debería funcionar!** 🎉

**Tiempo estimado**: 5 minutos (deploy automático)
