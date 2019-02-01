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
echo "00 08 * * * DISPLAY=:0 /home/pi/SingSparrow/singsparrow-operant-yoked.sh" > mycron
echo "00 19 * * * /home/pi/SingSparrow/shutsparrow.sh /home/pi/SingSparrow/processes" >> mycron
echo "*/15 08-19 * * * DISPLAY=:0 /home/pi/SingSparrow/resumetutoring.sh /home/pi/SingSparrow/processes" >> mycron
echo "* */1 * * * /home/pi/SingSparrow/updatetime.sh" >> mycron
echo "* 20 * * * reboot" >> mycron
crontab mycron
rm mycron

# Create data folders, if needed
outputdir="/home/pi/SingSparrow_data/output"
if [ ! -d $outputdir ]; then
    mkdir -p $outputdir
fi

# Parameters.txt wizard
#echo "Do you want to run the set-up wizard?, Type to corresponding number to your answer:"
#select yn in "Yes" "No"; do
 #   case $yn in
	
