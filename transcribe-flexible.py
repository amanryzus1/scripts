#!/usr/bin/env python3
"""
Transcribe audio/video to text using OpenAI Whisper
Usage: python3 transcribe-flexible.py <input_audio_file> [output_text_file] [model_size]
"""
import os
import sys
import argparse

try:
    import whisper
except ImportError:
    print("Installing whisper...")
    os.system("pip3 install -q openai-whisper")
    import whisper

def transcribe_audio(audio_path, output_path=None, model_size="base"):
    """
    Transcribe audio file to text
    
    Args:
        audio_path: Path to audio/video file
        output_path: Path to save transcription (default: same name as input with .txt extension)
        model_size: Whisper model size (tiny, base, small, medium, large)
    """
    if not os.path.exists(audio_path):
        print(f"❌ Error: Audio file not found: {audio_path}")
        sys.exit(1)
    
    # Generate output path if not provided
    if output_path is None:
        base_name = os.path.splitext(audio_path)[0]
        output_path = f"{base_name}.txt"
    
    print(f"🎵 Input: {audio_path}")
    print(f"📝 Output: {output_path}")
    print(f"🤖 Model: {model_size}")
    print(f"\nLoading Whisper model...")
    
    try:
        model = whisper.load_model(model_size)
    except Exception as e:
        print(f"❌ Error loading model: {e}")
        print("Available models: tiny, base, small, medium, large")
        sys.exit(1)
    
    print(f"Transcribing...")
    result = model.transcribe(audio_path, verbose=True)
    
    # Save transcription
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(result["text"])
    
    print(f"\n✅ Transcription complete!")
    print(f"✅ Saved to: {output_path}")
    print(f"✅ Detected language: {result.get('language', 'unknown')}")
    print(f"✅ Text length: {len(result['text'])} characters")
    
    return result["text"]

def main():
    parser = argparse.ArgumentParser(
        description='Transcribe audio/video to text using OpenAI Whisper',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 transcribe-flexible.py interview.mp3
  python3 transcribe-flexible.py video.mkv output.txt
  python3 transcribe-flexible.py audio.wav transcript.txt small
  
Model sizes (accuracy vs speed):
  tiny   - Fastest, least accurate (~1GB RAM)
  base   - Fast, good accuracy (~1GB RAM) [default]
  small  - Better accuracy (~2GB RAM)
  medium - High accuracy (~5GB RAM)
  large  - Best accuracy (~10GB RAM)
        """
    )
    
    parser.add_argument('input', help='Input audio/video file (mp3, wav, m4a, mkv, etc.)')
    parser.add_argument('output', nargs='?', help='Output text file (optional, auto-generated if not provided)')
    parser.add_argument('model', nargs='?', default='base', 
                       choices=['tiny', 'base', 'small', 'medium', 'large'],
                       help='Whisper model size (default: base)')
    
    args = parser.parse_args()
    
    transcribe_audio(args.input, args.output, args.model)

if __name__ == "__main__":
    if len(sys.argv) == 1:
        # No arguments, show help
        print("Transcribe audio/video to text using OpenAI Whisper\n")
        print("Usage: python3 transcribe-flexible.py <input_file> [output_file] [model_size]\n")
        print("Examples:")
        print("  python3 transcribe-flexible.py interview.mp3")
        print("  python3 transcribe-flexible.py video.mkv output.txt")
        print("  python3 transcribe-flexible.py audio.wav transcript.txt small")
        print("\nRun with -h for more details")
        sys.exit(0)
    
    main()
