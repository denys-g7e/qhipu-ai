@echo off
echo ========================================
echo  Qhipu AI - Setup Automatico
echo ========================================
echo.
echo PASO 1: Verificando Flutter...
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [X] Flutter no encontrado.
    echo     Descargalo de: https://docs.flutter.dev/get-started/install/windows
    echo     Extraer en C:\flutter y agrega C:\flutter\bin al PATH
    pause
    exit /b
)
echo [OK] Flutter encontrado
echo.
echo PASO 2: Configurar Firebase
echo.
echo Crea un proyecto en https://console.firebase.google.com
echo 1. Registra app Android con package "com.qhipu.qhipu_ai"
echo 2. Descarga google-services.json
echo 3. COLOCALO en: android\app\google-services.json
echo 4. Activa Authentication ^> Anonimo
echo 5. Activa Firestore Database en modo prueba
echo.
echo PASO 3: Configurar Groq
echo API Key ya incluida en lib\core\groq_service.dart
echo.
echo PASO 4: Instalar dependencias
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [X] Error en flutter pub get
    pause
    exit /b
)
echo [OK] Dependencias instaladas
echo.
echo PASO 5: Ejecutar!
echo.
echo Para correr la app:
echo   flutter run --release
echo.
echo Para generar APK:
echo   flutter build apk --split-per-abi
echo.
echo MODO DEMO: Toca el logo 5 veces en el splash!
echo.
pause
