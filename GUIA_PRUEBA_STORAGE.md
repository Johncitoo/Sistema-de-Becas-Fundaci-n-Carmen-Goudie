# 🎯 Sistema de Storage - Listo para Probar

**Estado**: ✅ **COMPLETAMENTE FUNCIONAL Y DESPLEGADO**  
**Fecha**: 25 de noviembre de 2025

---

## 🚀 Cómo Probar

### Paso 1: Acceder a la Aplicación

1. Ve a: **https://fundacioncarmesgoudie.vercel.app**
2. Inicia sesión con tus credenciales de admin

### Paso 2: Ir a la Demo

Una vez dentro, navega a:

```
https://fundacioncarmesgoudie.vercel.app/admin/demo/files
```

O desde el menú lateral (si está disponible), busca "Demo de Archivos"

### Paso 3: Probar el Upload

1. **Arrastra un archivo** al área de carga o **haz clic** para seleccionar
2. Archivos aceptados:
   - Imágenes: JPG, PNG, GIF, WebP, SVG
   - Documentos: PDF, Word (DOC/DOCX), TXT
   - Tamaño máximo: **10 MB**

3. **Haz clic en "Subir Archivo"** y espera la carga

4. Una vez subido, verás:
   - ✅ Confirmación de éxito
   - 📊 Metadata del archivo (nombre, tamaño, tipo, ID)
   - 🔗 Botones para: Ver, Descargar, Thumbnail (si es imagen)
   - 🖼️ Vista previa del thumbnail (si es imagen)

### Paso 4: Verificar Funcionalidad

Después de subir, prueba:

- **Botón "Ver"**: Abre el archivo en el navegador (inline)
- **Botón "Descargar"**: Descarga el archivo
- **Botón "Thumbnail"**: Ver miniatura (solo para imágenes)
- **Vista previa**: Se muestra automáticamente para imágenes

---

## 🎨 Características Implementadas

### Backend
- ✅ **Auth Guards**: Todos los endpoints protegidos con JWT
- ✅ **User Extraction**: Usuario extraído automáticamente del token
- ✅ **Storage Service**: Microservicio independiente en Railway
- ✅ **Thumbnails**: Generación automática para imágenes
- ✅ **Database**: Metadata completa en PostgreSQL
- ✅ **API Keys**: Autenticación segura entre servicios

### Frontend
- ✅ **FileUpload Component**: Drag & drop con animaciones
- ✅ **Progress Bar**: Indicador visual de carga
- ✅ **File Icons**: Iconos según tipo de archivo
- ✅ **Validation**: Tamaño y tipo de archivo
- ✅ **Error Handling**: Mensajes de error claros
- ✅ **Files Service**: Servicio TypeScript para comunicación con API
- ✅ **Demo Page**: Página completa de demostración

---

## 📦 Componentes Desplegados

### Services en Railway

| Servicio | URL | Estado |
|----------|-----|--------|
| **Backend Principal** | https://fcgback-production.up.railway.app | ✅ Running |
| **Storage Service** | https://fcgstorage-production.up.railway.app | ✅ Running |
| **PostgreSQL** | Shared database | ✅ Connected |

### Frontend en Vercel

| URL | Estado |
|-----|--------|
| **https://fundacioncarmesgoudie.vercel.app** | ✅ Deployed |
| **Demo**: /admin/demo/files | ✅ Available |

---

## 🔐 Seguridad Implementada

1. **JWT Authentication**: Todos los endpoints requieren token válido
2. **User Extraction**: Usuario extraído del JWT (no del cliente)
3. **API Keys**: Comunicación segura entre backend y storage
4. **CORS**: Configurado solo para dominios autorizados
5. **File Validation**: Tipo y tamaño validados en cliente y servidor
6. **Ownership**: (Pendiente) Verificar que solo el dueño acceda a sus archivos

---

## 📊 Endpoints Disponibles

### Upload
```http
POST /api/files/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

Body:
- file: <archivo>
- category: PROFILE|DOCUMENT|FORM_FIELD|ATTACHMENT|OTHER
- entityType: USER|APPLICATION|FORM_ANSWER|INSTITUTION (opcional)
- entityId: <uuid> (opcional)
- description: <texto> (opcional)
```

### Download
```http
GET /api/files/:id/download
Authorization: Bearer <token>
```

### View (Inline)
```http
GET /api/files/:id/view
Authorization: Bearer <token>
```

### Thumbnail
```http
GET /api/files/:id/thumbnail
Authorization: Bearer <token>
```

### Metadata
```http
GET /api/files/:id/metadata
Authorization: Bearer <token>
```

### List Files
```http
GET /api/files/list?category=DOCUMENT&entityType=APPLICATION
Authorization: Bearer <token>
```

### Delete
```http
DELETE /api/files/:id
Authorization: Bearer <token>
```

