# 🚨 Script de Seguridad Urgente
# Ejecutar INMEDIATAMENTE después de cambiar password en Railway

Write-Host "========================================" -ForegroundColor Red
Write-Host "  REMEDIACION DE CREDENCIALES EXPUESTAS" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Verificar que estamos en la carpeta correcta
$currentPath = Get-Location
if (-not (Test-Path "backend")) {
    Write-Host "❌ ERROR: Debe ejecutar este script desde la raíz del proyecto" -ForegroundColor Red
    Write-Host "   Carpeta actual: $currentPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Ubicación correcta verificada" -ForegroundColor Green
Write-Host ""

# Paso 1: Crear carpeta para scripts inseguros
Write-Host "[1/5] Creando carpeta scripts-inseguros..." -ForegroundColor Cyan
$scriptsFolder = "backend/scripts-inseguros"

if (-not (Test-Path $scriptsFolder)) {
    New-Item -ItemType Directory -Path $scriptsFolder -Force | Out-Null
    Write-Host "✓ Carpeta creada: $scriptsFolder" -ForegroundColor Green
} else {
    Write-Host "⚠ Carpeta ya existe: $scriptsFolder" -ForegroundColor Yellow
}
Write-Host ""

# Paso 2: Mover archivos .js con credenciales
Write-Host "[2/5] Moviendo scripts con credenciales hardcodeadas..." -ForegroundColor Cyan

$jsFiles = Get-ChildItem -Path "backend" -Filter "*.js" -File
$movedCount = 0

foreach ($file in $jsFiles) {
    # Leer contenido para verificar si tiene credenciales
    $content = Get-Content $file.FullName -Raw
    
    if ($content -match "postgresql://postgres:[^@]+@" -or 
        $content -match "rejectUnauthorized: false") {
        
        $destinationPath = Join-Path $scriptsFolder $file.Name
        Move-Item -Path $file.FullName -Destination $destinationPath -Force
        Write-Host "  → Movido: $($file.Name)" -ForegroundColor Yellow
        $movedCount++
    }
}

Write-Host "✓ Archivos movidos: $movedCount" -ForegroundColor Green
Write-Host ""

# Paso 3: Actualizar .gitignore
Write-Host "[3/5] Actualizando .gitignore..." -ForegroundColor Cyan

$gitignorePath = ".gitignore"
$gitignoreContent = ""

if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
}

$entriesToAdd = @(
    "# Scripts inseguros con credenciales hardcodeadas",
    "backend/scripts-inseguros/",
    "",
    "# Environment variables",
    ".env",
    ".env.local",
    ".env.*.local"
)

$needsUpdate = $false
foreach ($entry in $entriesToAdd) {
    if ($gitignoreContent -notmatch [regex]::Escape($entry)) {
        $needsUpdate = $true
        break
    }
}

