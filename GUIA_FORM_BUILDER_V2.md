# 📋 Guía Visual: Nuevo Constructor de Formularios

## ✨ ¿Qué cambió?

Hemos creado un **constructor de formularios completamente nuevo** que es **mucho más fácil e intuitivo** de usar. Ya no necesitas ser desarrollador para crear o editar formularios.

---

## 🎯 Características principales

### 1. **Interfaz Visual Moderna**
- ✅ Todo se ve como se verá realmente
- ✅ Edición en tiempo real
- ✅ Vista previa instantánea
- ✅ Drag and drop (arrastrar y soltar)
- ✅ Iconos de colores para cada tipo de campo

### 2. **Diseño Intuitivo**
- ✅ Botones claros con íconos
- ✅ Panel de ayuda siempre visible
- ✅ Configuración campo por campo
- ✅ Validación visual inmediata

### 3. **Más Fácil de Usar**
- ✅ No más JSON complicado
- ✅ No más códigos técnicos
- ✅ Click, edita, guarda - ¡Listo!

---

## 🚀 Cómo usar el nuevo Form Builder

### Paso 1: Acceder al constructor
1. Ingresa al panel de **Administración**
2. En el menú lateral, busca **"📋 Formularios (Nuevo)"**
3. Haz clic para abrir el constructor

### Paso 2: Seleccionar convocatoria
1. En la parte superior, verás un selector de convocatoria
2. Selecciona la convocatoria para la cual quieres crear/editar el formulario
3. Si ya existe un formulario, se cargará automáticamente
4. Si no existe, verás una página en blanco lista para diseñar

### Paso 3: Crear una sección
Las secciones agrupan campos relacionados (ej: "Datos Personales", "Antecedentes Académicos")

1. Haz clic en **"Añadir nueva sección"** (botón punteado al final)
2. Haz clic en el título "Nueva sección" para editarlo
3. Escribe el nombre de tu sección (ej: "Datos Personales")
4. Opcionalmente, agrega una descripción

**Opciones de sección:**
- 🗑️ **Eliminar**: Borra la sección completa
- 📋 **Duplicar**: Crea una copia de la sección
- 🔼🔽 **Expandir/Colapsar**: Oculta o muestra los campos

### Paso 4: Añadir campos
1. Dentro de una sección, haz clic en **"Añadir campo"**
2. Se abrirá un menú con todos los tipos de campo disponibles
3. Selecciona el tipo que necesitas:

#### Tipos de campo disponibles:

| Icono | Tipo | ¿Cuándo usarlo? |
|-------|------|----------------|
| 📝 | **Texto corto** | Nombres, RUT, teléfono, email |
| 📄 | **Texto largo** | Descripciones, comentarios, motivación |
| #️⃣ | **Número** | Edad, cantidad, puntaje |
| 💯 | **Decimal** | Promedio (ej: 6.5), porcentajes |
| 📅 | **Fecha** | Fecha de nacimiento, fecha de inicio |
| 📋 | **Lista desplegable** | Comuna, región, nivel educativo |
| ⭕ | **Opción única** | Sí/No, Género, Estado civil |
| ☑️ | **Múltiple opción** | Intereses, habilidades, idiomas |
| 📎 | **Archivo** | PDFs, documentos, certificados |
| 🖼️ | **Imagen** | Foto de perfil, comprobantes escaneados |

### Paso 5: Configurar un campo
Cuando agregas un campo, automáticamente se abre el editor:

1. **Etiqueta** ⭐ (obligatorio): Lo que verá el usuario (ej: "Nombres completos")
2. **Nombre interno** ⭐ (obligatorio): Identificador técnico (ej: `nombres_completos`)
   - Se genera automáticamente desde la etiqueta
   - Solo usa letras, números y guión bajo
3. **Texto de ayuda**: Instrucciones adicionales (ej: "Ingresa tus nombres como aparecen en tu cédula")
4. **Placeholder**: Ejemplo dentro del campo (ej: "Juan Pablo García")

**Opciones adicionales:**
- ☑️ **Campo obligatorio**: El usuario DEBE llenar este campo para enviar el formulario
- ☑️ **Visible**: Si está desmarcado, el campo se oculta (útil para desactivar temporalmente)
- ☑️ **Solo lectura**: El usuario puede ver pero no editar (para campos prellenados)

### Paso 6: Configurar opciones (para select, radio, checkbox)
Si elegiste un campo de tipo **lista**, **opción única** o **múltiple opción**:

1. Verás la sección **"Opciones"**
2. Haz clic en **"Añadir opción"**
3. Escribe la etiqueta de cada opción
4. Usa el botón 🗑️ para eliminar opciones que no necesites

**Ejemplo:**
```
Campo: "Nivel educativo"
Tipo: Lista desplegable
Opciones:
  1. Educación Básica
  2. Educación Media
  3. Técnico Profesional
  4. Universitario
  5. Postgrado
```

### Paso 7: Vista previa
1. Haz clic en el botón **"Vista previa"** arriba a la derecha
2. Verás exactamente cómo se verá el formulario para los usuarios
3. Haz clic de nuevo en "Editar" para seguir modificando

### Paso 8: Guardar cambios
1. Cuando termines de editar, haz clic en **"Guardar cambios"**
2. Verás un mensaje de confirmación
3. ¡Listo! El formulario ya está disponible para las postulaciones

