#!/usr/bin/env bash

# Load variables
while getopts s:e:r option
do
    case "${option}"
    in
	s) whs=${OPTARG};;
	e) whe=${OPTARG};;
	r) reset=1;;
    esac
done

# Welcome message
printf "Welcome to SingSparrow, working in operant-yoked mode\n"
printf "This program was written by Carlos Antonio Rodriguez-Saltos, 2018\n\n"

# Reset schedule, if specified by the user
if [ "$reset" == "1" ]; then
    echo "1" > schpos
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
gnome-terminal -e "./operant-yoked.sh -t 3 -s schedule -c 1" &&
scheduleId1=$(echo $!)

gnome-terminal -e "./operant-yoked.sh -t 3 -s schedule -c 2" &&
scheduleId2=$(echo $!)

# Load press modules
printf "Opening press modules for each channel\n"
gnome-terminal -e "$press_module pressbuff1 1 0.25" &
pressId1=$(echo $!)

gnome-terminal -e "$press_module pressbuff2 2 0.25" &
pressId2=$(echo $!)

#wait $scheduleId

#printf "It worked!!"

#sleep 5
