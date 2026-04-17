#!/usr/bin/env python3
"""
Transcribe audio to text using OpenAI Whisper
"""
import os
import sys

try:
    import whisper
except ImportError:
    print("Installing whisper...")
    os.system("pip3 install -q openai-whisper")
    import whisper

def transcribe_audio(audio_path, output_path):
    print(f"Loading Whisper model...")
    model = whisper.load_model("base")  # Options: tiny, base, small, medium, large
    
    print(f"Transcribing {audio_path}...")
    result = model.transcribe(audio_path, verbose=True)
    
    # Save transcription
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(result["text"])
    
    print(f"\n✓ Transcription saved to: {output_path}")
    print(f"✓ Detected language: {result.get('language', 'unknown')}")
    
    return result["text"]

if __name__ == "__main__":
    audio_file = "/home/ansha/NCOM/others/sdevraku.mp3"
    output_file = "/home/ansha/NCOM/others/sdevraku.txt"
    
    if not os.path.exists(audio_file):
        print(f"Error: Audio file not found: {audio_file}")
        sys.exit(1)
    
    transcribe_audio(audio_file, output_file)
