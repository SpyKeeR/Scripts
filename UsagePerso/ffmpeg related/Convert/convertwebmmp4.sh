for i in *.webm; do
    ffmpeg -i "$i" "${i%.*}.mp4"
done
