for i in *.mp4; do
    ffmpeg -i "$i" -vf scale=-1:540 -c:v libx264 -crf 18 -preset veryfast -c:a copy encoded2/"${i%.*}.mp4"
done
