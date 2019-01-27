#!/usr/bin/env bash

# Load parameter values specified by user
# All values are stored in a configuration file, the name of which is specified here.
parameters="./parameters.txt"

# The values are imported by first searching the paramter name in the configuration file, and then by extracting the value to the right of the parameter name. The following function does that job.
val_importer () {
    # Select line containing value
    val=$(cat $parameters | grep "$1")

    # Remove carriage return
    val=$(echo $val | sed "s/\r//")

    # Extract value
    val=$(echo $val | sed "s/$1\(.*\)/\1/")

    echo $val
}

whs=$(val_importer "Hour start = ")
whe=$(val_importer "Hour end = ")
reset=$(val_importer "reset = ")

songA=$(val_importer "songA = ")
songB=$(val_importer "songB = ")
gapA=$(val_importer "gapA = ")
gapB=$(val_importer "gapB = ")

bird=$(val_importer "bird = ")
room=$(val_importer "booth = ")
model=$(val_importer "model = ")
yoktype=$(val_importer "yoke type =  ")
yokmatch=$(val_importer "yoke match = ")

# Create single-channel versions of the recordings.
# The way that SingSparrow cannalizes each song to each speaker is by creating left-only and right-only stereo versions of the sound files.
songAL=$(echo $songA | sed "s/\.wav/-L\.wav/")
songAR=$(echo $songA | sed "s/\.wav/-R\.wav/")
songBL=$(echo $songB | sed "s/\.wav/-L\.wav/")
songBR=$(echo $songB | sed "s/\.wav/-R\.wav/")

sox $songA $songAL remix 1 0
sox $songA $songAR remix 0 1
sox $songB $songBL remix 1 0
sox $songB $songBR remix 0 1

# Welcome message
printf "Welcome to SingSparrow, working in operant-yoked mode\n"
printf "This program was written by Carlos Antonio Rodriguez-Saltos, 2018\n\n"

echo "Start hour is $(echo $whs | cat -v)"
echo "End hour is $(echo $whe | cat -v)"
echo "Reset status is $(echo $reset | cat -v)"

echo "Song A is $(echo $songA | cat -v)"
echo "Song B is $(echo $songB | cat -v)"

# Define output file
output="OutputFile.$(date +%Y)$(date +%b)$(date +%d)"
output="$output"_"$room"
output="$output"_"Id-$bird"
output="$output"_"Model-$yokmatch"
output="$output"_"$yoktype"
output="$output"_"File1-$songA"
output="$output"_"File2-$songB"
output="$output"_"1.txt"

echo "Output file is $output"

# Reset schedule, as per user request
date="$(date +%Y),$(date +%m),$(date +%d),$(date +%H),$(date +%M),$(date +%S)"

if [ "$reset" == "1" ]; then
    echo "1" > schpos
    printf "0,0,1,$date\n" > $output
else
    printf "0,0,1,$date\n" >> $output
fi

# Configuration
# In this chunk, basic configuration options are set, including the location of the file containing parameters specified by the user and of the buffer storing key press values.
#parameters=

press_module=../press-response_source/press-capture.sh

# Time checks
## Check that the hour format is correct
if [ "$(echo $whs | wc -m)" != "3" ] || [ "$(echo $whe | wc -m)" != "3" ]
then
    printf "Bad hour format. Check the leading zeros.\n"
    exit 1
fi

## Check that program is running within working hours

now=$(date +%H)

printf "Hour is $now\n"

if [ "$now" -ge "$whe" ] || [ "$now" -lt "$whs" ]; then
    printf "Not in the working hour, time for a break!\n"
    exit
else
    printf "Starting program within working hours\n"
fi

# Initialize key pressing module
# An advantage of using SingSparrow operant-yoked mode is that the module for specifying the reinforcement schedule can be kept separate from that gathering the key presses. In this chunk of code, the key press module, which can be specified by the user, will start running as a parallel process.

printf "Press module is $press_module\n"

# To prevent former named pipes from interfering, they will be deleted.
if [ -p pressbuff1 ]; then
    rm pressbuff1
fi

if [ -p pressbuff2 ]; then
    rm pressbuff2
fi

# Make queue
if [ ! -f schpos ]; then
    echo "1" > schpos
fi

printf "Starting position in schedule is $(cat schpos)\n"

# Named pipes will be created to communicate across modules.
mkfifo pressbuff1
mkfifo pressbuff2

# The modules will be started. Each schedule and press module will be opened for each channel.
printf "Opening schedule modules for each channel\n"
echo $songAL
echo $songBL
gnome-terminal -e "./operant-yoked.sh -t $gapA -s schedule -c 1 -a $songAL -b $songBL -o $output" &&
scheduleId1=$(echo $!)

echo $songAR
echo $songBR
gnome-terminal -e "./operant-yoked.sh -t $gapB -s schedule -c 2 -a $songAR -b $songBR -o $output" &&
scheduleId2=$(echo $!)

# Load press modules
printf "Opening press modules for each channel\n"
gnome-terminal -e "$press_module pressbuff1 1 0.5" &
pressId1=$(echo $!)

gnome-terminal -e "$press_module pressbuff2 2 0.5" &
pressId2=$(echo $!)

#wait $scheduleId

#printf "It worked!!"

#sleep 5
