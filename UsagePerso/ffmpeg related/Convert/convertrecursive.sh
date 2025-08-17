for i in $(cat listfiles);
do
    ffmpeg -i "$i" -c copy "${i%.*}.mkv"
done
