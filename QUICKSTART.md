# Orpheus-FastAPI Quick Start Guide

## For Open-WebUI Integration

Orpheus-FastAPI is **fully compatible** with Open-WebUI and provides automatic llamacpp server deployment.

### Installation Options

#### Option 1: Auto-Installer (Linux/macOS) - Recommended

```bash
# Clone and install
git clone https://github.com/groxaxo/Orpheus-FastAPI.git
cd Orpheus-FastAPI

# Make scripts executable and install
chmod +x install.sh start.sh
./install.sh

# Start everything automatically
./start.sh
```

#### Option 2: Docker Compose (All Platforms) - Easiest

```bash
# Clone and setup
git clone https://github.com/groxaxo/Orpheus-FastAPI.git
cd Orpheus-FastAPI
cp .env.example .env

# Start with Docker (GPU)
docker compose -f docker-compose-gpu.yml up

# Or start with Docker (CPU)
docker compose -f docker-compose-cpu.yml up
```

#### Option 3: Windows Batch Scripts

```cmd
# Clone and install
git clone https://github.com/groxaxo/Orpheus-FastAPI.git
cd Orpheus-FastAPI
install.bat

# Start the server
start.bat
```

### What Gets Deployed Automatically

When you run `./start.sh` or Docker Compose:

1. ✓ **llamacpp server** launches in background
2. ✓ **GGUF model** is loaded automatically
3. ✓ **Orpheus-FastAPI** starts and connects to llamacpp
4. ✓ All endpoints become available at `http://localhost:5005`

### Open-WebUI Configuration

Once the server is running:

1. Open **Open-WebUI** → Admin Panel → Settings → Audio
2. Set **TTS Engine** to: `OpenAI`
3. Set **API Base URL** to: `http://localhost:5005/v1`
4. Set **API Key** to: `not-needed` (or leave blank)
5. Set **TTS Model** to: `tts-1` or `orpheus`
6. Set **TTS Voice** to any available voice:
   - English: `tara`, `leah`, `jess`, `leo`, `dan`, `mia`, `zac`, `zoe`
   - French: `pierre`, `amelie`, `marie`
   - German: `jana`, `thomas`, `max`
   - Korean: `유나`, `준서`
   - Hindi: `ऋतिका`
   - Mandarin: `长乐`, `白芷`
   - Spanish: `javi`, `sergio`, `maria`
   - Italian: `pietro`, `giulia`, `carlo`

### Available Endpoints

Orpheus-FastAPI provides these Open-WebUI compatible endpoints:

- `POST /v1/audio/speech` - Generate speech from text (OpenAI-compatible)
- `GET /v1/models` - List available TTS models
- `GET /v1/audio/voices` - List available voices

### Testing the Integration

```bash
# Test models endpoint
curl http://localhost:5005/v1/models

# Test voices endpoint
curl http://localhost:5005/v1/audio/voices

# Test speech generation
curl http://localhost:5005/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tts-1",
    "input": "Hello from Orpheus TTS!",
    "voice": "tara"
  }' \
  --output test.wav
```

### Troubleshooting

**llamacpp server not found?**
- On Linux/macOS: Install llama.cpp or use Docker
- On Windows: Use Docker Compose for automatic llamacpp

**Model not found?**
- Run `./install.sh` to download the model
- Or download manually from HuggingFace to `models/` folder

**Connection refused?**
- Ensure llamacpp is running: `curl http://localhost:5006/health`
- Check `.env` file has correct `ORPHEUS_API_URL`

### Architecture

```
┌─────────────────┐
│  Open-WebUI     │
└────────┬────────┘
         │ HTTP
         ↓
┌─────────────────┐
│ Orpheus-FastAPI │ ← Port 5005
│  (app.py)       │
└────────┬────────┘
         │ HTTP
         ↓
┌─────────────────┐
│  llamacpp       │ ← Port 5006
│  (GGUF model)   │
└─────────────────┘
```

### Default Ports

- Orpheus-FastAPI: `5005`
- llamacpp server: `5006`

Both ports can be customized in the `.env` file.

### Support

For issues or questions:
- GitHub Issues: https://github.com/groxaxo/Orpheus-FastAPI/issues
- README: Full documentation in README.md
