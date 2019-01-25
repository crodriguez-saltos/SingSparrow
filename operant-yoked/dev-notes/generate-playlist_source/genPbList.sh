#!/bin/bash

# Generate playback list from log files of keypresses.

# Import variables
dirlog=$1
output=$2

wd=$(pwd)
cd $dirlog

# Get identity of songs
temp1=$(mktemp)
for i in $(ls); do
    song1=$(echo $i | sed "s/.*_File1-\([0-9a-zA-Z]*\)_.*/\1/")
    song2=$(echo $i | sed "s/.*_File2-\([0-9a-zA-Z]*\)_.*/\1/")

    for j in $(cat $i | tail -n +2); do
	printf "$song1,$song2\n" >> $temp1
    done
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
cat $temp3 | sort -t , -k 7 > $output

# Retain playbacks only

#cat * | cut -d "," -f 5- > output

