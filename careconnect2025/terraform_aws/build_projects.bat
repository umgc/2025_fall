@echo off
setlocal enabledelayedexpansion

REM ==================================================
REM CareConnect Build Script (Backend + Frontend only)
REM Produces ZIP for Lambda (backend) and build folder (frontend)
REM ==================================================

REM Defaults
set "BUILD_BACKEND=true"
set "BUILD_FRONTEND=true"
set "SPRING_PROFILE=dev"
set "SKIP_TESTS=true"
set "MVN_FLAGS="
set "FLUTTER_FLAGS="
set "FLUTTER_MODE=release"
set "DIST_DIR="
set "BACKEND_DIR_NAME=backend\core"
set "FRONTEND_DIR_NAME=frontend"

REM Parse command line args
for %%A in (%*) do (
  if /I "%%~A"=="--backend-only" ( set "BUILD_FRONTEND=false" ) ^
  else if /I "%%~A"=="--frontend-only" ( set "BUILD_BACKEND=false" ) ^
  else if /I "%%~A"=="--skip-tests" ( set "SKIP_TESTS=true" ) ^
  else (
    echo %%~A | findstr /I /B "--profile=" >nul
    if not errorlevel 1 for /f "tokens=2 delims==" %%P in ("%%~A") do set "SPRING_PROFILE=%%P"

    echo %%~A | findstr /I /B "--mvn-flags=" >nul
    if not errorlevel 1 for /f "tokens=2* delims==" %%P in ("%%~A") do set "MVN_FLAGS=%%Q"

    echo %%~A | findstr /I /B "--flutter-flags=" >nul
    if not errorlevel 1 for /f "tokens=2* delims==" %%P in ("%%~A") do set "FLUTTER_FLAGS=%%Q"

    echo %%~A | findstr /I /B "--flutter-mode=" >nul
    if not errorlevel 1 for /f "tokens=2 delims==" %%P in ("%%~A") do set "FLUTTER_MODE=%%P"

    echo %%~A | findstr /I /B "--dist=" >nul
    if not errorlevel 1 for /f "tokens=2 delims==" %%P in ("%%~A") do set "DIST_DIR=%%P"
  )
)

REM Resolve paths
set "SCRIPT_DIR=%~dp0"
for %%A in ("%SCRIPT_DIR:~0,-1%") do set "PROJECT_ROOT=%%~dpA"
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

set "BACKEND_DIR=%PROJECT_ROOT%\%BACKEND_DIR_NAME%"
set "FRONTEND_DIR=%PROJECT_ROOT%\%FRONTEND_DIR_NAME%"
if "%DIST_DIR%"=="" set "DIST_DIR=%PROJECT_ROOT%\dist"

echo.
echo ==================================================
echo CareConnect Build Script
echo ==================================================
echo Project Root: %PROJECT_ROOT%
echo Backend Dir : %BACKEND_DIR%
echo Frontend Dir: %FRONTEND_DIR%
echo Dist Dir  : %DIST_DIR%
echo.
echo Options:
echo  BUILD_BACKEND = %BUILD_BACKEND%
echo  BUILD_FRONTEND = %BUILD_FRONTEND%
echo  SPRING_PROFILE = %SPRING_PROFILE%
echo  SKIP_TESTS   = %SKIP_TESTS%
echo  MVN_FLAGS   = %MVN_FLAGS%
echo  FLUTTER_MODE  = %FLUTTER_MODE%
echo  FLUTTER_FLAGS = %FLUTTER_FLAGS%
echo ==================================================
echo.

REM Prereqs
if /I "%BUILD_BACKEND%"=="true" (
 where mvn >nul 2>&1 || ( echo [ERROR] Maven is not installed or not in PATH & exit /b 1 )
 echo [SUCCESS] Maven is installed
)
if /I "%BUILD_FRONTEND%"=="true" (
 where flutter >nul 2>&1 || ( echo [ERROR] Flutter is not installed or not in PATH & exit /b 1 )
 echo [SUCCESS] Flutter is installed
)
if /I "%BUILD_BACKEND%"=="true" (
 where powershell >nul 2>&1 || ( echo [ERROR] PowerShell is required for zipping & exit /b 1 )
)

REM Ensure dist dir
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%" >nul 2>&1

REM ==================================
REM Load Flutter --dart-define flags
REM ==================================
set "DART_DEFINES="
if /I "%BUILD_FRONTEND%"=="true" (
 set "ENV_FILE=%SCRIPT_DIR%build.%SPRING_PROFILE%.env"
 echo [INFO] Checking for Flutter env file: !ENV_FILE!
 if not exist "!ENV_FILE!" (
  echo [WARN] Environment file not found. Flutter build will use defaults.
  echo [WARN] To pass variables, create !ENV_FILE! with lines like:
  echo [WARN] BACKEND_URL=https://...
  echo [WARN] JWT_SECRET=...
 ) else (
  echo [INFO] Loading Flutter build environment from !ENV_FILE!
  for /f "usebackq delims=" %%L in ("!ENV_FILE!") do (
   rem Strip leading/trailing spaces and check for comments/empty lines
   set "LINE=%%L"
   for /f "tokens=* delims=" %%S in ("!LINE!") do set "LINE=%%S"
   
   set "FIRST_CHAR=!LINE:~0,1!"
   if not "!FIRST_CHAR!"=="#" if not "!LINE!"=="" (
    echo !LINE! | findstr /R /C:"=" >nul 2>&1
    if not errorlevel 1 (
     set "DART_DEFINES=!DART_DEFINES! --dart-define=%%L"
    )
   )
  )
 )
)

REM ============================
REM Build Backend (Maven, Java)
REM ============================
set "BACKEND_ZIP_OUT=%DIST_DIR%\backend_lambda.zip"
set "LAST_BACKEND_ZIP="
set "LAST_BACKEND_JAR="