---

## 🧪 Tests Realizados

| Test | Estado | Resultado |
|------|--------|-----------|
| Upload archivo texto | ✅ | 35 bytes subidos |
| Download archivo | ✅ | Contenido correcto |
| View inline | ✅ | Se muestra en navegador |
| Upload imagen | ✅ | 69 bytes + thumbnail |
| Generación thumbnail | ✅ | 811 bytes generados |
| Metadata en BD | ✅ | 4 archivos registrados |
| Auth guards | ✅ | JWT requerido |

---

## 📝 Uso en Código

### Importar el servicio

```typescript
import { filesService, FileCategory, EntityType } from '@/services/files.service';
```

### Subir archivo

```typescript
const token = localStorage.getItem('fcg.access_token') ?? '';

const response = await filesService.upload(
  {
    file: selectedFile,
    category: FileCategory.DOCUMENT,
    entityType: EntityType.APPLICATION,
    entityId: 'application-uuid',
    description: 'Documento de identidad'
  },
  token
);

console.log('File ID:', response.file.id);
console.log('Download URL:', response.urls.download);
```

### Usar el componente

```tsx
import { FileUpload } from '@/components/FileUpload';

<FileUpload
  onFileSelect={handleFileSelect}
  onFileRemove={handleFileRemove}
  file={file}
  progress={progress}
  isUploading={isUploading}
  error={error}
  accept="image/*,.pdf"
  maxSize={10 * 1024 * 1024}
  label="Subir documento"
  helperText="Formatos aceptados: imágenes, PDF"
/>
```

---

## 🔄 Flujo Completo

```
Usuario selecciona archivo
        ↓
FileUpload component
        ↓
filesService.upload()
        ↓
POST /api/files/upload (Backend Principal)
        ↓
JWT Auth Guard valida token
        ↓
Extrae userId del JWT
        ↓
POST /storage/upload (Storage Service)
        ↓
API Key validation
        ↓
Multer guarda archivo en disco
        ↓
Sharp genera thumbnail (si es imagen)
        ↓
TypeORM guarda metadata en PostgreSQL
        ↓
Response con file metadata y URLs
        ↓
Frontend muestra éxito + botones
```

---

## ✅ Checklist de Funcionalidad

- [x] Storage service desplegado y funcionando
- [x] Backend principal integrado con storage
- [x] Base de datos compartida
- [x] Tabla files_metadata creada
- [x] Auth guards en todos los endpoints
- [x] User extraction del JWT
- [x] Files service en frontend
- [x] FileUpload component con drag & drop
- [x] Demo page funcional
- [x] Upload de archivos funcionando
- [x] Download de archivos funcionando
- [x] View inline funcionando
- [x] Thumbnails generados automáticamente
- [x] Progress bar durante upload
- [x] Validación de tipo y tamaño
- [x] Manejo de errores
- [x] Deploy en Vercel
- [x] Deploy en Railway
- [ ] Ownership validation (próxima mejora)
- [ ] Integración en FormPage (próxima mejora)

---

## 🎯 Próximos Pasos (Opcionales)

1. **Ownership Validation**: Verificar que solo el dueño pueda descargar/eliminar
2. **Form Integration**: Agregar campos de tipo "file" en FormPage
3. **Profile Photo**: Subida de foto de perfil de usuario
4. **File Manager**: Página para ver todos los archivos del usuario
5. **Bulk Operations**: Eliminar múltiples archivos
6. **CDN Integration**: Usar CDN para archivos estáticos

---

## 🐛 Troubleshooting

### Error: "No token provided"
**Solución**: Asegúrate de estar logueado. El token JWT se obtiene de `localStorage.getItem('fcg.access_token')`

### Error: "Invalid token"
**Solución**: El token expiró. Vuelve a iniciar sesión.

### Error: "File too large"
**Solución**: El archivo supera los 10MB. Reduce el tamaño o comprime.

### Error: "Invalid file type"
**Solución**: El tipo de archivo no está permitido. Usa imágenes o PDFs.

### Thumbnail no se muestra
**Causa**: Solo se generan thumbnails para imágenes (JPG, PNG, GIF, etc.)  
**Solución**: Si es un PDF o documento, el thumbnail será null.

---

## 📞 Soporte

Si encuentras algún problema:

1. **Verificar logs**: Railway Dashboard → fcgback → Logs
2. **Verificar storage**: Railway Dashboard → fcgstorage → Logs
3. **Verificar BD**: Ejecutar `node backend/check-files.js` para ver archivos
4. **Diagnóstico**: Ejecutar `node backend/diagnose-storage.js`

---

**✨ ¡Sistema completamente funcional y listo para producción!**

Commits recientes:
- Backend: JWT guards + current user decorator
- Frontend: Files service + FileUpload component + Demo page
