#!/usr/bin/env python3
"""
AI-Tech Hub | TTS Generator
Uses edge-tts (Microsoft Edge TTS - 100% FREE) to generate voiceover
Install: pip install edge-tts asyncio

Usage: python3 tts_generate.py --text "your text" --output /path/to/output.mp3 --voice en-US-AriaNeural
"""

import argparse
import asyncio
import os
import sys
import edge_tts

AVAILABLE_VOICES = {
    "default": "en-US-AriaNeural",        # Clear, professional female
    "male": "en-US-GuyNeural",            # Professional male
    "professional_f": "en-US-JennyNeural", # Warm female
    "professional_m": "en-US-DavisNeural", # Deep male
    "energetic": "en-US-SaraNeural",       # Energetic female
}

async def generate_tts(text: str, output_path: str, voice: str = "en-US-AriaNeural", rate: str = "+10%", volume: str = "+0%"):
    """Generate TTS audio using Microsoft Edge TTS"""
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Clean text
    text = text.strip()
    if not text:
        print("ERROR: Empty text provided")
        sys.exit(1)
    
    # Add SSML-like pauses for better pacing
    text = text.replace(" ... ", "... ")
    
    try:
        communicate = edge_tts.Communicate(
            text=text,
            voice=voice,
            rate=rate,
            volume=volume
        )
        
        await communicate.save(output_path)
        
        if os.path.exists(output_path):
            size = os.path.getsize(output_path)
            print(f"TTS_SUCCESS: {output_path} ({size} bytes)")
        else:
            print(f"TTS_ERROR: File not created at {output_path}")
            sys.exit(1)
            
    except Exception as e:
        print(f"TTS_ERROR: {str(e)}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="AI-Tech Hub TTS Generator")
    parser.add_argument("--text", required=True, help="Text to convert to speech")
    parser.add_argument("--output", required=True, help="Output MP3 file path")
    parser.add_argument("--voice", default="en-US-AriaNeural", help="Voice name")
    parser.add_argument("--rate", default="+10%", help="Speech rate (+10% faster)")
    parser.add_argument("--volume", default="+0%", help="Volume adjustment")
    
    args = parser.parse_args()
    
    # Ensure output dir exists
    output_dir = os.path.dirname(args.output)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
    
    # Run async TTS
    asyncio.run(generate_tts(
        text=args.text,
        output_path=args.output,
        voice=args.voice,
        rate=args.rate,
        volume=args.volume
    ))

if __name__ == "__main__":
    main()
