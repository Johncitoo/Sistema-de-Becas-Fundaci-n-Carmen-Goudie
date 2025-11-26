# 🧪 Guía de Prueba: Flujo Completo del Postulante

## 📋 Preparación Completada

✅ **Frontend corriendo en:** http://localhost:5173/  
✅ **Backend en:** https://fcgback-production.up.railway.app  
✅ **Convocatoria activa:** Becas FCG 2026  
✅ **Código de invitación creado:** `TEST-IHZRF3LC`  
✅ **Email de prueba:** `postulante.prueba@test.cl`  

---

## 🎯 Flujo de Prueba Paso a Paso

### **PASO 1: Validar Código de Invitación** 🎫

1. **Abre el navegador en:**  
   ```
   http://localhost:5173/#/auth/enter-invite
   ```
   
   **💡 ALTERNATIVA:** También puedes ir a `/login` → pestaña "Postular" → botón "Ingresar código de invitación"

2. **Completa el formulario:**
   - **Correo personal:** `postulante.prueba@test.cl`
   - **Código de invitación:** `TEST-IHZRF3LC`

3. **Haz clic en** `Validar código`

4. **✅ Resultado esperado:**
   - Mensaje de éxito verde: "Código validado exitosamente..."
   - Se muestra botón "Definir contraseña"

5. **📸 Verifica:**
   - [ ] Mensaje de éxito se muestra claramente
   - [ ] No hay errores en la consola del navegador (F12)
   - [ ] Botones "Definir contraseña" y "Volver al login" aparecen

---

### **PASO 2: Establecer Contraseña** 🔐

1. **Haz clic en** `Definir contraseña`  
   (O navega manualmente a: `http://localhost:5173/#/set-password?email=postulante.prueba@test.cl`)

2. **En la página de establecer contraseña:**
   - **Email:** (debería estar pre-llenado con `postulante.prueba@test.cl`)
   - **Token:** Revisa la consola del backend Railway o busca en los logs. Alternativamente, puedes obtenerlo de la base de datos con:
     ```sql
     SELECT token FROM password_set_tokens 
     WHERE email = 'postulante.prueba@test.cl' 
     ORDER BY created_at DESC LIMIT 1;
     ```
   - **Nueva contraseña:** `Test1234!`
   - **Confirmar contraseña:** `Test1234!`

3. **Haz clic en** `Establecer contraseña`

4. **✅ Resultado esperado:**
   - Mensaje de éxito: "Contraseña establecida correctamente"
   - Redirección automática a `/login`

5. **📸 Verifica:**
   - [ ] Contraseña se establece sin errores
   - [ ] Redirección a login funciona
   - [ ] No hay errores 400/401 en Network (F12)

---

### **PASO 3: Iniciar Sesión** 🔓

1. **En la página de login** (`http://localhost:5173/#/login`)

2. **Usa las credenciales:**
   - **Email:** `postulante.prueba@test.cl`
   - **Contraseña:** `Test1234!`

3. **Haz clic en** `Iniciar sesión`

4. **✅ Resultado esperado:**
   - Login exitoso
   - Redirección automática a `/applicant` (home del postulante)
   - Navbar muestra nombre del usuario

5. **📸 Verifica:**
   - [ ] Login exitoso sin errores 401
   - [ ] Redirige a `/applicant`
   - [ ] Se guarda token en localStorage (F12 → Application → Local Storage)

---

### **PASO 4: Verificar Dashboard del Postulante** 📊

1. **Deberías estar en:** `http://localhost:5173/#/applicant`

2. **Busca en la página:**
   - **Tracker de hitos** (ProgressTracker component)
   - Lista de hitos de "Becas FCG 2026"
   - Progreso visual (barras o indicadores)

3. **✅ Resultado esperado:**
   - Se muestra el ProgressTracker
   - Hitos aparecen en orden (ej: "Validación de Código", "Completar Formulario", etc.)
   - Progreso inicial: 0% o solo primer hito completado

