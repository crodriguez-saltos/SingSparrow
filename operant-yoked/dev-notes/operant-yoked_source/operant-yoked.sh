#!/usr/bin/env bash

# Load variables
while getopts "t:s:c:r" option
do
    case "${option}"
    in
	t) gapthreshold=${OPTARG};;
	s) schedule=${OPTARG};;
	c) channel=${OPTARG};;
    esac
done

# Welcome message
printf "Module controlling the reinforcement schedule for SingSparrow.\n"
printf "Running in operant-yoked mode.\n"
printf "Module written by Carlos Antonio Rodríguez-Saltos, 2019.\n"
printf "Channel $channel.\n"

printf "To exit type Ctrl+C.\n"

# Set up starting variables
# The following variables are counters necessary to keep track of several quantities
prevbuff=$(cat pressbuff$channel)
gaprun=0
schpos=0
gap=0
play=1

# Start of loop
# The code below runs on a continuos loop, interrupted only once program is not within working hours any longer.
while :; do
    # Reset variables
    now=$(date +%H)
    onset=0

# Update gap, if necessary
# If the bird pressed a key, the program will not play a sound only after a certain period of time (gap) has passed since the last time that a sound was played. In the following chunk of code, the program will update the counter. If the gap has reached the threshold specified by the user, then it will allow playback, provided that other requirements (checked in following chunks) are met.

if [ "$gaprun" == "1" ]; then
    if [ "$(echo "$gap < $gapthreshold" | bc -l)" == "1" ]; then
	play=0
	gap=$(echo $(date +%s) - $gapstart | bc)
    else
	play=1
	gaprun=0
	gap=0
    fi
fi

# Scan key press
# The program searchers for presses in a buffer on which the press module stores key captures.
current_state=$(cat pressbuff"$channel")

if [ "$current_state" == "1" ]; then
    prev_state=$(echo $prevbuff)
    if [ "$prev_state" == "0" ]; then
	onset=1
	printf "Key "$channel" was pressed"
	if [ "$play" == "0" ]; then
	    printf "; song is still being played; no song will be played.\n"
	fi
	printf "\n"
    else
	onset=0
    fi
fi

# Behavior if keys were pressed
# This part of the loop describes how the program responds if a key has been pressed.

if [ "$onset" == "1" ] && [ "$gaprun" == "0" ]; then
    # Select sound to play
    if [ "$play" == "1" ]; then
	pos=$(cat schpos)
	sound=$(sed -n "$pos"p $schedule)
	printf "Playing song "$sound"\n"

	# Activate gap
	gaprun=1
	gapstart=$(date +%s)
    
	# Move position in the schedule
	echo $(($pos + 1)) > schpos
    fi
fi

# End of loop
done
