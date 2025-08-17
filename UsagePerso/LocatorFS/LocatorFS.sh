shopt -s globstar
for f in **/*.*
do
fp=$(dirname "$f")
ext="txt"
#echo $f
#echo $fp
mkdir -p /work/"$fp"
cp /home/spykeer/MirrorTxtScript/exemplelocatorfile.txt /work/"$f"."$ext"
echo $f >> /work/"$f"."$ext"
#text=$(cat /home/spykeer/Testmirrorproject/exemplelocatorfile.txt)
#touch /home/spykeer/Testmirrorproject/Destination/"$f"."$ext"
#echo $text > ../Destination/"$f"."$ext"
#echo "cat /home/spykeer/Testmirrorproject/exemplelocatorfile.txt > /home/spykeer/Testmirrorproject/Destination/$f.$ext"
#echo "$f >> /home/spykeer/Testmirrorproject/Destination/$f.$ext"
done
