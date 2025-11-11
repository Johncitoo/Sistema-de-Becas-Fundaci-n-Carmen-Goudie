# ⚡ SOLUCIÓN RÁPIDA - Error CORS

## 🚨 TU PROBLEMA:
```
❌ CORS policy: No 'Access-Control-Allow-Origin' header
```

## ✅ LA SOLUCIÓN:

Ya modifiqué el backend para habilitar CORS. Ahora solo debes:

### **EJECUTA ESTOS COMANDOS:**

```powershell
# 1. Ir a backend
cd "C:\Users\YeCoBz\Desktop\App\Fundación Carmes Goudie 2\backend"

# 2. Ver cambios
git status

# 3. Agregar cambios
git add .

# 4. Commit
git commit -m "fix: Configurar CORS para permitir peticiones desde Vercel"

# 5. Push (Railway desplegará automáticamente)
git push origin feat/SDBCG-15-crud-postulantes
```

### **ESPERA 1-2 MINUTOS** ⏱️

Railway desplegará automáticamente tu backend con la nueva configuración.

### **VERIFICA QUE FUNCIONÓ:**

1. Ve a: https://fcgfront.vercel.app/admin/forms
2. Abre la consola (F12)
3. **ANTES** veías: ❌ CORS error
4. **AHORA** deberías ver: ✅ Datos cargando

---

## 📋 QUÉ CAMBIÓ:

**Archivo**: `backend/src/main.ts`

**Se agregó**:
```typescript
app.enableCors({
  origin: [
    'https://fcgfront.vercel.app',  // Tu app en Vercel
    'http://localhost:5173',        // Desarrollo local
  ],
  credentials: true,
});
```

Esto permite que tu frontend en Vercel se comunique con tu backend en Railway.

---

## 🎯 RESUMEN:

**Problema**: Backend bloqueaba peticiones desde Vercel  
**Solución**: Configurar CORS en el backend  
**Acción**: Hacer push a GitHub (Railway despliega auto)  

---

## 📖 DOCUMENTACIÓN COMPLETA:

Ver: `SOLUCION_CORS.md` para explicación detallada.

---

**¡Listo! Ejecuta los comandos y espera el deploy!** 🚀
