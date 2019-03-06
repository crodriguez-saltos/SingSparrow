#!/usr/bin/env bash

# Welcome message
printf "\n*************"
printf "\nThis is the installation utility for SingSparrow (Operant Yoked mode).\n\n"
printf "Please answer the following questions.\n\n"

# Apparently, the Raspberry Pi does not have system sounds, so no need to deactivate them.

# Schedule Rpi to run on a daily basis
while true; do
    read -p "Do you want to automate the daily start and end of SingSparrow? (if not installing on Raspberry Pi, please answer no) (y/n)" yn
    case $yn in
	[Yy]* ) echo "Updating crontab"; cronup=1; break;;
	[Nn]* ) cronup=0; break;;
	* ) echo "Please answer yes (y) or no (n).";;
    esac
done
printf "\n"

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
outputdir="../SingSparrow_data/output"
if [ ! -d $outputdir ]; then
    mkdir -p $outputdir
fi

# Copy parameters file
rsync ./parameters_opyok.txt ../SingSparrow_data/parameters_opyok.txt

# Parameters.txt wizard
while true; do
    read -p "Do you want to enter info about the bird? (y/n)" yn
    case $yn in
	[Yy]* ) echo "Let's begin!"; break;;
	[Nn]* ) echo "OK"; exit;;
	* ) echo "Please answer yes (y) or no (n).";;
    esac
done
printf "\n"

pfile="../SingSparrow_data/parameters_opyok.txt"

# Name of the bird
echo "What is the name of the bird?"
read birdname
param="bird ="
sed -i "s/$param.*/$param $birdname/" $pfile
printf "\n"

# Booth
echo "In which booth or room is the bird housed?"
read varname
booth=$varname
param="booth ="
sed -i "s/$param.*/$param $varname/" $pfile
printf "\n"

# Yoke match
matches=$(ls ./models/*_modelpb/ -d | sed "s@./models/\(.*\)_modelpb/@\1@g")
echo "To which bird is this bird matched to? (showing models stored in the ./models folder)"

i=0
while read line; do
    options[ $i ]="$line"
    (( i++ ))
done < <(ls ./models/*_modelpb/ -d | sed "s@./models/\(.*\)_modelpb/@\1@g")

select opt in "${options[@]}"; do
  case $opt in
    *)
      echo "Model $opt selected"
      varname=$opt
      break
      ;;
  esac
done

yokmodel=$varname
param="yoke match ="
sed -i "s/$param.*/$param $varname/" $pfile
printf "\n"

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
printf "\n"

# Date start
echo "When is the bird starting the experiment? (yyyy-mm-dd)"
read varname
param="date start ="
sed -i "s/$param.*/$param $varname/" $pfile
printf "\n"

# Song info
songs=$(ls ./audio/*_oc.wav | sed "s@./audio/@@g")
echo "Which one is the song of the father? (showing files stored in the ./audio folder)"
#echo "These are the songs found in storage:"

i=0
while read line; do
    options[ $i ]="$line"
    (( i++ ))
done < <(ls ./audio/*_oc.wav | sed "s@./audio/@@g")

select opt in "${options[@]}"; do
  case $opt in
    *.wav)
      echo "Wave file $opt selected"
      varname=$opt
      break
      ;;
    *)
      echo "This is not a number"
      ;;
  esac
done

param="songA ="
sed -i "s/$param.*/$param $varname/" $pfile
sed -i "s/sound_typeA = .*/sound_typeA = foster/" $pfile
printf "\n"

echo "Which one is the song of the neighbor? (showing files stored in the ./audio folder)"

i=0
while read line; do
    options[ $i ]="$line"
    (( i++ ))
done < <(ls ./audio/*_oc.wav | sed "s@./audio/@@g")

select opt in "${options[@]}"; do
  case $opt in
    *.wav)
      echo "Wave file $opt selected"
      varname=$opt
      break
      ;;
    *)
      echo "This is not a number"
      ;;
  esac
done

param="songB ="
sed -i "s/$param.*/$param $varname/" $pfile
sed -i "s/sound_typeB = .*/sound_typeB = alien/" $pfile
printf "\n"

# Finish
while true; do
    read -p "Set-up completed. Do you want to see the parameters file (y/n)" yn
    case $yn in
	[Yy]* ) echo "Opening file. Type [q] after finishing reading it."; sleep 2; less $pfile; break;;
	[Nn]* ) exit;;
	* ) echo "Please answer yes (y) or no (n).";;
    esac
done

# Archive parameter file
rsync $pfile ../SingSparrow_data/parameters/$birdname\_parameters.txt
