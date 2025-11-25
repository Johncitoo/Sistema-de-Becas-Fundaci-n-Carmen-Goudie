# 📝 Nuevo Diseñador de Formularios - Guía Super Simple

## 🎯 ¿Qué mejoró?

Rediseñamos **COMPLETAMENTE** el constructor de formularios pensando en personas que NO son técnicas. 

### ❌ Antes:
- Términos técnicos: "nombre interno", "tipo", "step", "min/max"
- Interfaz confusa
- No estaba integrado con hitos
- Duplicación de configuración de "tipo"

### ✅ Ahora:
- **Lenguaje simple**: "Pregunta", "Respuesta obligatoria"
- **Visual e intuitivo**: Iconos grandes, descripciones claras
- **Integrado con hitos**: Cada hito tiene su formulario
- **Sin repeticiones**: Eliges el tipo UNA vez

---

## 🚀 Cómo funciona (3 pasos)

### Paso 1: Selecciona convocatoria e hito
```
1. Selecciona la convocatoria → Ej: "Becas 2025"
2. Selecciona el hito → Ej: "1. Formulario de postulación ✅"
   (El ✅ indica que ya tiene formulario)
```

### Paso 2: Diseña tu formulario

#### A. Agregar secciones
Las secciones agrupan preguntas relacionadas:
- Haz clic en **"Añadir nueva sección"**
- Escribe el título: Ej: "Datos Personales"
- Opcionalmente agrega una descripción

#### B. Agregar preguntas
- Dentro de una sección, haz clic en **"Añadir pregunta"**
- Se abre un menú visual con tipos de pregunta:

```
📝 Texto corto → Para nombres, RUT, email
   "Para nombres, RUT, email, teléfono"

📄 Texto largo → Para descripciones largas
   "Para descripciones, comentarios"

🔢 Número → Para cantidades
   "Para edad, cantidad, puntaje"

📅 Fecha → Para fechas
   "Para fecha de nacimiento, etc"

📋 Lista de opciones → Selector dropdown
   "Elegir una opción de una lista"

⭕ Sí/No o múltiples opciones → Radio buttons
   "Elegir solo una opción"

☑️ Varias opciones → Checkboxes
   "Elegir varias opciones"

📎 Subir archivo → Para PDFs, documentos
   "Para PDF, Word, etc"

🖼️ Subir imagen → Para fotos
   "Para fotos, comprobantes"
```

#### C. Configurar cada pregunta
Cuando agregas una pregunta, se abre el editor:

**Campos principales:**
1. **Pregunta** ⭐ (obligatorio)
   - Lo que verá el usuario
   - Ejemplo: "¿Cuál es tu nombre completo?"

2. **Texto de ayuda** (opcional)
   - Instrucciones adicionales
   - Ejemplo: "Ingresa tu nombre como aparece en tu cédula"

3. **Ejemplo** (opcional, solo para texto)
   - Se muestra dentro del campo vacío
   - Ejemplo: "Juan Pérez García"

4. **Opciones de respuesta** (solo para listas/múltiples opciones)
   - Define las opciones disponibles
   - Ejemplo: Opción 1: "Sí", Opción 2: "No"

5. **Respuesta obligatoria** ☑️
   - Marca si el usuario DEBE responder
   - Campos obligatorios muestran un asterisco rojo (*)

### Paso 3: Guardar
- Haz clic en **"Guardar formulario"** arriba a la derecha
- ¡Listo! El formulario queda asociado al hito

---

## 💡 Ejemplos prácticos

### Ejemplo 1: Sección "Datos Personales"

```
Sección: Datos Personales
Descripción: Completa con tus datos tal como aparecen en tu cédula

Pregunta 1:
  Tipo: 📝 Texto corto
  Pregunta: ¿Cuál es tu nombre completo?
  Ayuda: Ingresa tus nombres y apellidos
  Ejemplo: Juan Pablo Pérez García
  ☑️ Respuesta obligatoria

Pregunta 2:
  Tipo: 📝 Texto corto
  Pregunta: ¿Cuál es tu RUT?
  Ayuda: Sin puntos, con guión (12345678-9)
  Ejemplo: 12345678-9
  ☑️ Respuesta obligatoria

Pregunta 3:
  Tipo: 📅 Fecha
  Pregunta: ¿Cuál es tu fecha de nacimiento?
  ☑️ Respuesta obligatoria
```

### Ejemplo 2: Sección "Antecedentes Académicos"

