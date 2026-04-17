# Interview Transcription Project

Complete pipeline to convert video/audio interviews to text using OpenAI Whisper.

**Pipeline**: Video (MP4/MKV) → Audio (MP3) → Text (TXT)

## Files

- **video-to-audio.sh** - Bash script to convert video to MP3 using ffmpeg
- **transcribe.py** - Original Python script (hardcoded paths)
- **transcribe-flexible.py** - Flexible Python script with command-line arguments

## Prerequisites

```bash
pip3 install openai-whisper
# For video to audio conversion
sudo apt-get install ffmpeg  # or brew install ffmpeg on Mac
```

## Usage

### Complete Pipeline (Video → Audio → Text)

#### Step 1: Convert Video to Audio

```bash
./video-to-audio.sh interview.mkv
# Output: interview.mp3
```

Or with custom output name:
```bash
./video-to-audio.sh recording.mp4 output.mp3
```

#### Step 2: Transcribe Audio to Text

**Option A: Flexible script (recommended)**
```bash
# Auto-generate output filename
python3 transcribe-flexible.py interview.mp3

# Specify output file
python3 transcribe-flexible.py interview.mp3 transcript.txt

# Use different model size
python3 transcribe-flexible.py interview.mp3 transcript.txt small
```

**Option B: Original script (edit file paths first)**
```bash
# Edit paths in transcribe.py, then:
python3 transcribe.py
```

### Quick Example
```bash
# Complete pipeline for interview.mkv
./video-to-audio.sh interview.mkv
python3 transcribe-flexible.py interview.mp3
# Result: interview.txt
```

## Whisper Model Options

The script uses `base` model by default. Available models:

- `tiny` - Fastest, least accurate (~1GB RAM)
- `base` - Fast, good accuracy (~1GB RAM)
- `small` - Better accuracy (~2GB RAM)
- `medium` - High accuracy (~5GB RAM)
- `large` - Best accuracy (~10GB RAM)

Change the model in transcribe.py:
```python
model = whisper.load_model("base")  # Change to "small", "medium", etc.
```

## Example Pipeline

Real example from sdevraku interview:
```bash
# Step 1: Convert video to audio
./video-to-audio.sh sdevraku.mkv
# sdevraku.mkv (274MB) → sdevraku.mp3 (26MB)

# Step 2: Transcribe to text
python3 transcribe-flexible.py sdevraku.mp3
# sdevraku.mp3 (26MB) → sdevraku.txt (30KB)
```

Result: Complete interview transcript ready for analysis!

## Features

- Automatic Whisper installation if not present
- Language detection
- UTF-8 encoding support
- Verbose output during transcription

## Notes

- Larger models are more accurate but slower and require more memory
- Processing time depends on audio length and model size
- Works with multiple audio formats: mp3, wav, m4a, flac, etc.
