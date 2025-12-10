# 🚨 ACCIÓN URGENTE: Credenciales Expuestas

## ⚠️ SITUACIÓN CRÍTICA

**40+ archivos** contienen credenciales de base de datos hardcodeadas:
```
postgresql://postgres:LVMTmEztSWRfFHuJoBLRkLUUiVAByPuv@tramway.proxy.rlwy.net:30026/railway
```

## 🔴 RIESGOS

1. **Cualquiera con acceso al código puede conectarse a tu DB de producción**
2. **Pueden robar, modificar o eliminar todos los datos**
3. **Pueden crear usuarios admin falsos**
4. **SSL deshabilitado** (`rejectUnauthorized: false`) = Man-in-the-middle attacks

---

## ✅ SOLUCIÓN INMEDIATA

### Paso 1: Cambiar contraseña de Railway AHORA

1. Ve a Railway.app → Tu proyecto
2. Variables → `DATABASE_URL` → Regenerate password
3. Esto invalidará la contraseña expuesta

### Paso 2: Mover archivos de scripts a carpeta separada

Estos archivos son **scripts de desarrollo/debug**, NO deberían estar en producción:

```bash
# Crear carpeta de scripts inseguros
mkdir backend/scripts-inseguros

# Mover todos los archivos .js problemáticos
mv backend/*.js backend/scripts-inseguros/
```

### Paso 3: Agregar a .gitignore

```bash
echo "backend/scripts-inseguros/" >> .gitignore
```

### Paso 4: Crear template de script seguro

Archivo: `backend/scripts-template.js`

```javascript
// ✅ CORRECTO: Usar variables de entorno
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL, // ✅ Desde variable
  ssl: process.env.NODE_ENV === 'production' 
    ? { rejectUnauthorized: true }  // ✅ SSL habilitado en prod
    : false  // Solo dev local sin SSL
});

async function main() {
  const client = await pool.connect();
  try {
    // Tu lógica aquí
    const result = await client.query('SELECT NOW()');
    console.log(result.rows);
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch(console.error);
```

---

## 🔍 ARCHIVOS AFECTADOS (40+)

### Scripts con credenciales hardcodeadas:
```
backend/sync-milestone-progress.js
backend/clean-database-keep-test2029.js
backend/verify-test-call.js
backend/get-arturo-code.js
backend/create-test-code-arturo.js
backend/check-arturo-status.js
backend/fix-arturo-milestones.js
backend/check-first-milestone-form.js
backend/check-milestone-form-relation.js
backend/debug-arturo-view.js
backend/check-arturo-complete.js
backend/create-arturo-application.js
backend/create-arturo-app-fixed.js
backend/check-applications-schema.js
backend/create-arturo-full.js
backend/debug-duplicate-milestones.js
backend/fix-test2029-milestones.js
backend/add-form-fields.js
backend/check-api-response.js
backend/test-form-endpoint.js
backend/debug-form-submission.js
backend/fix-arturo-milestone.js
backend/check-arturo-files.js
backend/check-files-metadata.js
backend/test-files-endpoint.js
backend/reset-arturo-submission.js
backend/check-db-structure.js
backend/check-form-details.js
backend/check-responses-detail.js
backend/verify-empty-applications.js
backend/check-arturo-submission.js
backend/find-arturo.js
backend/check-call-structure.js
backend/preview-csv-arturo.js
backend/check-submission-fields.js
backend/audit-complete-database.js
backend/check-active-call.js
backend/check-call-milestones.js
backend/check-form-schema.js
backend/check-forms-structure.js
backend/check-invite-meta.js
backend/check-invites-simple.js
backend/check-milestones-schema.js
... y más
```

---

## 📋 CHECKLIST DE SEGURIDAD

### Inmediato (HOY):
- [ ] Cambiar contraseña de Railway
- [ ] Mover scripts a carpeta `scripts-inseguros/`
- [ ] Agregar `scripts-inseguros/` a `.gitignore`
- [ ] Verificar que no se hayan commiteado aún (si sí, hacer git history cleanup)