---

## 🎨 Consejos de diseño

### ✅ Buenas prácticas

1. **Agrupa campos relacionados en secciones**
   - ✅ "Datos Personales": nombre, RUT, email, teléfono
   - ✅ "Datos Académicos": colegio, promedio, año de egreso
   - ✅ "Antecedentes Familiares": composición familiar, ingresos

2. **Usa etiquetas claras y simples**
   - ✅ "Nombres completos" en vez de "Name"
   - ✅ "Fecha de nacimiento" en vez de "Birth Date"

3. **Agrega texto de ayuda para campos que puedan confundir**
   - ✅ "RUT" → "Ingresa tu RUT sin puntos y con guión (ej: 12345678-9)"
   - ✅ "Promedio" → "Promedio de notas del último año cursado"

4. **Marca como obligatorios solo los campos esenciales**
   - No marques todo como obligatorio
   - Deja opcionales campos complementarios

5. **Usa el tipo de campo correcto**
   - ❌ No uses "texto" para fechas
   - ❌ No uses "texto largo" para nombres
   - ✅ Usa el tipo específico para cada dato

### ⚠️ Errores comunes a evitar

1. ❌ **Nombre interno con espacios o tildes**
   - Malo: `Nombre Completo`
   - Bueno: `nombre_completo`

2. ❌ **Demasiadas secciones vacías**
   - Elimina secciones que no estés usando

3. ❌ **Campos duplicados**
   - Verifica que no hayas duplicado campos por error

4. ❌ **No guardar los cambios**
   - Siempre haz clic en "Guardar cambios" antes de salir

---

## 🆘 Solución de problemas

### "No veo mi convocatoria en el selector"
- Verifica que la convocatoria esté creada en el módulo de **Convocatorias**
- Recarga la página (F5)

### "Los campos no se guardan"
- Asegúrate de hacer clic en "Listo" al configurar un campo
- Luego haz clic en "Guardar cambios" arriba

### "El nombre interno tiene caracteres raros"
- El sistema automáticamente convierte espacios en guiones bajos
- Evita usar tildes, ñ, o caracteres especiales

### "¿Cómo elimino un campo?"
1. Busca el campo en su sección
2. Haz clic en el ícono 🗑️ a la derecha del campo
3. Confirma la eliminación

### "¿Puedo deshacer cambios?"
- El sistema guarda solo cuando haces clic en "Guardar cambios"
- Si cometiste un error, simplemente recarga la página (F5) antes de guardar

---

## 📊 Comparación: Antiguo vs Nuevo

| Característica | Antiguo ❌ | Nuevo ✅ |
|---------------|-----------|---------|
| **Interfaz** | Código JSON | Visual e intuitiva |
| **Edición** | Texto plano | Drag & drop + clicks |
| **Vista previa** | No | Sí, en tiempo real |
| **Iconos** | No | Sí, con colores |
| **Ayuda** | No | Panel lateral siempre visible |
| **Validación** | Manual | Automática |
| **Curva aprendizaje** | Alta | Baja |

---

## 🎯 Ejemplo completo paso a paso

### Caso: Formulario de Postulación a Beca

#### Sección 1: Datos Personales
```
✏️ Nombres completos (texto corto, obligatorio)
✏️ Apellidos (texto corto, obligatorio)
✏️ RUT (texto corto, obligatorio)
   💡 Ayuda: "Sin puntos, con guión (12345678-9)"
✏️ Email (texto corto, obligatorio)
✏️ Teléfono (texto corto, obligatorio)
📅 Fecha de nacimiento (fecha, obligatorio)
```

#### Sección 2: Antecedentes Académicos
```
📋 Establecimiento educacional (lista, obligatorio)
   Opciones: [Cargar desde tabla institutions]
💯 Promedio de notas (decimal, obligatorio)
   💡 Ayuda: "Promedio del último año cursado"
📅 Año de egreso (fecha, obligatorio)
```

#### Sección 3: Documentación
```
🖼️ Foto 3x4 (imagen, obligatorio)
📎 Certificado de notas (archivo, obligatorio)
📎 Comprobante de ingresos (archivo, opcional)
```

---

## 💡 Preguntas frecuentes

**¿Puedo editar un formulario que ya tiene respuestas?**
Sí, pero ten cuidado:
- Puedes agregar nuevos campos
- Puedes editar etiquetas y textos de ayuda
- ❌ NO cambies el "nombre interno" de campos existentes
- ❌ NO elimines campos que ya tienen respuestas

**¿Los cambios afectan postulaciones anteriores?**
- Los cambios NO afectan formularios ya enviados
- Solo afectan postulaciones nuevas en estado DRAFT

**¿Puedo copiar un formulario de un año anterior?**
- En el antiguo form builder hay una opción de "clonar"
- En el nuevo, próximamente agregaremos esta función

**¿Cuántos campos puedo tener?**
- No hay límite, pero se recomienda:
  - Máximo 30-40 campos por formulario
  - 5-8 secciones máximo

---

## 📞 ¿Necesitas ayuda?

Si tienes dudas o encuentras problemas:
1. Revisa esta guía
2. Verifica el panel de ayuda lateral (tiene recordatorios rápidos)
3. Contacta al equipo de soporte técnico

---

_Última actualización: Noviembre 2025_
