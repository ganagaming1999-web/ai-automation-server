#!/bin/bash
# ============================================================
# AI-Tech Hub | Complete Server Setup Script
# Run this on Oracle Cloud Always Free Ubuntu 22.04 instance
# This sets up EVERYTHING needed for zero-manual YouTube automation
# ============================================================

set -e  # Exit on any error

echo "======================================================"
echo "  AI-Tech Hub | Automated YouTube System Setup"
echo "======================================================"

# ─────────────────────────────────────────────────────────────
# STEP 1: System Update & Base Dependencies
# ─────────────────────────────────────────────────────────────
echo "[1/10] Updating system..."
sudo apt-get update -y && sudo apt-get upgrade -y

echo "[1/10] Installing base dependencies..."
sudo apt-get install -y \
  curl wget git \
  python3 python3-pip python3-venv \
  ffmpeg \
  imagemagick \
  nodejs npm \
  nginx \
  unzip zip \
  fonts-dejavu-core \
  fonts-liberation \
  chromium-browser \
  xvfb \
  jq

# ─────────────────────────────────────────────────────────────
# STEP 2: Fix ImageMagick PDF Policy (for thumbnail generation)
# ─────────────────────────────────────────────────────────────
echo "[2/10] Configuring ImageMagick..."
sudo sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml 2>/dev/null || true
sudo sed -i 's/<policy domain="resource" name="memory" value="256MiB"\/>/<policy domain="resource" name="memory" value="2GiB"\/>/' /etc/ImageMagick-6/policy.xml 2>/dev/null || true

# ─────────────────────────────────────────────────────────────
# STEP 3: Python Environment & Packages
# ─────────────────────────────────────────────────────────────
echo "[3/10] Setting up Python environment..."
python3 -m venv /opt/aitechhub/venv
source /opt/aitechhub/venv/bin/activate

pip install --upgrade pip
pip install \
  edge-tts \
  asyncio \
  requests \
  google-auth \
  google-auth-oauthlib \
  google-api-python-client \
  pillow \
  ffmpeg-python \
  playwright \
  aiohttp \
  pydub

# Install Playwright browsers
python3 -m playwright install chromium
python3 -m playwright install-deps chromium

# ─────────────────────────────────────────────────────────────
# STEP 4: Install n8n (Self-Hosted)
# ─────────────────────────────────────────────────────────────
echo "[4/10] Installing n8n..."
sudo npm install -g n8n@latest

# Create n8n service
sudo tee /etc/systemd/system/n8n.service > /dev/null << 'EOF'
[Unit]
Description=n8n Workflow Automation
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
Environment=N8N_PORT=5678
Environment=N8N_PROTOCOL=http
Environment=N8N_HOST=0.0.0.0
Environment=N8N_ENCRYPTION_KEY=CHANGE_THIS_TO_RANDOM_STRING_32CHARS
Environment=EXECUTIONS_DATA_SAVE_ON_ERROR=all
Environment=EXECUTIONS_DATA_SAVE_ON_SUCCESS=none
Environment=EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
Environment=N8N_BASIC_AUTH_ACTIVE=true
Environment=N8N_BASIC_AUTH_USER=admin
Environment=N8N_BASIC_AUTH_PASSWORD=CHANGE_THIS_PASSWORD
Environment=WEBHOOK_URL=http://YOUR_SERVER_IP:5678/
EnvironmentFile=/opt/aitechhub/.env
ExecStart=/usr/local/bin/n8n start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# ─────────────────────────────────────────────────────────────
# STEP 5: Create Directory Structure
# ─────────────────────────────────────────────────────────────
echo "[5/10] Creating directory structure..."
sudo mkdir -p /opt/aitechhub
sudo chown ubuntu:ubuntu /opt/aitechhub

mkdir -p /opt/aitechhub/{scripts,assets,logs,temp,music}
mkdir -p /tmp/aitechhub

# ─────────────────────────────────────────────────────────────
# STEP 6: Copy TTS Script
# ─────────────────────────────────────────────────────────────
echo "[6/10] Setting up TTS generator..."
# Copy tts_generate.py to /opt/aitechhub/
# Make sure the file is placed here: /opt/aitechhub/tts_generate.py
chmod +x /opt/aitechhub/tts_generate.py 2>/dev/null || true

# ─────────────────────────────────────────────────────────────
# STEP 7: Download Free Background Music
# ─────────────────────────────────────────────────────────────
echo "[7/10] Downloading royalty-free background music..."
# Download from YouTube Audio Library or Pixabay (manual step)
# These are examples - replace with actual Pixabay Music API calls
cat > /opt/aitechhub/download_music.py << 'MUSICEOF'
import requests
import os

PIXABAY_API_KEY = os.environ.get('PIXABAY_API_KEY', '')
MUSIC_DIR = '/opt/aitechhub/music/'

