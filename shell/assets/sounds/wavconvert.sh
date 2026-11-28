#!/bin/bash

# Alpe liefert nur noch die Klänge von Harmony 2 mit (plasma/); die freedesktop-Klänge nimmt die Shell aus dem
# installierten Klangthema (Paket sound-theme-freedesktop, Entscheid vom 26.11.2026).

# Convert plasma sounds
cd "$(dirname "$0")/plasma" || exit 1
for file in *.ogg; do
    if [ -f "$file" ]; then
        echo "Converting $file to WAV..."
        ffmpeg -i "$file" -acodec pcm_s16le -ar 44100 -ac 2 "${file%.ogg}.wav"
    fi
done

echo "Conversion complete!"
