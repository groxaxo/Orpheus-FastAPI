#!/bin/bash
# Orpheus-FastAPI Auto-Installer
# This script automatically sets up Orpheus-FastAPI with all dependencies

set -e  # Exit on error

echo "🚀 Orpheus-FastAPI Auto-Installer"
echo "=================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    OS="windows"
else
    OS="unknown"
fi

echo -e "${GREEN}✓${NC} Detected OS: $OS"

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗${NC} Python 3 is not installed. Please install Python 3.8-3.11 first."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo -e "${GREEN}✓${NC} Python version: $PYTHON_VERSION"

# Check Python version (must be 3.8-3.11)
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ] && [ "$PYTHON_MINOR" -le 11 ]; then
    echo -e "${GREEN}✓${NC} Python version is compatible"
else
    echo -e "${RED}✗${NC} Python version must be 3.8-3.11 (Python 3.12 is not supported)"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo ""
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
    echo -e "${GREEN}✓${NC} Virtual environment created"
else
    echo -e "${GREEN}✓${NC} Virtual environment already exists"
fi

# Activate virtual environment
echo ""
echo "🔌 Activating virtual environment..."
if [[ "$OS" == "windows" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi
echo -e "${GREEN}✓${NC} Virtual environment activated"

# Upgrade pip
echo ""
echo "⬆️  Upgrading pip..."
pip install --upgrade pip --quiet
echo -e "${GREEN}✓${NC} pip upgraded"

# Install PyTorch based on platform
echo ""
echo "🔥 Installing PyTorch..."
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected, installing PyTorch with CUDA 12.4 support..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 --quiet
    echo -e "${GREEN}✓${NC} PyTorch with CUDA support installed"
elif [[ "$OS" == "macos" ]]; then
    echo "macOS detected, installing PyTorch for Mac..."
    pip install torch torchvision torchaudio --quiet
    echo -e "${GREEN}✓${NC} PyTorch for macOS installed"
else
    echo "No GPU detected, installing CPU-only PyTorch..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu --quiet
    echo -e "${GREEN}✓${NC} PyTorch (CPU) installed"
fi

# Install other dependencies
echo ""
echo "📚 Installing other dependencies..."
pip install -r requirements.txt --quiet
echo -e "${GREEN}✓${NC} All dependencies installed"

# Create required directories
echo ""
echo "📁 Creating required directories..."
mkdir -p outputs static models
echo -e "${GREEN}✓${NC} Directories created: outputs/, static/, models/"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo ""
    echo "⚙️  Creating .env configuration file..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✓${NC} .env file created from .env.example"
    else
        echo -e "${YELLOW}⚠${NC}  .env.example not found, creating minimal .env"
        cat > .env << EOF
# Orpheus-FastAPI Configuration
ORPHEUS_API_URL=http://127.0.0.1:5006/v1/completions
ORPHEUS_API_TIMEOUT=120
ORPHEUS_MAX_TOKENS=8192
ORPHEUS_TEMPERATURE=0.6
ORPHEUS_TOP_P=0.9
ORPHEUS_SAMPLE_RATE=24000
ORPHEUS_MODEL_NAME=Orpheus-3b-FT-Q8_0.gguf
ORPHEUS_MODEL_REPO=lex-au
ORPHEUS_PORT=5005
ORPHEUS_HOST=0.0.0.0
EOF
        echo -e "${GREEN}✓${NC} Minimal .env file created"
    fi
else
    echo -e "${GREEN}✓${NC} .env file already exists"
fi

# Download model if it doesn't exist
echo ""
MODEL_NAME=$(grep ORPHEUS_MODEL_NAME .env | cut -d'=' -f2)
MODEL_REPO=$(grep ORPHEUS_MODEL_REPO .env | cut -d'=' -f2)

if [ ! -f "models/$MODEL_NAME" ]; then
    echo "📥 Model not found. Downloading $MODEL_NAME from HuggingFace..."
    echo "   This may take a while depending on your connection..."
    
    if command -v wget &> /dev/null; then
        wget -P models "https://huggingface.co/$MODEL_REPO/$MODEL_NAME/resolve/main/$MODEL_NAME" || {
            echo -e "${YELLOW}⚠${NC}  Model download failed. You can download it manually later."
        }
    elif command -v curl &> /dev/null; then
        curl -L "https://huggingface.co/$MODEL_REPO/$MODEL_NAME/resolve/main/$MODEL_NAME" -o "models/$MODEL_NAME" || {
            echo -e "${YELLOW}⚠${NC}  Model download failed. You can download it manually later."
        }
    else
        echo -e "${YELLOW}⚠${NC}  wget or curl not found. Please download the model manually:"
        echo "   https://huggingface.co/$MODEL_REPO/$MODEL_NAME/resolve/main/$MODEL_NAME"
    fi
else
    echo -e "${GREEN}✓${NC} Model already exists: models/$MODEL_NAME"
fi

# Installation complete
echo ""
echo "=================================="
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. If you haven't already, ensure you have a llamacpp server running or use the start.sh script"
echo "2. Run './start.sh' to start both llamacpp and Orpheus-FastAPI servers automatically"
echo "3. Or start manually: source venv/bin/activate && python app.py"
echo ""
echo "Access the web UI at: http://localhost:5005"
echo "API documentation at: http://localhost:5005/docs"
echo ""
echo "For open-webui integration:"
echo "  - Set API Base URL to: http://localhost:5005/v1"
echo "  - Set TTS Model to: tts-1 or orpheus"
echo "  - API Key: not-needed"
echo ""
