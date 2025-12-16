@echo off
REM Orpheus-FastAPI Auto-Launcher for Windows
REM This script starts Orpheus-FastAPI (and llamacpp if available)

echo ============================================
echo Orpheus-FastAPI Auto-Launcher (Windows)
echo ============================================
echo.

REM Check for .env file
if not exist ".env" (
    echo [WARNING] No .env file found. Using defaults...
    set ORPHEUS_MODEL_NAME=Orpheus-3b-FT-Q8_0.gguf
    set ORPHEUS_MAX_TOKENS=8192
    set ORPHEUS_PORT=5005
) else (
    echo [OK] Loading configuration from .env
    REM Load .env variables (simplified version for batch)
    for /f "tokens=1,2 delims==" %%a in (.env) do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" (
            set %%a=%%b
        )
    )
)

REM Set defaults
if not defined LLAMA_PORT set LLAMA_PORT=5006
if not defined ORPHEUS_PORT set ORPHEUS_PORT=5005
if not defined ORPHEUS_MODEL_NAME set ORPHEUS_MODEL_NAME=Orpheus-3b-FT-Q8_0.gguf
if not defined ORPHEUS_MAX_TOKENS set ORPHEUS_MAX_TOKENS=8192

set MODEL_PATH=models\%ORPHEUS_MODEL_NAME%

REM Check if model exists
if not exist "%MODEL_PATH%" (
    echo [ERROR] Model file not found: %MODEL_PATH%
    echo Please run 'install.bat' first to download the model.
    pause
    exit /b 1
)

REM Check if llamacpp server is already running
curl -s http://127.0.0.1:%LLAMA_PORT%/health >nul 2>&1
if errorlevel 1 (
    echo.
    echo [INFO] llamacpp server not running
    echo [INFO] For Windows, please start llamacpp server manually
    echo        or use Docker: docker compose -f docker-compose-gpu.yml up
    echo.
    echo Press any key to continue without llamacpp...
    pause >nul
) else (
    echo [OK] llamacpp server is already running on port %LLAMA_PORT%
)

REM Activate virtual environment if it exists
if exist "venv\Scripts\activate.bat" (
    echo.
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
    echo [OK] Virtual environment activated
) else (
    echo [WARNING] No virtual environment found. Using system Python.
    echo           Run 'install.bat' first for proper setup.
)

REM Start Orpheus-FastAPI
echo.
echo ============================================
echo Starting Orpheus-FastAPI
echo ============================================
echo.
echo Web UI: http://localhost:%ORPHEUS_PORT%
echo API Docs: http://localhost:%ORPHEUS_PORT%/docs
echo Open-WebUI integration: http://localhost:%ORPHEUS_PORT%/v1
echo.
echo Press Ctrl+C to stop the server
echo.

python app.py
