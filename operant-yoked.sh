#!/usr/bin/env bash

# Load variables
while getopts "t:s:c:a:x:b:y:w:o:" option
do
    case "${option}"
    in
	t) gapthreshold=${OPTARG};;
	s) schedule=${OPTARG};;
	c) channel=${OPTARG};;
	a) songA=${OPTARG};;
	x) songAtype=${OPTARG};;
	b) songB=${OPTARG};;
	y) songBtype=${OPTARG};;
	w) wd=${OPTARG};;
	o) output=${OPTARG};;
    esac
done

# Welcome message
printf "Module controlling the reinforcement schedule for SingSparrow.\n"
printf "Running in operant-yoked mode.\n"
printf "Module written by Carlos Antonio Rodríguez-Saltos, 2019.\n"
printf "Channel $channel.\n"

printf "Song A is $songA.\n"
printf "Song B is $songB.\n"

printf "Working directory is $wd\n"

printf "To exit type Ctrl+C.\n"

# Go to working directory
cd $wd

# Set up starting variables
# The following variables are counters necessary to keep track of several quantities
prev_state=$(cat pressbuff$channel)
gaprun=0
gap=0
onset=0

npb=$(cat schedule | wc -l)

# Start of loop
# The code below runs on a continuos loop, interrupted only once program is not within working hours any longer.
while :; do
    # Reset variables
    now=$(date +%H)
    onset=0

# Update gap, if necessary
# If the bird pressed a key, the program will not play a sound only after a certain period of time (gap) has passed since the last time that a sound was played. In the following chunk of code, the program will update the counter. If the gap has reached the threshold specified by the user, then it will allow playback, provided that other requirements (checked in following chunks) are met.

if [ "$gaprun" == "1" ]; then
    if [ "$(python ./gapcomp.py $gap $gapthreshold)" == "1" ]; then
	gap=$(python ./gapsum.py $(date +%s) $gapstart)
    else
	gaprun=0
	gap=0
    fi
fi

# Scan key press
# The program searchers for presses in a buffer on which the press module stores key captures.
current_state=$(cat pressbuff"$channel")

# Record press and decide whether song should be played.
if [ "$current_state" == "1" ] && [ "$prev_state" == "0" ]; then
    printf "Key "$channel" was pressed"
    pos=$(cat schpos)
    onset=1
    if [ "$pos" -gt "$npb" ]; then
	printf "; no more song playbacks allowed.\n"
	play=0
    elif [ "$gaprun" == "1" ]; then
	printf "; song is still being played; no song will be played.\n"
	play=0
    else
	play=1
    fi
    printf "\n"
else
    play=0
fi

prev_state=$current_state

# Play sound, if requirements are met
if [ "$play" == "1" ]; then
    sound=$(sed -n "$pos"p $schedule)

    if [ "$sound" == "1" ]; then
	printf "Playing song "$songAtype"\n"
	aplay $songA &
    elif [ "$sound" == "2" ]; then
	printf "Playing song "$songBtype"\n"
	aplay $songB &
    fi

    # Activate gap
    gaprun=1
    gapstart=$(date +%s)
    
    # Move position in the schedule
    echo $(($pos + 1)) > schpos
fi

# Record info to output file
if [ "$onset" == "1" ]; then
    date="$(date +%Y),$(date +%m),$(date +%d),$(date +%H),$(date +%M),$(date +%S)"
    if [ "$play" == "1" ]; then
	printf "$channel,$sound,1,$date\n" >> $output
    else
	printf "$channel,0,1,$date\n" >> $output
    fi
fi

# End of loop
done
