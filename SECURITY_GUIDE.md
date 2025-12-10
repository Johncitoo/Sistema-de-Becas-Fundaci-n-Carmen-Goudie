# 🛡️ Guía de Seguridad para Desarrolladores

## 🎯 Principios de Seguridad

### 1. **Defensa en Profundidad**
No confíes en una sola capa de seguridad. Implementa múltiples controles.

### 2. **Principio de Mínimo Privilegio**
Los usuarios y servicios solo deben tener los permisos mínimos necesarios.

### 3. **Seguridad por Defecto**
La configuración predeterminada debe ser segura.

### 4. **Fallar de Forma Segura**
En caso de error, el sistema debe fallar de manera que no comprometa la seguridad.

---

## 🔒 Mejores Prácticas por Área

### **Autenticación y Autorización**

#### ✅ DO - Hacer
```typescript
// Verificar rol del usuario
if (!['admin', 'reviewer'].includes(user.role)) {
  return res.status(403).json({ error: 'Acceso denegado' });
}

// Usar bcrypt para contraseñas
const hashedPassword = await bcrypt.hash(password, 10);

// Tokens con expiración
const token = jwt.sign({ userId }, SECRET, { expiresIn: '1h' });
```

#### ❌ DON'T - No hacer
```typescript
// ❌ No confiar solo en el frontend
if (userRole === 'admin') { // Esto se puede manipular

// ❌ No almacenar contraseñas en texto plano
await pool.query('INSERT INTO users VALUES (?, ?)', [username, password]);

// ❌ No usar tokens sin expiración
const token = jwt.sign({ userId }, SECRET); // Sin expiresIn
```

---

### **Protección contra Inyección SQL**

#### ✅ DO - Usar consultas parametrizadas
```typescript
// ✅ SEGURO - PostgreSQL
const result = await pool.query(
  'SELECT * FROM users WHERE email = $1 AND password = $2',
  [email, hashedPassword]
);

// ✅ SEGURO - Validación adicional
const email = validator.normalizeEmail(req.body.email);
if (!validator.isEmail(email)) {
  return res.status(400).json({ error: 'Email inválido' });
}
```

#### ❌ DON'T - Concatenación directa
```typescript
// ❌ VULNERABLE a SQL Injection
const query = `SELECT * FROM users WHERE email = '${email}'`;
await pool.query(query);

// ❌ VULNERABLE - Interpolación de strings
const query = `DELETE FROM users WHERE id = ${userId}`;
```

---

### **Protección contra XSS (Cross-Site Scripting)**

#### ✅ DO - Escapar y sanitizar
```typescript
import DOMPurify from 'dompurify';

// ✅ Sanitizar HTML
const cleanHTML = DOMPurify.sanitize(userInput);

// ✅ Usar textContent en lugar de innerHTML
element.textContent = userInput; // Seguro

// ✅ React escapa por defecto
<p>{userInput}</p> // Seguro en React
```

#### ❌ DON'T - Insertar HTML directamente
```typescript
// ❌ VULNERABLE a XSS
element.innerHTML = userInput;

// ❌ VULNERABLE - dangerouslySetInnerHTML sin sanitizar
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// ❌ VULNERABLE - eval()
eval(userInput); // ¡Nunca uses eval!
```

---

### **Manejo Seguro de Archivos**

#### ✅ DO - Validar y restringir
```typescript
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'application/pdf'];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

// ✅ Validar tipo y tamaño
if (!ALLOWED_TYPES.includes(file.mimetype)) {
  return res.status(400).json({ error: 'Tipo de archivo no permitido' });
}

if (file.size > MAX_SIZE) {
  return res.status(400).json({ error: 'Archivo demasiado grande' });
}

// ✅ Generar nombre de archivo aleatorio
const filename = `${uuidv4()}.${extension}`;
```

#### ❌ DON'T - Confiar en el cliente
```typescript
// ❌ VULNERABLE - Usar nombre original sin validar
const filename = file.originalname; // Puede ser ../../../etc/passwd

// ❌ No verificar tipo de archivo
await saveFile(file); // Sin validación

// ❌ Permitir cualquier tamaño
// Sin límite de tamaño = DoS attack
```