### Esta semana:
- [ ] Reescribir scripts necesarios usando `process.env.DATABASE_URL`
- [ ] Habilitar SSL validation en producción (`rejectUnauthorized: true`)
- [ ] Agregar `.env.example` con variables requeridas
- [ ] Rotar JWT_SECRET y otros secretos
- [ ] Habilitar 2FA en Railway

### Próxima semana:
- [ ] Implementar secrets management (AWS Secrets Manager, HashiCorp Vault)
- [ ] Auditoría de seguridad completa
- [ ] Penetration testing
- [ ] Setup de logs de acceso a DB

---

## 🛡️ PREVENCIÓN FUTURA

### 1. Pre-commit Hook

`.git/hooks/pre-commit`:
```bash
#!/bin/bash
if git diff --cached | grep -q "postgresql://postgres:"; then
  echo "❌ ERROR: Credenciales hardcodeadas detectadas"
  echo "No se permite commit con credenciales en el código"
  exit 1
fi
```

### 2. GitHub Secret Scanning

Habilitar en GitHub:
- Settings → Code security → Secret scanning
- Esto te alertará si commiteas credenciales

### 3. Environment Variables Only

Regla: **NUNCA** poner credenciales directamente en código.
Siempre usar `process.env.VARIABLE_NAME`

---

## 🔐 MEJORAS ADICIONALES

### 1. Usar Railway CLI para scripts

En lugar de hardcodear, usar:
```bash
railway run node script.js
```

Esto inyecta automáticamente las variables de entorno.

### 2. Database Roles

Crear roles de DB con permisos limitados:
```sql
-- Role solo lectura para scripts de análisis
CREATE ROLE readonly_user WITH LOGIN PASSWORD 'secure_pass';
GRANT CONNECT ON DATABASE railway TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
```

### 3. IP Whitelist

En Railway, restringir acceso a DB solo desde IPs conocidas.

---

## 📊 IMPACTO DE LA BRECHA

Si un atacante obtuvo estas credenciales, podría:

1. ✅ **Leer todos los datos** (usuarios, emails, postulaciones, hitos)
2. ✅ **Modificar datos** (cambiar estados, aprobar/rechazar postulaciones)
3. ✅ **Eliminar datos** (DROP tables)
4. ✅ **Crear backdoors** (insertar usuarios admin)
5. ✅ **Exfiltrar datos** (copiar DB completa)

### Nivel de Riesgo: 🔴 CRÍTICO

---

## 🚀 COMANDOS RÁPIDOS

```bash
# 1. Mover scripts inseguros
mkdir -p backend/scripts-inseguros
mv backend/*.js backend/scripts-inseguros/ 2>/dev/null || true

# 2. Agregar a gitignore
echo "backend/scripts-inseguros/" >> .gitignore
echo "*.env" >> .gitignore
echo ".env.local" >> .gitignore

# 3. Crear .env.example
cat > backend/.env.example << 'EOF'
# Database
DATABASE_URL=postgresql://user:password@host:port/database

# JWT
AUTH_JWT_SECRET=your-secret-here
AUTH_REFRESH_SECRET=your-refresh-secret-here

# Email
EMAIL_HOST=smtp.example.com
EMAIL_USER=user@example.com
EMAIL_PASS=your-email-password

# Storage
STORAGE_SERVICE_URL=http://localhost:3001
EOF

# 4. Commit cambios
git add .gitignore backend/.env.example
git commit -m "security: move unsafe scripts and add env example"
```

---

## ⏰ TIEMPO ESTIMADO

- **Cambiar password Railway**: 2 minutos
- **Mover archivos**: 1 minuto  
- **Actualizar .gitignore**: 1 minuto
- **Crear template**: 5 minutos
- **Verificar que funcione**: 10 minutos

**TOTAL: ~20 minutos** para mitigar riesgo crítico

---

**Fecha**: 10 de diciembre de 2024  
**Prioridad**: 🔴 URGENTE  
**Responsable**: Ejecutar INMEDIATAMENTE
