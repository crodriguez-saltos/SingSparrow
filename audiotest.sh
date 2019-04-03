#!/usr/bin/env bash
# This program contains useful functions to test audio for SingSparrow.

# Import variables
while getopts "t:p:" option
do
    case "${option}"
    in
	t) test=${OPTARG};;
	p) params=${OPTARG};;
    esac
done

# Bird test
# In this test, a song is played on continuous loop. This playback routine is normally used to calibrate speakers to have a desired volume output.

if [ "$test" == "bird" ]; then
    echo "Bird test selected."
    echo "A sound will be played continuously for 5 minutes, or until the user forcefully terminates the program."
    echo "To break the loop, type Ctrl+C"

    now=$(date +%s)
    while :; do
	elapsed=$((($(date +%s) - $now) / 60))
	if [ "$elapsed" == "5" ]; then
	    break
	fi
	aplay /home/pi/SingSparrow/audio/red-jl-092_oc-L.wav
	sleep 0.1
    done
fi

# Test of identity
# With this test, a sound is played to check that the playback system is hooked to the right booth or sound system. For this test to work, a unique sound must be uniquely assigned to any particular system

if [ "$test" == "id" ]; then
    echo "Identity test was selected"
    echo "A sound will be played continuously for 5 minutes, or until the user forcefully terminates the program."
    echo "To break the loop, type Ctrl+C"
    
    # Load assignations
    assignation="./audio/id-test-assignments.txt"
    echo "Assignation table is $assignation"
    booth=$(cat $params | grep "booth = " | sed "s/\r//" | sed "s/booth = \(.*\)/\1/")
    assigned=$(cat $assignation | grep "$booth" | cut -d " " -f 2)
   
    echo "Booth is $booth"
    echo "Sound is $assigned"

    now=$(date +%s)
    while :; do
	elapsed=$((($(date +%s) - $now) / 60))
	if [ "$elapsed" == "5" ]; then
	    break
	fi
	aplay ./audio/$assigned
	sleep 1.5
    done
fi
