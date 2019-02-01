#!/usr/bin/env bash

echo "This is the installation utility for SingSparrow Operant Yoked mode."
echo "This installation is meant to be run only with Raspberry Pis, and it will dedicate all user-defined automated tasks only to SingSparrow."

while true; do
    read -p "Do you want to continue (y/n)" yn
    case $yn in
	[Yy]* ) break;;
	[Nn]* ) exit;;
	* ) echo "Please answer yes (y) or no (n).";;
    esac
done

# Apparently, the Raspberry Pi does not have system sounds, so no need to deactivate them.

# Schedule Rpi to run on a daily basis
while true; do
    read -p "Do you want to automate the daily start and end of SingSparrow? (y/n)" yn
    case $yn in
	[Yy]* ) echo "Updating crontab"; cronup=1; break;;
	[Nn]* ) cronup=0; break;;
	* ) echo "Please answer yes (y) or no (n).";;
    esac
done

if [ "$cronup" == "1" ]; then
    echo "00 08 * * * DISPLAY=:0 /home/pi/SingSparrow/singsparrow-operant-yoked.sh" > mycron
    echo "00 19 * * * /home/pi/SingSparrow/shutsparrow.sh /home/pi/SingSparrow/processes" >> mycron
    echo "*/15 08-19 * * * DISPLAY=:0 /home/pi/SingSparrow/resumetutoring.sh /home/pi/SingSparrow/processes" >> mycron
    echo "* */1 * * * /home/pi/SingSparrow/updatetime.sh" >> mycron
    echo "* 20 * * * reboot" >> mycron
    crontab mycron
    rm mycron
fi

# Create data folders, if needed
outputdir="/home/pi/SingSparrow_data/output"
if [ ! -d $outputdir ]; then
    mkdir -p $outputdir
fi

# Copy parameters file
cp ./parameters_opyok.txt /home/pi/SingSparrow_data/parameters_opyok.txt

# Parameters.txt wizard
while true; do
    read -p "Do you want to run the set-up wizard? (y/n)" yn
    case $yn in
	[Yy]* ) echo "Let's begin!"; break;;
	[Nn]* ) echo "OK"; exit;;
	* ) echo "Please answer yes (y) or no (n).";;
    esac
done

pfile="/home/pi/SingSparrow_data/parameters_opyok.txt"

# Welcome message
echo "***************"
echo "Welcome to the wizard to set-up SingSparrow, in operant-yoked mode"
printf "Please type the answers to the following questions.\n\n"

# Name of the bird
echo "What is the name of the bird?"
read varname
param="bird ="
sed -i "s/$param.*/$param $varname/" $pfile

# Booth
echo "In which booth or room is the bird housed?"
read varname
booth=$varname
param="booth ="
sed -i "s/$param.*/$param $varname/" $pfile

# Yoke match
matches=$(ls ./models/*_modelpb/ -d | sed "s@./models/\(.*\)_modelpb/@\1@g")
echo "To which bird is this bird matched to? (the corresponding playback lists should be stored in the ./models folder)"
echo "These are the models found in storage:"
echo $matches
read varname
yokmodel=$varname
param="yoke match ="
sed -i "s/$param.*/$param $varname/" $pfile

# Type of yoke match
echo "What type of yoked control is this one?"
select ty in "forward" "reverse"; do
    case $ty in
        forward ) yoktype="forward"; break;;
        reverse ) yoktype="reverse"; break;;
    esac
done
param="yoke type ="
sed -i "s/$param.*/$param $yoktype/" $pfile

# Date start
echo "When is the bird starting the experiment? (yyyy-mm-dd)"
read varname
param="date start ="
sed -i "s/$param.*/$param $varname/" $pfile

# Song info
songs=$(ls ./audio/*_oc.wav | sed "s@./audio/@@g")
echo "What is the filename of the song of the father? (the file should be stored in the ./audio folder)"
echo "These are the songs found in storage:"
echo $songs
read varname
param="songA ="
sed -i "s/$param.*/$param $varname/" $pfile
sed -i "s/sound_typeA = .*/sound_typeA = foster/" $pfile

echo "What is the filename of ths song of the neighbor? (the file should be stored in the ./audio folder)"
echo "These are the songs found in storage:"
echo $songs
read varname
param="songB ="
sed -i "s/$param.*/$param $varname/" $pfile
sed -i "s/sound_typeB = .*/sound_typeB = alien/" $pfile

# Finish
while true; do
    read -p "Set-up completed. Do you want to see the parameters file (y/n)" yn
    case $yn in
	[Yy]* ) echo "Opening file. Type [q] after finishing reading it."; sleep 2; less $pfile; break;;
	[Nn]* ) exit;;
	* ) echo "Please answer yes (y) or no (n).";;
    esac
done
	