4. **📸 Verifica:**
   - [ ] ProgressTracker se renderiza correctamente
   - [ ] Hitos se muestran con nombres y descripciones
   - [ ] Estados de hitos son correctos (ej: primer hito COMPLETED, resto NOT_STARTED)
   - [ ] No hay errores en consola al cargar hitos

---

### **PASO 5: Navegar al Formulario** 📝

1. **Busca el botón/link** "Completar formulario" o "Ir a formulario"

2. **Haz clic para ir a la página del formulario**  
   (Debería ser algo como `/applicant/form` o `/form`)

3. **✅ Resultado esperado:**
   - Formulario se carga con campos vacíos
   - Se muestra estructura de secciones (datos personales, académicos, etc.)
   - Campos de carga de archivos visibles

4. **📸 Verifica:**
   - [ ] Formulario se renderiza sin errores
   - [ ] Campos están organizados en secciones
   - [ ] Componentes FileUpload aparecen donde corresponden

---

### **PASO 6: Llenar Formulario** ✍️

1. **Completa los campos:**
   - **Datos Personales:**
     - Nombre: `Juan`
     - Apellido: `Pérez`
     - RUT: `12345678-9`
     - Teléfono: `+56912345678`
   
   - **Datos Académicos:**
     - Institución: (selecciona una)
     - Carrera: `Ingeniería Civil`
     - Año de ingreso: `2023`

   - **Documentos:**
     - Sube un archivo de prueba (cualquier .pdf o imagen)

2. **Haz clic en** `Guardar borrador` (o similar)

3. **✅ Resultado esperado:**
   - Toast de éxito: "Formulario guardado"
   - Datos persisten al recargar página
   - Progreso de hitos se actualiza (ej: "Completar Formulario" → IN_PROGRESS)

4. **📸 Verifica:**
   - [ ] Guardado exitoso sin errores 500
   - [ ] Datos persisten tras refrescar (F5)
   - [ ] ProgressTracker se actualiza mostrando nuevo progreso
   - [ ] Estado en BD cambió a IN_PROGRESS o SUBMITTED según corresponda

---

### **PASO 7: Verificar Actualización de Hitos** 🎯

1. **Vuelve al dashboard** (`/applicant`)

2. **Revisa el ProgressTracker:**
   - Progreso debería haber aumentado (ej: 33% → 66%)
   - Hito "Completar Formulario" debería estar IN_PROGRESS o COMPLETED

3. **✅ Resultado esperado:**
   - Barra de progreso visual actualizada
   - Cambio de color/icono en hito correspondiente
   - Porcentaje de completitud correcto

4. **📸 Verifica:**
   - [ ] Progreso refleja acciones realizadas
   - [ ] API `/milestone-progress` retorna datos correctos (F12 → Network)
   - [ ] No hay errores al consultar progreso

---

### **PASO 8: Subir Documentos** 📎

1. **En el formulario, sección de documentos:**

2. **Sube archivos de prueba:**
   - Certificado de notas (PDF)
   - Foto de perfil (JPG/PNG)
   - Carta de motivación (PDF)

3. **✅ Resultado esperado:**
   - Upload exitoso con barra de progreso
   - Preview del archivo aparece
   - URL del archivo guardada en formulario

4. **📸 Verifica:**
   - [ ] FileUpload component funciona correctamente
   - [ ] POST a `/documents/upload` retorna 200
   - [ ] Archivos se guardan en storage (Railway o S3)
   - [ ] URLs de archivos persisten en form_submissions

---

### **PASO 9: Enviar Formulario Final** 🚀

1. **Completa todos los campos obligatorios**

2. **Haz clic en** `Enviar postulación` (o botón final)

3. **Confirma el envío** (si hay modal de confirmación)

