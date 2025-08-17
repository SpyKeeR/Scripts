for FILE in /home/spykeer/test/*.mkv
do
python ffmpeg-split.py -f $FILE -s 540
done
