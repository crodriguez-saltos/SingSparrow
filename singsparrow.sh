#!/usr/bin/env bash

# Load arguments
while getopts "s:k:p:r" option
do
	case "${option}"
	in
		s) system=${OPTARG};;
		k) keys=${OPTARG};;
		p) parameters=${OPTARG};;
		r) reset=1;;
	esac
done

# Load parameter values specified by user
# All values are stored in a configuration file, the name of which is specified here.

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

songA=$(val_importer "songA = ")
songB=$(val_importer "songB = ")
gapA=$(val_importer "gapA = ")
gapB=$(val_importer "gapB = ")

songAtype=$(val_importer "sound_typeA = ")
songBtype=$(val_importer "sound_typeB = ")

bird=$(val_importer "bird = ")
room=$(val_importer "booth = ")
model=$(val_importer "model = ")
yoktype=$(val_importer "yoke type = ")
yokmatch=$(val_importer "yoke match = ")
daystart=$(val_importer "date start = ")

wd=$(val_importer "working directory = ")

opyok=$(val_importer "operant yoked = ")

# Move to working directory 
cd $wd

# Create single-channel versions of the recordings.
# The way that SingSparrow cannalizes each song to each speaker is by creating left-only and right-only stereo versions of the sound files.
songAL=$(echo $songA | sed "s/\.wav/-L\.wav/")
songAR=$(echo $songA | sed "s/\.wav/-R\.wav/")
songBL=$(echo $songB | sed "s/\.wav/-L\.wav/")
songBR=$(echo $songB | sed "s/\.wav/-R\.wav/")

sox ./audio/$songA ./audio/$songAL remix 1 0
sox ./audio/$songA ./audio/$songAR remix 0 1
sox ./audio/$songB ./audio/$songBL remix 1 0
sox ./audio/$songB ./audio/$songBR remix 0 1

# Welcome message
printf "Welcome to SingSparrow\n" > welcome.txt
if [ "$opyok" == "1" ]; then
	printf "Running in operant-yoked mode\n" >> welcome.txt
fi

printf "This program was written by Carlos Antonio Rodriguez-Saltos, 2018\n\n" >> welcome.txt

echo "Start hour is $(echo $whs | cat -v)" >> welcome.txt
echo "End hour is $(echo $whe | cat -v)" >> welcome.txt

if [ "$reset" == "1" ]; then
	echo "Playlist position has been reset" >> welcome.txt
else
	echo "Playlist continues from last run" >> welcome.txt
fi

echo "Song A is $(echo $songA | cat -v)" >> welcome.txt
echo "Song B is $(echo $songB | cat -v)" >> welcome.txt

echo "Working directory is $(pwd)" >> welcome.txt

# Define output file
if [ "$system" == "rpi" ]; then
    datadir="/home/pi/SingSparrow_data"
else
    datadir="../singsparrow_data"
fi

if [ ! -d $datadir/output/$bird ]; then
    mkdir $datadir/output/$bird
fi

if [ "$opyok" == "1" ]; then
    nday=$(((($(date +%s) - $(date -d "$daystart" +%s)) / (24 * 3600)) + 1))
    output="$datadir/output/$bird"
    output="$output/OutputFile.$(date +%Y)$(date +%b)$(date +%d)"
    output="$output"_"$room"
    output="$output"_"Id-$bird"
    output="$output"_"Model-$yokmatch"
    output="$output"_"day-$nday"
    output="$output"_"$yoktype"
    output="$output"_"File1-$songA"
    output="$output"_"Type1-$songAtype"
    output="$output"_"File2-$songB"
    output="$output"_"Type2-$songBtype"
    output="$output"_"1.txt"
fi

echo "Output file is $output" >> welcome.txt

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

if [ "$keys" == "keyboard" ]; then
	press_module="./press-capture.sh"
elif [ "$keys" == "gpio" ]; then
	press_module="./gpio_press.sh"