```
Sección: Antecedentes Académicos

Pregunta 1:
  Tipo: 📋 Lista de opciones
  Pregunta: ¿En qué establecimiento estudias?
  Opciones:
    1. Liceo A-1
    2. Liceo B-2
    3. Colegio San José
    4. Otro
  ☑️ Respuesta obligatoria

Pregunta 2:
  Tipo: 🔢 Número
  Pregunta: ¿Cuál es tu promedio de notas?
  Ayuda: Promedio del último año (escala 1-7)
  ☑️ Respuesta obligatoria

Pregunta 3:
  Tipo: ☑️ Varias opciones
  Pregunta: ¿Qué materias te interesan? (puedes elegir varias)
  Opciones:
    1. Matemáticas
    2. Lenguaje
    3. Ciencias
    4. Historia
    5. Artes
  ☐ Opcional
```

### Ejemplo 3: Sección "Documentos"

```
Sección: Documentos requeridos
Descripción: Sube los documentos solicitados en formato PDF o imagen

Pregunta 1:
  Tipo: 🖼️ Subir imagen
  Pregunta: Foto tamaño carnet (3x4)
  Ayuda: Fondo blanco, formato JPG o PNG
  ☑️ Respuesta obligatoria

Pregunta 2:
  Tipo: 📎 Subir archivo
  Pregunta: Certificado de notas
  Ayuda: PDF del último año cursado
  ☑️ Respuesta obligatoria

Pregunta 3:
  Tipo: 📎 Subir archivo
  Pregunta: Comprobante de ingresos familiares
  Ayuda: Opcional - Solo si aplica
  ☐ Opcional
```

---

## ✨ Características clave

### 1. Sin términos técnicos
❌ Antes: "Nombre interno", "fieldType", "step"
✅ Ahora: "Pregunta", "Texto de ayuda", "Respuesta obligatoria"

### 2. Vista previa en tiempo real
- Botón **"Ver vista previa"**
- Ves exactamente cómo se verá para el usuario
- Vuelve a "Previsualizando" para seguir editando

### 3. Integración con hitos
- Cada hito tiene su propio formulario
- El ✅ indica que el hito ya tiene formulario configurado
- Los formularios se guardan automáticamente vinculados al hito

### 4. Interfaz visual clara
- Iconos grandes y descriptivos
- Colores para diferenciar tipos
- Descripciones de cada opción
- Ejemplos de uso

### 5. Edición intuitiva
- Haz clic en cualquier pregunta para editarla
- Se destaca con borde azul
- Botón "Listo" para terminar de editar

---

## 🎨 Flujo completo de trabajo

```
1. Admin entra a "Formularios" (/admin/formularios)
   ↓
2. Selecciona convocatoria "Becas 2025"
   ↓
3. Selecciona hito "1. Formulario de postulación"
   ↓
4. Crea secciones:
   - Datos Personales
   - Antecedentes Académicos
   - Documentación
   ↓
5. En cada sección, añade preguntas:
   - Clic en "Añadir pregunta"
   - Elige tipo (ej: 📝 Texto corto)
   - Configura la pregunta
   - Clic en "Listo"
   ↓
6. Vista previa para verificar
   ↓
7. Guarda el formulario
   ↓
8. ✅ El hito ahora tiene formulario configurado
   ↓
9. Los postulantes ven este formulario cuando
   completan ese hito de su postulación
```

---

## ⚠️ Cosas importantes

### ✅ Buenas prácticas

1. **Organiza bien las secciones**
   - Agrupa preguntas relacionadas
   - Ej: Todos los datos personales juntos

2. **Escribe preguntas claras**
   - ✅ "¿Cuál es tu nombre completo?"
   - ❌ "Nombre"

3. **Usa el texto de ayuda**
   - Explica formatos esperados
   - Ej: "Sin puntos, con guión"

4. **Marca obligatorias solo las esenciales**
   - No todo debe ser obligatorio
   - Deja opcionales los datos complementarios

5. **Da ejemplos**
   - Ayuda a entender qué se espera
   - Ej: placeholder "Juan Pérez"

### ❌ Errores comunes

1. **No guardar**
   - Siempre haz clic en "Guardar formulario"
   - Los cambios no se guardan automáticamente

2. **Demasiadas preguntas obligatorias**
   - Los usuarios abandonan formularios muy largos
   - Solo lo esencial como obligatorio

3. **Preguntas confusas**
   - Sin contexto o ayuda
   - Usa siempre el "Texto de ayuda"

4. **Olvidar la vista previa**
   - Siempre revisa cómo se ve
   - Ponte en el lugar del usuario

---