moods = ['technology', 'upbeat', 'corporate', 'inspiring', 'calm']

for mood in moods:
    url = f'https://pixabay.com/api/?key={PIXABAY_API_KEY}&q={mood}+technology&music=true&per_page=3'
    response = requests.get(url)
    data = response.json()
    if data.get('hits'):
        for hit in data['hits'][:2]:
            audio_url = hit.get('audio', {}).get('url')
            if audio_url:
                filename = f'{MUSIC_DIR}{mood}_{hit["id"]}.mp3'
                if not os.path.exists(filename):
                    r = requests.get(audio_url)
                    with open(filename, 'wb') as f:
                        f.write(r.content)
                    print(f'Downloaded: {filename}')
MUSICEOF

python3 /opt/aitechhub/download_music.py 2>/dev/null || echo "Music download skipped - add PIXABAY_API_KEY to .env"

# ─────────────────────────────────────────────────────────────
# STEP 8: Create Environment File
# ─────────────────────────────────────────────────────────────
echo "[8/10] Creating environment configuration..."
cat > /opt/aitechhub/.env << 'ENVEOF'
# ══════════════════════════════════════════
# AI-Tech Hub | Environment Configuration
# ══════════════════════════════════════════

# Google Gemini API (FREE tier)
# Get from: https://aistudio.google.com/app/apikey
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE

# Pexels API (FREE)
# Get from: https://www.pexels.com/api/
PEXELS_API_KEY=YOUR_PEXELS_API_KEY_HERE

# Pixabay API (FREE)
# Get from: https://pixabay.com/api/docs/
PIXABAY_API_KEY=YOUR_PIXABAY_API_KEY_HERE

# Google Sheets ID (create a new sheet, copy ID from URL)
GOOGLE_SHEET_ID=YOUR_GOOGLE_SHEET_ID_HERE

# Gmail Notification Email (uses Gmail OAuth2 in n8n)
# Your Gmail address for notifications
NOTIFICATION_EMAIL=YOUR_GMAIL_ADDRESS_HERE
# NOTIFICATION_EMAIL is used for Gmail alerts (no Telegram needed)

# YouTube OAuth2 (set in n8n credentials panel)
# YOUTUBE_CLIENT_ID and YOUTUBE_CLIENT_SECRET go in n8n UI

# n8n Workflow IDs (fill after importing workflows)
WORKFLOW_SCRIPT_ID=YOUR_SCRIPT_WORKFLOW_ID
WORKFLOW_VISUALS_ID=YOUR_VISUALS_WORKFLOW_ID
WORKFLOW_UPLOAD_ID=YOUR_UPLOAD_WORKFLOW_ID

# Server paths
ASSETS_BASE_PATH=/tmp/aitechhub
SCRIPTS_PATH=/opt/aitechhub/scripts
MUSIC_PATH=/opt/aitechhub/music
ENVEOF

echo "⚠️  IMPORTANT: Edit /opt/aitechhub/.env with your API keys!"

# ─────────────────────────────────────────────────────────────
# STEP 9: Start n8n Service
# ─────────────────────────────────────────────────────────────
echo "[9/10] Starting n8n service..."
sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n

# ─────────────────────────────────────────────────────────────
# STEP 10: Firewall & Security
# ─────────────────────────────────────────────────────────────
echo "[10/10] Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 5678/tcp  # n8n
sudo ufw --force enable

# ─────────────────────────────────────────────────────────────
# VERIFY INSTALLATIONS
# ─────────────────────────────────────────────────────────────
echo ""
echo "======================================================"
echo "  VERIFICATION CHECKS"
echo "======================================================"
echo -n "✓ FFmpeg: " && ffmpeg -version 2>&1 | head -1
echo -n "✓ Python3: " && python3 --version
echo -n "✓ Node.js: " && node --version
echo -n "✓ edge-tts: " && /opt/aitechhub/venv/bin/edge-tts --version 2>&1 || echo "Run: pip install edge-tts"
echo -n "✓ ImageMagick: " && convert --version 2>&1 | head -1
echo -n "✓ n8n: " && n8n --version 2>&1
echo ""
echo "======================================================"
echo "  SETUP COMPLETE!"
echo "======================================================"
echo ""
echo "Next Steps:"
echo "1. Edit API keys: nano /opt/aitechhub/.env"
echo "2. Access n8n:    http://YOUR_SERVER_IP:5678"
echo "3. Import workflows from the JSON files"
echo "4. Set up YouTube OAuth2 in n8n credentials"
echo "5. Set up Google Sheets OAuth2 in n8n credentials"
echo "6. Set up Telegram credentials in n8n"
echo "7. Fill in workflow IDs in .env after import"
echo "8. Test each workflow stage individually"
echo "9. Enable all workflows and let it run!"
echo ""
echo "Your channel AI-Tech Hub will post automatically 🚀"