fi

# Time checks
## Check that the hour format is correct
if [ "$(echo $whs | wc -m)" != "3" ] || [ "$(echo $whe | wc -m)" != "3" ]
then
    printf "Bad hour format. Check the leading zeros.\n" >> welcome.txt
    exit 1
fi

## Check that program is running within working hours

now=$(date +%H)

printf "Hour is $now\n" >> welcome.txt

if [ "$now" -ge "$whe" ] || [ "$now" -lt "$whs" ]; then
    printf "Not in the working hour, time for a break!\n" >> welcome.txt
    exit
else
    printf "Starting program within working hours\n" >> welcome.txt
fi

# Initialize key pressing module
# An advantage of using SingSparrow operant-yoked mode is that the module for specifying the reinforcement schedule can be kept separate from that gathering the key presses. In this chunk of code, the key press module, which can be specified by the user, will start running as a parallel process.

printf "Press module is $press_module\n" >> welcome.txt

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

printf "Starting position in schedule is $(cat schpos)\n" >> welcome.txt

# Named pipes will be created to communicate across modules.
mkfifo pressbuff1
mkfifo pressbuff2

# Generate schedule
if [ "$opyok" == "1" ]; then
	echo "Today is day $nday of experiment." >> welcome.txt
	
	ndayf=$(printf "%03d" $nday)
	schfile=$(find ./models -name "$yokmatch*day$ndayf*.txt")
	echo "Match file is $schfile" >> welcome.txt
	cp $schfile schedulenum
	tempsch=$(mktemp)
	awk -F',' '{print $1}' schedulenum > tempsch && mv tempsch schedulenum
fi

cat welcome.txt

if [ "$yoktype" == "forward" ]; then
	sed -i "s/$songAtype/1/g" schedulenum
	sed -i "s/$songBtype/2/g" schedulenum
elif [ "$yoktype" == "reverse" ]; then
	sed -i "s/$songAtype/2/g" schedulenum
	sed -i "s/$songBtype/1/g" schedulenum
fi

# The modules will be started. Each schedule and press module will be opened for each channel.
printf "Opening schedule modules for each channel\n"
echo $songAL
echo $songBL

if [ "$opyok" == "1" ]; then
	schcmd1="./operant-yoked.sh -t $gapA -s schedulenum -c 1 -a ./audio/$songAL -x $songAtype -b ./audio/$songBL -y $songBtype -w $wd -o $output"
	schcmd2="./operant-yoked.sh -t $gapB -s schedulenum -c 2 -a ./audio/$songAR -x $songAtype -b ./audio/$songBR -y $songBtype -w $wd -o $output"
fi

if [ "$system" == "rpi" ]; then
	lxterminal --command="/bin/bash -c '$schcmd1'" &
	scheduleId1=$(echo $!)
	lxterminal --command="/bin/bash -c '$schcmd2'" &
	scheduleId2=$(echo $!)
else
	gnome-terminal -e "$schcmd1" &
	scheduleId1=$(echo $!)
	gnome-terminal -e "$schcmd2" &
	scheduleId2=$(echo $!)
fi

# Load press modules
printf "Opening press modules for each channel\n"
presscmd1="$press_module pressbuff1 1 0.2"
presscmd2="$press_module pressbuff2 2 0.2"

if [ "$keys" == "gpio" ]; then
	lxterminal --command="/bin/bash -c '$presscmd1'" &
	pressId1=$(echo $!)
	lxterminal --command="/bin/bash -c '$presscmd2'" &
	pressId2=$(echo $!)
else
	gnome-terminal -e "$presscmd1" &
	pressId1=$(echo $!)
	gnome-terminal -e "$presscmd2" &
	pressId2=$(echo $!)
fi

# Save processes' names to a text file
echo $schcmd1 > processes
echo $schcmd2 >> processes
echo $presscmd1 >> processes
echo $presscmd2 >> processes
