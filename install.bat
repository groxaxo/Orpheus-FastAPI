@echo off
REM Orpheus-FastAPI Auto-Installer for Windows
REM This script automatically sets up Orpheus-FastAPI with all dependencies

echo ============================================
echo Orpheus-FastAPI Auto-Installer (Windows)
echo ============================================
echo.

REM Check for Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH
    echo Please install Python 3.8-3.11 and add it to PATH
    pause
    exit /b 1
)

echo [OK] Python is installed

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo.
    echo Creating Python virtual environment...
    python -m venv venv
    echo [OK] Virtual environment created
) else (
    echo [OK] Virtual environment already exists
)

REM Activate virtual environment
echo.
echo Activating virtual environment...
call venv\Scripts\activate.bat
echo [OK] Virtual environment activated

REM Upgrade pip
echo.
echo Upgrading pip...
python -m pip install --upgrade pip --quiet
echo [OK] pip upgraded

REM Install PyTorch
echo.
echo Installing PyTorch...
where nvidia-smi >nul 2>&1
if errorlevel 1 (
    echo No NVIDIA GPU detected, installing CPU-only PyTorch...
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu --quiet
    echo [OK] PyTorch (CPU) installed
) else (
    echo NVIDIA GPU detected, installing PyTorch with CUDA 12.4 support...
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 --quiet
    echo [OK] PyTorch with CUDA support installed
)

REM Install other dependencies
echo.
echo Installing other dependencies...
pip install -r requirements.txt --quiet
echo [OK] All dependencies installed

REM Create required directories
echo.
echo Creating required directories...
if not exist "outputs" mkdir outputs
if not exist "static" mkdir static
if not exist "models" mkdir models
echo [OK] Directories created

REM Create .env file if it doesn't exist
if not exist ".env" (
    echo.
    echo Creating .env configuration file...
    if exist ".env.example" (
        copy .env.example .env >nul
        echo [OK] .env file created from .env.example
    ) else (
        echo [WARNING] .env.example not found, creating minimal .env
        (
            echo # Orpheus-FastAPI Configuration
            echo ORPHEUS_API_URL=http://127.0.0.1:5006/v1/completions
            echo ORPHEUS_API_TIMEOUT=120
            echo ORPHEUS_MAX_TOKENS=8192
            echo ORPHEUS_TEMPERATURE=0.6
            echo ORPHEUS_TOP_P=0.9
            echo ORPHEUS_SAMPLE_RATE=24000
            echo ORPHEUS_MODEL_NAME=Orpheus-3b-FT-Q8_0.gguf
            echo ORPHEUS_MODEL_REPO=lex-au
            echo ORPHEUS_PORT=5005
            echo ORPHEUS_HOST=0.0.0.0
        ) > .env
        echo [OK] Minimal .env file created
    )
) else (
    echo [OK] .env file already exists
)

echo.
echo ============================================
echo Installation Complete!
echo ============================================
echo.
echo Next steps:
echo 1. Download the GGUF model manually and place in models/ folder
echo 2. Run 'start.bat' to start the server
echo 3. Or start manually: venv\Scripts\activate.bat ^&^& python app.py
echo.
echo Access the web UI at: http://localhost:5005
echo API documentation at: http://localhost:5005/docs
echo.
echo For open-webui integration:
echo   - Set API Base URL to: http://localhost:5005/v1
echo   - Set TTS Model to: tts-1 or orpheus
echo   - API Key: not-needed
echo.
pause
