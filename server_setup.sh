#!/bin/bash
echo "Preparing AI Secret Base environment..."
mkdir -p $HOME/.local/bin
export PATH=$HOME/.local/bin:$PATH
mkdir -p temp_assets output
chmod +x tts_generate.py
echo "✓ Environment ready."