if ($needsUpdate) {
    Add-Content -Path $gitignorePath -Value "`n$($entriesToAdd -join "`n")"
    Write-Host "✓ .gitignore actualizado" -ForegroundColor Green
} else {
    Write-Host "⚠ .gitignore ya contiene las entradas" -ForegroundColor Yellow
}
Write-Host ""

# Paso 4: Crear .env.example
Write-Host "[4/5] Creando backend/.env.example..." -ForegroundColor Cyan

$envExamplePath = "backend/.env.example"
$envExampleContent = @"
# ========================================
# Backend - Environment Variables Template
# ========================================

# Database
DATABASE_URL=postgresql://user:password@host:port/database
DATABASE_SSL=true

# JWT Secrets
AUTH_JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
AUTH_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production

# Email Configuration
EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_USER=your-email@example.com
EMAIL_PASS=your-email-password
EMAIL_FROM=noreply@example.com

# Storage Service
STORAGE_SERVICE_URL=http://localhost:3001

# CORS Origins (comma-separated)
CORS_ORIGINS=http://localhost:5173,http://localhost:3000

# Environment
NODE_ENV=development

# Server
PORT=3000

# ========================================
# IMPORTANTE: 
# 1. Copiar este archivo como .env
# 2. Reemplazar TODOS los valores de ejemplo
# 3. NUNCA commitear el archivo .env real
# ========================================
"@

Set-Content -Path $envExamplePath -Value $envExampleContent
Write-Host "✓ Archivo creado: $envExamplePath" -ForegroundColor Green
Write-Host ""

# Paso 5: Crear script template seguro
Write-Host "[5/5] Creando template de script seguro..." -ForegroundColor Cyan

$templatePath = "backend/script-template-seguro.js"
$templateContent = @"
/**
 * ✅ TEMPLATE DE SCRIPT SEGURO
 * 
 * Este template muestra cómo crear scripts de DB SIN credenciales hardcodeadas
 * 
 * NUNCA uses credenciales directamente en el código:
 * ❌ const url = 'postgresql://postgres:password@host/db'
 * 
 * SIEMPRE usa variables de entorno:
 * ✅ const url = process.env.DATABASE_URL
 */

// Cargar variables de entorno
require('dotenv').config();
const { Pool } = require('pg');

// ✅ CORRECTO: Leer desde variable de entorno
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  
  // ✅ CORRECTO: SSL habilitado en producción, deshabilitado en dev
  ssl: process.env.NODE_ENV === 'production' 
    ? { rejectUnauthorized: true }  // Valida certificado en prod
    : false  // Sin SSL en desarrollo local
});

/**
 * Función principal del script
 */
async function main() {
  const client = await pool.connect();
  
  try {
    console.log('📊 Conectado a la base de datos');
    
    // ✅ CORRECTO: Usar prepared statements (previene SQL injection)
    const result = await client.query(
      'SELECT id, name, email FROM users WHERE role = `$1` LIMIT `$2`',
      ['ADMIN', 10]
    );
    
    console.log('Usuarios encontrados:', result.rows.length);
    console.log(result.rows);
    
    // ❌ INCORRECTO (SQL Injection vulnerable):
    // const id = req.query.id;
    // await client.query(`SELECT * FROM users WHERE id = '`${id}`'`);
    
    // ✅ CORRECTO (Safe):
    // await client.query('SELECT * FROM users WHERE id = `$1`', [id]);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
    console.log('✓ Conexión cerrada');
  }
}

// Ejecutar y manejar errores
main()
  .then(() => {
    console.log('✓ Script completado exitosamente');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script falló:', error);
    process.exit(1);
  });

/**
 * PARA EJECUTAR ESTE SCRIPT:
 * 
 * Opción 1: Con .env file
 * $ node backend/script-template-seguro.js
 * 
 * Opción 2: Con Railway CLI (inyecta vars automáticamente)
 * $ railway run node backend/script-template-seguro.js
 * 
 * Opción 3: Con variables inline
 * $ DATABASE_URL="postgresql://..." node backend/script-template-seguro.js
 */
"@

Set-Content -Path $templatePath -Value $templateContent
Write-Host "✓ Archivo creado: $templatePath" -ForegroundColor Green
Write-Host ""

# Resumen final
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ REMEDIACION COMPLETADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Archivos movidos:     $movedCount scripts" -ForegroundColor Yellow
Write-Host "Carpeta creada:       backend/scripts-inseguros/" -ForegroundColor Yellow
Write-Host ".gitignore:           ✓ Actualizado" -ForegroundColor Yellow
Write-Host ".env.example:         ✓ Creado" -ForegroundColor Yellow
Write-Host "Template seguro:      ✓ Creado" -ForegroundColor Yellow
Write-Host ""

# Siguientes pasos
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SIGUIENTES PASOS CRÍTICOS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 🔴 CAMBIAR PASSWORD EN RAILWAY (si no lo hiciste)" -ForegroundColor Red
Write-Host "   → Railway.app → Proyecto → Variables → DATABASE_URL → Regenerate" -ForegroundColor White
Write-Host ""
Write-Host "2. ✅ Verificar archivos movidos" -ForegroundColor Yellow
Write-Host "   → cd backend/scripts-inseguros" -ForegroundColor White
Write-Host "   → ls" -ForegroundColor White
Write-Host ""
Write-Host "3. ✅ Commit los cambios" -ForegroundColor Yellow
Write-Host "   → git add .gitignore backend/.env.example backend/script-template-seguro.js" -ForegroundColor White
Write-Host "   → git commit -m `"security: remove hardcoded credentials from scripts`"" -ForegroundColor White
Write-Host ""
Write-Host "4. ⚠️  Regenerar JWT secrets" -ForegroundColor Yellow
Write-Host "   → En Railway: AUTH_JWT_SECRET = <nuevo-valor-random>" -ForegroundColor White
Write-Host "   → AUTH_REFRESH_SECRET = <otro-valor-random>" -ForegroundColor White
Write-Host ""
Write-Host "5. 📝 Para crear nuevos scripts:" -ForegroundColor Yellow
Write-Host "   → Usar backend/script-template-seguro.js como base" -ForegroundColor White
Write-Host "   → SIEMPRE usar process.env.DATABASE_URL" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "Script completado. Presiona cualquier tecla para salir..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@
