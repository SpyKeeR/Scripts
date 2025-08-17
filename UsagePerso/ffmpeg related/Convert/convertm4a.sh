for f in *.m4a
	do ffmpeg -i "$f" -codec:v copy -codec:a libmp3lame -q:a 2 mp3s/"${f%.*}.mp3"
done
