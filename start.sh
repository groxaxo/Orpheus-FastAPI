#!/bin/bash
# Orpheus-FastAPI Auto-Launcher
# This script automatically starts llamacpp server in background and then launches Orpheus-FastAPI

set -e  # Exit on error

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🚀 Orpheus-FastAPI Auto-Launcher"
echo "================================"
echo ""

# Load environment variables safely
if [ -f ".env" ]; then
    set -o allexport
    source .env
    set +o allexport
    echo -e "${GREEN}✓${NC} Loaded configuration from .env"
else
    echo -e "${YELLOW}⚠${NC}  No .env file found. Using defaults..."
    ORPHEUS_MODEL_NAME="Orpheus-3b-FT-Q8_0.gguf"
    ORPHEUS_MAX_TOKENS=8192
    ORPHEUS_PORT=5005
fi

# Default values
LLAMA_PORT=${LLAMA_PORT:-5006}
MODEL_PATH="models/${ORPHEUS_MODEL_NAME}"

# Check if model exists
if [ ! -f "$MODEL_PATH" ]; then
    echo -e "${RED}✗${NC} Model file not found: $MODEL_PATH"
    echo "Please run './install.sh' first to download the model."
    exit 1
fi

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

# Function to check if llamacpp server is running
check_llama_server() {
    if curl -s "http://127.0.0.1:${LLAMA_PORT}/health" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to find llama-server binary
find_llama_server() {
    # Check common locations
    LLAMA_PATHS=(
        "llama-server"
        "./llama-server"
        "./llama.cpp/build/bin/llama-server"
        "./llama.cpp/llama-server"
        "/usr/local/bin/llama-server"
        "/usr/bin/llama-server"
        "$HOME/.local/bin/llama-server"
    )
    
    for path in "${LLAMA_PATHS[@]}"; do
        if command -v "$path" &> /dev/null || [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Check if llamacpp server is already running
if check_llama_server; then
    echo -e "${GREEN}✓${NC} llamacpp server is already running on port ${LLAMA_PORT}"
else
    echo ""
    echo "🔍 Checking for llamacpp server..."
    
    LLAMA_BIN=$(find_llama_server)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Found llama-server at: $LLAMA_BIN"
        echo ""
        echo "🔥 Starting llamacpp server in background..."
        echo "   Model: $MODEL_PATH"
        echo "   Port: $LLAMA_PORT"
        echo "   Max tokens: $ORPHEUS_MAX_TOKENS"
        echo "   GPU layers: ${LLAMA_GPU_LAYERS:-29}"
        
        # Start llamacpp server in background
        nohup "$LLAMA_BIN" \
            -m "$MODEL_PATH" \
            --port "$LLAMA_PORT" \
            --host 0.0.0.0 \
            --n-gpu-layers "${LLAMA_GPU_LAYERS:-29}" \
            --ctx-size "$ORPHEUS_MAX_TOKENS" \
            --n-predict "$ORPHEUS_MAX_TOKENS" \
            --rope-scaling linear \
            > llama-server.log 2>&1 &
        
        LLAMA_PID=$!
        echo "$LLAMA_PID" > .llama-server.pid
        echo -e "${GREEN}✓${NC} llamacpp server started (PID: $LLAMA_PID)"
        
        # Wait for server to be ready
        echo ""
        echo "⏳ Waiting for llamacpp server to be ready..."
        MAX_WAIT=60
        WAITED=0
        while ! check_llama_server && [ $WAITED -lt $MAX_WAIT ]; do
            sleep 2
            WAITED=$((WAITED + 2))
            echo -n "."
        done
        echo ""
        
        if check_llama_server; then
            echo -e "${GREEN}✓${NC} llamacpp server is ready!"
        else
            echo -e "${RED}✗${NC} llamacpp server failed to start within ${MAX_WAIT}s"
            echo "Check llama-server.log for details"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠${NC}  llamacpp server binary not found"
        echo ""
        echo "Options:"
        echo "1. Install llama.cpp:"
        echo "   git clone https://github.com/ggerganov/llama.cpp"
        echo "   cd llama.cpp && make"
        echo ""
        echo "2. Use Docker Compose (recommended):"
        echo "   docker compose -f docker-compose-gpu.yml up"
        echo ""
        echo "3. Start an external llamacpp server and set ORPHEUS_API_URL in .env"
        echo ""
        read -p "Continue without starting llamacpp? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    echo ""
    echo "🔌 Activating virtual environment..."
    if [[ "$OS" == "windows" ]]; then
        source venv/Scripts/activate
    else
        source venv/bin/activate
    fi
    echo -e "${GREEN}✓${NC} Virtual environment activated"
else
    echo -e "${YELLOW}⚠${NC}  No virtual environment found. Using system Python."
    echo "   Run './install.sh' first for a proper setup."
fi

# Start Orpheus-FastAPI
echo ""
echo "================================"
echo -e "${BLUE}🎵 Starting Orpheus-FastAPI${NC}"
echo "================================"
echo ""
echo "Web UI: http://localhost:${ORPHEUS_PORT}"
echo "API Docs: http://localhost:${ORPHEUS_PORT}/docs"
echo "Open-WebUI integration: http://localhost:${ORPHEUS_PORT}/v1"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Trap Ctrl+C to cleanup
trap cleanup INT

cleanup() {
    echo ""
    echo "🛑 Shutting down..."
    
    # Stop llamacpp if we started it
    if [ -f ".llama-server.pid" ]; then
        LLAMA_PID=$(cat .llama-server.pid)
        if kill -0 "$LLAMA_PID" 2>/dev/null; then
            echo "Stopping llamacpp server (PID: $LLAMA_PID)..."
            kill "$LLAMA_PID"
        fi
        rm .llama-server.pid
    fi
    
    exit 0
}

# Start the FastAPI server
python app.py