## 🔗 Integración con el sistema

### Cómo se relaciona todo:

```
Convocatoria "Becas 2025"
  └─ Hito 1: "Formulario de postulación" 📋
      └─ Formulario: "Datos del postulante"
          └─ Sección: "Datos Personales"
              └─ Pregunta: "Nombre completo"
  └─ Hito 2: "Documentos adicionales" 📎
      └─ Formulario: "Subida de documentos"
  └─ Hito 3: "Entrevista" 📅
      └─ Sin formulario (se agenda por email)
```

### Flujo del postulante:

```
1. Postulante se registra
   ↓
2. Ve sus hitos pendientes en el dashboard
   ↓
3. Clic en "Hito 1: Formulario de postulación"
   ↓
4. Completa el formulario que diseñaste
   ↓
5. Envía y el hito se marca como completado ✅
   ↓
6. Su barra de progreso avanza
```

---

## 🆘 Solución de problemas

### "No veo ningún hito para seleccionar"
**Solución:** 
1. Primero debes crear hitos para la convocatoria
2. Ve a "Convocatorias" → Selecciona la convocatoria
3. En la página de la convocatoria, crea los hitos
4. Luego vuelve a "Formularios"

### "Los cambios no se guardan"
**Solución:**
1. Verifica que hayas hecho clic en "Listo" al editar una pregunta
2. Luego haz clic en "Guardar formulario" arriba
3. Espera a ver el mensaje "✅ Formulario guardado"

### "¿Cómo elimino una pregunta?"
**Solución:**
- Haz clic en el ícono de papelera 🗑️ al lado de la pregunta
- Confirma la eliminación

### "¿Puedo reordenar preguntas?"
**Solución:**
- Actualmente no hay drag & drop
- Para reordenar: elimina y vuelve a crear en el orden deseado
- O edita el formulario en el modo avanzado (próximamente)

### "El formulario se ve diferente en vista previa"
**Solución:**
- La vista previa es exacta a cómo se verá para el usuario
- Si algo se ve mal, edita la pregunta y ajusta
- Revisa especialmente el texto de ayuda y ejemplos

---

## 📊 Comparación: Versiones

| Característica | Antiguo | Nuevo ✨ |
|---------------|---------|---------|
| **Lenguaje** | Técnico | Simple y claro |
| **Tipos de campo** | Texto "type" duplicado | Visual con íconos |
| **Configuración** | Múltiples campos técnicos | Solo lo esencial |
| **Hitos** | No integrado | ✅ Totalmente integrado |
| **Vista previa** | Separada | Integrada |
| **Términos** | "name", "label", "step" | "Pregunta", "Ayuda" |
| **Curva aprendizaje** | Alta ⚠️ | Muy baja ✅ |

---

## 💬 Preguntas frecuentes

**¿Puedo tener varios formularios por convocatoria?**
Sí, cada hito puede tener su propio formulario. Por ejemplo:
- Hito 1: Formulario de postulación
- Hito 2: Formulario de documentos adicionales
- Hito 3: Formulario de evaluación socioeconómica

**¿Los formularios se pueden reutilizar entre años?**
Actualmente no, pero está en desarrollo la función de "clonar formulario".

**¿Cuántas preguntas puedo poner?**
No hay límite técnico, pero se recomienda:
- Máximo 20-25 preguntas por formulario
- Divide formularios largos en varios hitos

**¿Se puede editar un formulario que ya tiene respuestas?**
Sí, pero con cuidado:
- ✅ Puedes agregar nuevas preguntas
- ✅ Puedes editar textos de ayuda
- ⚠️ No elimines preguntas con respuestas
- ⚠️ No cambies el tipo de pregunta si ya hay respuestas

**¿Cómo veo las respuestas de los postulantes?**
Ve a "Postulaciones" → Selecciona una postulación → Ver formulario completado

---

## 🎯 Resumen ejecutivo

### Lo que cambió:
1. ❌ Eliminados términos técnicos
2. ✅ Lenguaje simple y claro
3. ✅ Integración completa con hitos
4. ✅ Interfaz visual con iconos descriptivos
5. ✅ Sin duplicación de "tipo"
6. ✅ Vista previa integrada

### Acceso:
- Menú lateral → **"✨ Formularios"**
- URL: `/admin/formularios`

### Flujo simple:
```
Seleccionar convocatoria → Seleccionar hito → Diseñar formulario → Guardar
```

---

_Esta es la versión definitiva, diseñada para personas no técnicas._
_Última actualización: 25 de noviembre de 2025_
