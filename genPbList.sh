#!/bin/bash

# Generate playback list from log files of keypresses.

# Import variables
dirlog=$1
dirout=$2

wd=$(pwd)
cd $dirlog

# Get identity of songs
temp1=$(mktemp)
for i in $(ls); do
    song1=$(echo $i | sed "s/.*_File1-\([0-9a-zA-Z]*\)_.*/\1/")
    song2=$(echo $i | sed "s/.*_File2-\([0-9a-zA-Z]*\)_.*/\1/")

    cat $i | tail -n +2 | awk -F',' '{print $3}' | sed "s/^1$/$song1/g" | sed "s/^2$/$song2/g" >> $temp1
done
# Get press info
temp2=$(mktemp)
for i in $(ls); do
    cat $i | tail -n +2 >> $temp2
done

temp3=$(mktemp)
paste -d , $temp1 $temp2 > $temp3

# Sort by timestamp
cd $wd
temp4=$(mktemp)
cat $temp3 | sort -t , -k 6 -V > $temp4

# Retain playbacks only
temp5=$(mktemp)
awk -F',' '($4 > 0)' < $temp4  > $temp5

# Generate folder to contain output
outdir="$dirout/$(basename $dirlog)_modelpb"
if [ ! -d $outdir ]; then
	mkdir $outdir
fi

# Save playback lists for each day
temp6=$(mktemp)
awk -F',' '{print $6,$7,$8}' $temp5 | sort -V | uniq > $temp6
day1=$(date -d "$(sed -n 1p $temp6 | sed 's/ /-/g')")

echo "First day is $day1"

for i in $(seq 0 100)
do
	year=$(date -d "$day1+$i days" +%Y)
	month=$(date -d "$day1+$i days" +%-m)
	day=$(date -d "$day1+$i days" +%-d)
	nday=$(printf "%03d" $(($i + 1)))
	#echo $year $month $day
	awk -F',' -v year=$year -v month=$month -v day=$day '($6 == year && $7 == month && $8 == day)' $temp5 > "$outdir/$(basename $dirlog)"_"day$nday"_"$year-$month-$day.txt"
done
