#!/bin/bash
# Convert video to audio (MP3) for transcription
# Usage: ./video-to-audio.sh input.mkv [output.mp3]

if [ $# -eq 0 ]; then
    echo "Convert video to audio (MP3) for transcription"
    echo ""
    echo "Usage: $0 <input_video> [output_audio.mp3]"
    echo ""
    echo "Examples:"
    echo "  $0 interview.mkv"
    echo "  $0 recording.mp4 output.mp3"
    echo ""
    echo "Supported formats: mkv, mp4, avi, mov, webm, flv, etc."
    exit 0
fi

INPUT="$1"
OUTPUT="${2}"

# Check if input file exists
if [ ! -f "$INPUT" ]; then
    echo "❌ Error: Input file not found: $INPUT"
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ Error: ffmpeg is not installed"
    echo ""
    echo "Install ffmpeg:"
    echo "  Ubuntu/Debian: sudo apt-get install ffmpeg"
    echo "  macOS: brew install ffmpeg"
    echo "  Fedora: sudo dnf install ffmpeg"
    exit 1
fi

# Generate output filename if not provided
if [ -z "$OUTPUT" ]; then
    BASENAME=$(basename "$INPUT")
    FILENAME="${BASENAME%.*}"
    OUTPUT="${FILENAME}.mp3"
fi

echo "🎬 Input video: $INPUT"
echo "🎵 Output audio: $OUTPUT"
echo ""
echo "Converting..."

# Convert video to MP3 with good quality
# -vn: no video
# -acodec libmp3lame: use MP3 codec
# -q:a 2: quality level (0-9, 2 is high quality ~170-210 kbps)
ffmpeg -i "$INPUT" -vn -acodec libmp3lame -q:a 2 "$OUTPUT" -y

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Conversion complete!"
    echo "✅ Output saved to: $OUTPUT"
    
    # Show file sizes
    INPUT_SIZE=$(du -h "$INPUT" | cut -f1)
    OUTPUT_SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "✅ Original size: $INPUT_SIZE → Audio size: $OUTPUT_SIZE"
    echo ""
    echo "Next step: Run transcription"
    echo "  python3 transcribe-flexible.py $OUTPUT"
else
    echo ""
    echo "❌ Conversion failed!"
    exit 1
fi
