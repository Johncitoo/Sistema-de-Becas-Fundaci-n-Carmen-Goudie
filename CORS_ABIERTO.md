# 🌐 CORS Completamente Abierto

## ✅ Cambios Realizados

Se modificó el archivo `backend/src/main.ts` para **abrir completamente el CORS**:

```typescript
app.enableCors({
  origin: true,  // ✅ Acepta TODOS los orígenes
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  credentials: true,
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
  exposedHeaders: ['Content-Disposition'],
});
```

## 🔓 Qué significa esto

- **`origin: true`**: El backend acepta peticiones desde **cualquier URL**
- No hay restricciones de dominio
- Funciona desde:
  - ✅ https://fcgfront.vercel.app
  - ✅ https://fcgback-production.up.railway.app
  - ✅ http://localhost:5173
  - ✅ Cualquier otro dominio

## 🚀 Cómo Aplicar los Cambios

### 1. Commitea y despliega el backend

```bash
cd backend
git add .
git commit -m "feat: Abrir CORS para todos los orígenes"
git push
```

### 2. Espera el despliegue automático de Railway

Railway detectará el push y desplegará automáticamente (1-2 minutos).

### 3. Verifica que funcione

Abre https://fcgfront.vercel.app/admin/forms y revisa la consola del navegador:

- ✅ **Correcto**: `Status 200 OK` en las peticiones
- ❌ **Error**: Mensajes de CORS (si aún aparecen, espera más tiempo)

## ⚠️ Importante para Producción

**Esta configuración es temporal para desarrollo/pruebas.**

Cuando el sistema esté en producción, debes **restringir los orígenes** permitidos:

```typescript
app.enableCors({
  origin: [
    'https://fcgfront.vercel.app',
    'https://tu-dominio-personalizado.com'
  ],
  // ... resto de la configuración
});
```

Esto previene que otros sitios web consuman tu API sin permiso.

## 📋 Próximos Pasos

1. ✅ Cambios realizados en el código
2. 🔄 **TÚ DEBES HACER**: Commitear y hacer push al backend
3. ⏳ Railway desplegará automáticamente
4. ✅ Verifica que funcione en Vercel

---

**URLs de referencia:**
- Backend Railway: https://fcgback-production.up.railway.app
- Frontend Vercel: https://fcgfront.vercel.app
