Write-Host "=== Qhipu AI Setup ===" -ForegroundColor Green
Write-Host ""

# Step 1: Verificar Flutter
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "ERROR: Flutter no encontrado. Instalalo desde:" -ForegroundColor Red
    Write-Host "https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK: Flutter encontrado" -ForegroundColor Green

# Step 2: Verificar que google-services.json existe
if (-not (Test-Path "android\app\google-services.json")) {
    Write-Host "AVISO: google-services.json no encontrado." -ForegroundColor Yellow
    Write-Host "  Crea un proyecto en https://console.firebase.google.com" -ForegroundColor Yellow
    Write-Host "  y coloca google-services.json en android/app/" -ForegroundColor Yellow
}

# Step 3: Instalar dependencias
Write-Host ""
Write-Host "Instalando dependencias..." -ForegroundColor Cyan
flutter pub get
if ($?) {
    Write-Host "OK: Dependencias instaladas" -ForegroundColor Green
} else {
    Write-Host "ERROR: Fallo flutter pub get" -ForegroundColor Red
    exit 1
}

# Step 4: Verificar ambiente
Write-Host ""
Write-Host "Verificando ambiente Flutter..." -ForegroundColor Cyan
flutter doctor --android-licenses 2>$null
flutter doctor
Write-Host ""
Write-Host "=== Setup completo ===" -ForegroundColor Green
Write-Host ""
Write-Host "Para ejecutar la app:" -ForegroundColor Cyan
Write-Host "  flutter run --release" -ForegroundColor White
Write-Host ""
Write-Host "Para generar APK:" -ForegroundColor Cyan
Write-Host "  flutter build apk --split-per-abi" -ForegroundColor White
Write-Host ""
Write-Host "Demo rapida:" -ForegroundColor Cyan
Write-Host "  Toca el logo 5 veces en el splash para activar modo demo" -ForegroundColor White