---

### **Gestión de Secretos**

#### ✅ DO - Variables de entorno
```typescript
// ✅ .env (NO commitear al repositorio)
DATABASE_URL=postgresql://user:pass@localhost:5432/db
JWT_SECRET=tu_secreto_super_seguro_aleatorio_largo
API_KEY=tu_api_key_secreta

// ✅ Usar en código
const secret = process.env.JWT_SECRET;
if (!secret) {
  throw new Error('JWT_SECRET no configurado');
}

// ✅ .gitignore
.env
.env.local
.env.production
```

#### ❌ DON'T - Hard-coded secrets
```typescript
// ❌ VULNERABLE - Secretos en código
const JWT_SECRET = 'mysecret123'; // ¡Nunca!
const API_KEY = 'sk_live_abc123xyz'; // ¡Nunca!

// ❌ VULNERABLE - Commitear .env
git add .env // ¡NUNCA HAGAS ESTO!
```

---

### **Protección CSRF (Cross-Site Request Forgery)**

#### ✅ DO - Usar tokens CSRF
```typescript
import csrf from 'csurf';

// ✅ Middleware CSRF
const csrfProtection = csrf({ cookie: true });
app.use(csrfProtection);

// ✅ Enviar token al frontend
app.get('/form', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// ✅ Verificar en POST
app.post('/submit', csrfProtection, (req, res) => {
  // Token verificado automáticamente
});
```

#### ❌ DON'T - Ignorar CSRF
```typescript
// ❌ VULNERABLE - Sin protección CSRF
app.post('/delete-account', (req, res) => {
  // Cualquier sitio puede hacer esta request
  await deleteUser(req.user.id);
});
```

---

### **Rate Limiting y DoS Prevention**

#### ✅ DO - Limitar requests
```typescript
import rateLimit from 'express-rate-limit';

// ✅ Rate limiting global
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // 100 requests por ventana
  message: 'Demasiadas solicitudes, intenta más tarde'
});
app.use(limiter);

// ✅ Rate limiting específico para login
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // Solo 5 intentos de login
  skipSuccessfulRequests: true
});
app.post('/login', loginLimiter, loginHandler);
```

---

### **Logging y Monitoreo**

#### ✅ DO - Log eventos de seguridad
```typescript
// ✅ Log de autenticación fallida
logger.warn('Login fallido', {
  email: email,
  ip: req.ip,
  timestamp: new Date()
});

// ✅ Log de acciones administrativas
logger.info('Usuario eliminado', {
  adminId: req.user.id,
  targetUserId: userId,
  timestamp: new Date()
});
```

#### ❌ DON'T - Log información sensible
```typescript
// ❌ VULNERABLE - Logear contraseñas
logger.info('Login', { email, password }); // ¡Nunca!

// ❌ VULNERABLE - Logear tokens
logger.debug('Token:', token); // ¡No!
```

---

## 🧪 Testing de Seguridad

### Checklist antes de cada Pull Request

- [ ] No hay credenciales hard-coded
- [ ] Todas las inputs están validadas
- [ ] Se usan consultas parametrizadas
- [ ] Headers de seguridad configurados
- [ ] Rate limiting implementado donde corresponde
- [ ] Logs no contienen información sensible
- [ ] Errores no exponen detalles del sistema
- [ ] CSRF protection habilitado
- [ ] Autenticación verificada en todas las rutas protegidas
- [ ] Autorización (roles) verificada donde corresponde

---

## 🚨 Qué hacer si encuentras una vulnerabilidad

1. **NO** commitees el código vulnerable
2. **NO** abras un issue público
3. Informa inmediatamente al equipo de seguridad
4. Documenta los pasos para reproducir
5. Propón una solución si es posible

---

## 📚 Recursos Recomendados

- [OWASP Top 10](https://owasp.org/Top10/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)
- [React Security Best Practices](https://react.dev/learn/security)

---

**Recuerda**: La seguridad es responsabilidad de todo el equipo. 🛡️
