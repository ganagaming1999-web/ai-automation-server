#!/bin/bash
echo "------------------------------------------------"
echo " AT-Tech Hub | Automated YouTube System Setup "
echo "------------------------------------------------"

# Create local bin if it doesn't exist
mkdir -p $HOME/.local/bin
export PATH=$HOME/.local/bin:$PATH

echo "[1/3] Setting up local environment..."
mkdir -p /opt/render/project/src/temp_assets
mkdir -p /opt/render/project/src/output

echo "[2/3] Checking Dependencies..."
# Note: Render already has Python and FFmpeg pre-installed in most environments.
python3 --version
ffmpeg -version | head -n 1

echo "[3/3] Finalizing Setup..."
chmod +x tts_generate.py

echo "✓ Build environment prepared successfully!"