if /I "%BUILD_BACKEND%"=="true" (
 if not exist "%BACKEND_DIR%" ( echo [ERROR] Backend directory not found: %BACKEND_DIR% & exit /b 1 )

 echo.
 echo ==================================================
 echo Building Backend
 echo ==================================================
 pushd "%BACKEND_DIR%" >nul

 set "MVN_CMD=mvn clean package -Passembly-zip -Dspring.profiles.active=%SPRING_PROFILE% %MVN_FLAGS%"
 if /I "%SKIP_TESTS%"=="true" set "MVN_CMD=!MVN_CMD! -DskipTests"

 echo [INFO] !MVN_CMD!
 call !MVN_CMD!
 if errorlevel 1 (
  echo [ERROR] Backend build failed
  popd >nul
  exit /b 1
 )
 echo [SUCCESS] Backend build completed

 REM Prefer a zip produced by the assembly profile
 for /f "delims=" %%F in ('dir /b /a:-d /o:-d target\*.zip 2^>nul') do (
  set "LAST_BACKEND_ZIP=%%F"
  goto :found_backend_zip
 )

 :no_backend_zip
 REM Otherwise find the most recent fat jar or jar
 for /f "delims=" %%F in ('dir /b /a:-d /o:-d target\*all*.jar 2^>nul') do (
V  set "LAST_BACKEND_JAR=%%F"
  goto :have_backend_jar
 )
 for /f "delims=" %%F in ('dir /b /a:-d /o:-d target\*.jar 2^>nul') do (
  set "LAST_BACKEND_JAR=%%F"
  goto :have_backend_jar
 )

 echo [ERROR] Could not find backend artifact in target\
 popd >nul
 exit /b 1

 :found_backend_zip
 echo [INFO] Found backend zip: !LAST_BACKEND_ZIP!
 copy /y "target\!LAST_BACKEND_ZIP!" "%BACKEND_ZIP_OUT%" >nul
 if errorlevel 1 ( echo [ERROR] Failed to copy backend zip & popd >nul & exit /b 1 )
 goto :backend_done

 :have_backend_jar
 echo [INFO] Packaging backend jar into zip: !LAST_BACKEND_JAR!
 if exist "%BACKEND_ZIP_OUT%" del /f /q "%BACKEND_ZIP_OUT%" >nul 2>&1
 powershell -NoProfile -Command ^
  "Add-Type -A 'System.IO.Compression.FileSystem';" ^
  "$zip='%BACKEND_ZIP_OUT%';" ^
  "$jar='target\!LAST_BACKEND_JAR!';" ^
  "$tmp=[System.IO.Path]::GetTempFileName(); Remove-Item $tmp; " ^
  "[System.IO.Compression.ZipFile]::Open($zip,'Create').Dispose(); " ^
  "$fs=[System.IO.File]::Open($zip,'Open');" ^
  "$archive = New-Object System.IO.Compression.ZipArchive($fs,[System.IO.Compression.ZipArchiveMode]::Update,$true);" ^
  "$entry=$archive.CreateEntry([System.IO.Path]::GetFileName($jar));" ^
  "$in=[System.IO.File]::OpenRead($jar); $out=$entry.Open(); $in.CopyTo($out); $out.Dispose(); $in.Dispose(); $archive.Dispose(); $fs.Dispose();"
 if errorlevel 1 ( echo [ERROR] Failed to create backend zip & popd >nul & exit /b 1 )

 :backend_done
 echo [ARTIFACT] %BACKEND_ZIP_OUT%
 popd >nul
)

REM =============================
REM Build Frontend (Flutter Web)
REM =============================
REM *** NOTE: Zipping is removed. Output will be in build\web ***

if /I "%BUILD_FRONTEND%"=="true" (
 if not exist "%FRONTEND_DIR%" ( echo [ERROR] Frontend directory not found: %FRONTEND_DIR% & exit /b 1 )

 echo.
 echo ==================================================
 echo Building Frontend
 echo ==================================================
 pushd "%FRONTEND_DIR%" >nul

 echo [INFO] flutter pub get !FLUTTER_FLAGS!
 call flutter pub get !FLUTTER_FLAGS!
 if errorlevel 1 ( echo [ERROR] flutter pub get failed & popd >nul & exit /b 1 )

 if /I "%FLUTTER_MODE%"=="debug" (
  echo [INFO] flutter build web --debug !FLUTTER_FLAGS! !DART_DEFINES!
  call flutter build web --debug !FLUTTER_FLAGS! !DART_DEFINES!
 ) else (
  echo [INFO] flutter build web --release !FLUTTER_FLAGS! !DART_DEFINES!
  call flutter build web --release !FLUTTER_FLAGS! !DART_DEFINES!
 )
 if errorlevel 1 ( echo [ERROR] Frontend build failed & popd >nul & exit /b 1 )
 echo [SUCCESS] Frontend build completed

 if not exist "build\web" ( echo [ERROR] build\web folder not found & popd >nul & exit /b 1 )
 
 echo [ARTIFACT] %FRONTEND_DIR%\build\web
 popd >nul
)

echo.
echo ==================================================
echo Build Summary
echo ==================================================
if /I "%BUILD_BACKEND%"=="true" (
 if exist "%BACKEND_ZIP_OUT%" ( echo Backend : %BACKEND_ZIP_OUT% ) else ( echo Backend : FAILED )
)
if /I "%BUILD_FRONTEND%"=="true" (
 if exist "%FRONTEND_DIR%\build\web" ( echo Frontend : %FRONTEND_DIR%\build\web ) else ( echo Frontend : FAILED )
)
echo ==================================================
echo Done.
exit /b 0