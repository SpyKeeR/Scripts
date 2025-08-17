for i in *.avi; do
    ffmpeg -i "$i" -c:v libx264 -crf 19 -preset slow -c:a aac -b:a 192k -ac 2 "${i%.*}.mp4"
done
