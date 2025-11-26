# 🚨 ACCIÓN REQUERIDA: Ejecutar Migración SQL

## ⚠️ Estado Actual

**Backend y Frontend revertidos temporalmente** para restaurar funcionalidad.

Los commits de activación están listos pero **no se pueden usar** hasta ejecutar la migración SQL en Railway.

---

## 📋 Pasos para Activar el Sistema de Activación

### 1️⃣ Ejecutar Migración en Railway (5 minutos)

**Opción más fácil - Railway Dashboard:**

1. Ve a https://railway.app
2. Selecciona tu proyecto PostgreSQL
3. Click en pestaña **"Query"**
4. Abre el archivo: `BD/migrations/005_add_call_activation_control.sql`
5. Copia TODO el contenido (BEGIN hasta COMMIT)
6. Pega en Railway Query
7. Click **"Run Query"**
8. Verifica que aparezca: ✅ **COMMIT**

### 2️⃣ Verificar Migración

Ejecuta en Railway Query:

```sql
-- Verificar columnas nuevas
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'calls' 
AND column_name IN ('start_date', 'end_date', 'is_active', 'auto_close');
```

**Resultado esperado:** 4 filas

### 3️⃣ Re-desplegar Backend

```powershell
cd backend
git revert 0357a86
git commit -m "feat: reactivar sistema de activación de convocatorias"
git push origin main
```

### 4️⃣ Re-desplegar Frontend

```powershell
cd frontend
git revert 48454d5
npm run build
git commit -m "feat: reactivar sistema de activación de convocatorias"
git push origin main
```

---

## 📁 Archivo de Migración

**Ubicación:** `BD/migrations/005_add_call_activation_control.sql`

**Qué hace:**
- ✅ Agrega 4 columnas a tabla `calls`
- ✅ Crea función `is_call_active()`
- ✅ Crea función `auto_close_expired_calls()`
- ✅ Crea vista `active_calls`
- ✅ Actualiza convocatorias existentes

---

## 🔍 Troubleshooting

**Error: "column already exists"**
```
La migración ya se ejecutó. Continúa con paso 3.
```

**Error: "permission denied"**
```
Verifica estar usando usuario 'postgres' con contraseña correcta.
```

**Error: "relation does not exist"**
```
Verifica estar conectado a la base de datos correcta.
```

---

## 📚 Documentación

Una vez ejecutada la migración, lee:

- **`ACTIVACION_CONVOCATORIAS_SIMPLE.md`** - Cómo usar el sistema
- **`GUIA_ACTIVACION_CONVOCATORIAS.md`** - Detalles técnicos
- **`RESUMEN_EJECUTIVO_ACTIVACION.md`** - Overview completo

---

## ⚡ Resumen Rápido

```
1. Railway → PostgreSQL → Query
2. Copiar/Pegar: BD/migrations/005_add_call_activation_control.sql
3. Run Query
4. git revert 0357a86 (backend)
5. git revert 48454d5 (frontend)
6. git push ambos repositorios
7. ✅ Sistema activo
```

---

**Commits revertidos temporalmente:**
- Backend: `0357a86` (revirtió `1341b24`)
- Frontend: `48454d5` (revirtió `f0034ed`)

**Para restaurar:** Hacer `git revert` de los commits de revert (pasos 3 y 4 arriba)
