#!/bin/bash
# script to go through a directory of photos/ maps, annotate timestamp, and make animation
# (where the date and timestamp is obtained from EXIF data if available)
# modified from J. Amundson 4-November-2008
#
# arguments:
# $1 = image directory
# $2 = file extension (jpg or JPG)
#
# example run:
# $ ./jpg_movie.sh /home/btober/Documents/Malsaspina_gopro/ JPG
#
# requires exiv2 if using jpg exif timestamp
#
# author: Brandon S. Tober
# 22-September-2021

echo 'Input directory: ' $1
echo 'File suffix: ' $2
SFIX=$2

###-------------------------------RENAME JPG FILES WITH JPG HEADER TIMESTAMP-------------------------------###
# (optional) name the photos after the dates in the jpg header
# jhead  -n%Y%m%d-%H%M%S  $1/*.$2; SFIX=$(echo "$2" | tr '[:upper:]' '[:lower:]')


# loop through all image files of specified type in directory and get time stamp to use for annotating each frame
# for photographs taken with jpg exif information, use exiv2 to get timestamp
# for maps/figures created, use file name, assuming that name relates to timestamp
for i in $(ls $1/*.$SFIX ); do
FNAME=$(basename -- "$i")
FNAME="${FNAME%.*}"

###-------------------------------CHOOSE EITHER ANNOTATION OPTION 1 OR 2-------------------------------###
###1 uncomment the below 2 lines for photographs containing jpg exif timestamps ###
TEXT=$(exiv2 $i | awk '/Image timestamp :/ {print $4, $5}' | sed 's/:/\//' | sed 's/:/\//')
[ -z "$TEXT" ] && exit 1
###2 uncomment the below line for maps/figures names with timestamp in file name ###
# TEXT=$FNAME

SFIX="_anno.jpg"
OUT="${1}/${FNAME}$SFIX"

###-------------------------------ANNOTATIONS-------------------------------###
# add annotations to southeast corner of each frame
# {-pointsize} controls the annotation size
# # use -pointsize 120  and -annotate +100+100 for hi-res glacier cam
# # use -pointsize 30  and -annotate +100+10 for lo-res images (e.g. AWS)
convert $i -font /usr/share/fonts/truetype/freefont/FreeMono.ttf -fill black -gravity SouthEast -pointsize 120 -annotate +100+10 "$TEXT" "$OUT"
echo "${i}-------->${OUT}"
done

###-------------------------------MOVIE TIME-------------------------------###
DIRNAME=$(basename $1)
cd $1
# fps along with other video settings may need to be set based on desired video speed & quality
# for details see https://linux.die.net/man/1/mencoder, and https://linux.die.net/man/1/ffmpeg
mencoder "mf://*$SFIX" -mf fps=2 -o tmp.avi -ovc lavc -lavcopts vcodec=msmpeg4v2:vbitrate=5320000 -vf scale=960:640
ffmpeg -i tmp.avi -b 5320k $DIRNAME.mp4

echo "Animation saved to "$DIRNAME".mp4"
# clean up
rm tmp.avi