4. **✅ Resultado esperado:**
   - Mensaje de éxito: "Postulación enviada exitosamente"
   - Estado de application cambia de DRAFT a SUBMITTED
   - Hito final "Postulación Enviada" → COMPLETED
   - Progreso → 100%

5. **📸 Verifica:**
   - [ ] Status en BD: `applications.status = 'SUBMITTED'`
   - [ ] Todos los hitos relevantes están COMPLETED
   - [ ] ProgressTracker muestra 100%
   - [ ] No se puede editar formulario después del envío

---

### **PASO 10: Verificar Estado Final** ✅

1. **En el dashboard del postulante:**
   - Progreso: 100%
   - Todos los hitos completados
   - Mensaje: "Postulación enviada exitosamente"

2. **Opcional - Login como ADMIN:**
   - Ve a `/admin/applications`
   - Busca la postulación de `postulante.prueba@test.cl`
   - Verifica que aparece con status SUBMITTED

3. **✅ Resultado esperado:**
   - Postulación completa y visible en el sistema
   - Todos los datos guardados correctamente
   - Flujo end-to-end funcional

---

## 🐛 Checklist de Problemas Comunes

### Si el código no valida:
- [ ] Verifica que escribiste exactamente: `TEST-IHZRF3LC` (mayúsculas)
- [ ] Revisa en DB que el invite existe: `SELECT * FROM invites WHERE code_hash = ...`
- [ ] Confirma que no está expirado: `expires_at > NOW()`

### Si el login falla:
- [ ] Verifica que estableciste la contraseña correctamente
- [ ] Revisa en Network (F12) el error exacto (401, 400, etc.)
- [ ] Confirma que el usuario existe: `SELECT * FROM users WHERE email = 'postulante.prueba@test.cl'`

### Si el formulario no guarda:
- [ ] Revisa errores 500 en Network (F12)
- [ ] Verifica que form_submissions se creó: `SELECT * FROM form_submissions WHERE user_id = ...`
- [ ] Confirma que el backend está corriendo

### Si los hitos no se actualizan:
- [ ] Verifica que milestones existen: `SELECT * FROM milestones WHERE call_id = '5e33c8ee-52a7-4736-89a4-043845ea7f1a'`
- [ ] Confirma que milestone_progress se crea: `SELECT * FROM milestone_progress WHERE application_id = ...`
- [ ] Revisa logs del backend para ver si hay errores

### Si FileUpload falla:
- [ ] Verifica configuración de storage en backend (.env)
- [ ] Confirma que `/documents/upload` endpoint existe
- [ ] Revisa permisos de storage (Railway Volumes o S3)

---

## 📊 Datos de Prueba para Copiar

```
Email:         postulante.prueba@test.cl
Código:        TEST-IHZRF3LC
Contraseña:    Test1234!
Call ID:       5e33c8ee-52a7-4736-89a4-043845ea7f1a
Call Name:     Becas FCG 2026
```

---

## 🎉 Éxito del Flujo

Si completaste todos los pasos sin errores:

✅ **Validación de código** → Funcional  
✅ **Establecimiento de contraseña** → Funcional  
✅ **Login con credenciales** → Funcional  
✅ **Dashboard con ProgressTracker** → Funcional  
✅ **Llenado de formulario** → Funcional  
✅ **Upload de archivos** → Funcional  
✅ **Actualización de hitos** → Funcional  
✅ **Envío final de postulación** → Funcional  

🚀 **Sistema completo operacional!**

---

## 📝 Notas Adicionales

- Si quieres probar de nuevo, crea otro código con: `node create-test-invite.js`
- Para resetear un postulante, elimina en DB: `DELETE FROM users WHERE email = 'postulante.prueba@test.cl'`
- Logs del backend están en Railway: https://railway.app/project/logs
- Frontend corre en: http://localhost:5173/
- Backend API: https://fcgback-production.up.railway.app

---

**Fecha de creación:** 25 de noviembre de 2025  
**Versión:** 1.0.0  
**Estado:** ✅ Listo para probar
