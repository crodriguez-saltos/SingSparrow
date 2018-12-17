#from smop.core import *
import re
import os
import numpy as np
import random as rand
import time
import csv
import math
#

## SingSparrow!
# Program that controls the behavior of playback keys in operant conditioning tests.
# The program balances exposure to both sounds played by the keys while
# still allowing to detect a preference for a particular key.

# Original program writen by Carlos Antonio Rodriguez-Saltos for MATLAB, 2014.
# Translated from Matlab to Python by Prasanna Karur, 2017-2018.
# This version of the program is made to run with a Raspberry Pi board as
# a data acquisition device.

## Import parameters
# The parameters specified by the user in the 'parameter.txt' textfile are
# imported here.

# [Identifiers] - Parameters that permit to identify the trial.
# Bird - Code name of the bird
# Booth - Letter desginating the sound isolation booth in which the experiment is carried. Letters could be one from "A", "B", "C", "D", and "E".
# dayTrial - Day number of experiments with the same bird in the same booth

# [Key A/B] - Parameters that specify the audio file that will mostly be played by pressing Key A/B.
# file - Name of the audio file
# name - Type of sound played by the audio file.

# [Schedule] - Parameters that specify the schedule of
#                playbacks. Currently, the program accepts just 3 parameters.
# MaxPresentations - Maximum number of sound presentations.
# Switch1/2 - Number fo playbacks, from onset of experiment, at which the program changes the probabilities of playing song A or B by pressing either key.

# [DAQ] - Specifies the name of the DAQ device and which channels will be
# in use for Key A and Key B. The name of the device can be seen by opening
# the program NI-DAQmx while the DAQ card is connected to the computer. The
# name is usually 'Dev1' or 'Dev2'. The number that identifies each input
# line are labeled in the DAQ itself. For example, the line labeled as
# 'P1.7' corresponds to the line 7 of the port 1. In the parameter file,
# both the port and the line numbers have to be specified as in the
# following example: LineA = 'Port1/Line3'.
# device - Name of the device.
# LineA/B - Input lines of the device assigned to Key A or B, respectively.
# EXPLAIN TO NOT PUT DOTS BEFORE FILENAMES, IDEALLY, THEY SHOULD BE
# NUMBERS. BOTH FOLDERS SHOULD HAVE AN EQUAL NUMBER OF FILES.
# Import datafile 'parameters.txt'

#Define a method for loading variabes from text file
def loadVar(var):
  with open ('parameters.txt') as f:
    for line in f:
      my_var = r"\b(?=\w)" + var + r"\b(?!\w)" #locates variable in text file
      line = re.findall(my_var, line) 
      if line:
        line = line[0].split('= ')[1]
        line = line.split("\r")[0] #takes only the variable of interest
        return line
  return;
  
#Load variables
bird = loadVar(var = 'bird = .*')
booth = loadVar(var = 'booth = .*')
dayTrial = int(loadVar(var = 'dayTrial = .*'))
setProbe = int(loadVar(var = 'probe = .*'))
gap = [[0, 0, 0], [0, 0, 0]]
sounds = [[0, 0],[0, 0]]

soundA = loadVar(var = 'folder1 = .*')
filesA = os.listdir(soundA)
numberFiles = len(filesA)
sounds[0][0] = loadVar(var = 'sound_type1 = .*') #upload name for sound1
gap[0][0] = int(loadVar(var = 'gap1 = .*')) #upload limit for first gap

soundB = loadVar(var = 'folder2 = .*')
filesB = os.listdir(soundB)
numberFiles = len(filesB)
sounds[1][0] = loadVar(var = 'sound_type2 = .*') #upload name for sound2
gap[1][0] = int(loadVar(var = 'gap2 = .*')) #upload limit for second gap

startRun = float(loadVar(var = 'Hour start = .*'))
minStart = startRun * 60
endRun = float(loadVar(var = 'Hour end = .*'))
soundChange = float(loadVar(var = 'Sound change = .*'))
beginFile = float(loadVar(var = 'Begin file = .*'))
currentFile = beginFile - 1  #Making the current file be a different number than beginFile engages the program to load the first file because the program 'thinks' that an update is needed (section Import Files).
simple = int(loadVar(var = 'simple = .*')) #simple is activated if == 0 and deactivated if != 0

#if simple schedule deactivated
if simple != 0: 
  MaxPresentations = float(loadVar(var = 'MaxPresentations = .*'))
  Switch1 = float(loadVar(var = 'Switch1 = .*'))
  Switch2 = float(loadVar(var = 'Switch2 = .*'))
  Prob1 = float(loadVar(var = 'Prob1 = .*'))
  Prob2 = float(loadVar(var = 'Prob2 = .*'))
  Prob3 = float(loadVar(var = 'Prob3 = .*'))
  Compensation = 0

port = loadVar(var = 'port = .*')

#Set counters
nKeys = 2 #Specifies the number of keys, which almost always will be 2. However, having this variable will be useful when the program is upgraded to do more complex experiments.
lastKeySong = 2 #Tells which key was pressed last. 2 = No key was pressed, 0 = Key A, 1 = Key B.

#Generate counters that register the number of times that each key is pressed
keys = [[0,0],[0,0]]
for x in xrange(nKeys):
  keys[x][0] = 0 #update pos (registers the number of times that each key has been pressed and the program sent the command to play song)
  keys[x][1] = 0 #update total (registers the number of times each key is pressed without necesarilly having played song)

#Generate a counter that registers the number of times that any key has been pressed
outputPress = 0

#Generate counters that register how much time has passed since a key was
#pressed. The sound will not be played when a key is pressed again within
#a certain time of the last time that it was pressed and a command was
#send to play song. That time is defined by the user in the paremeters
#file.
for x in xrange(nKeys):
  gap[x][1] = 0 #update state
  gap[x][2] = 0 #update tictoc
  
for x in xrange(nKeys):
  sounds[x][1] = 0 #update counter

#Set probe
#Probe is a variable that grows with each iteration of the program. It is useful to know when did an error, if any, occur.
if (setProbe == 0):
  probe = 0
  
#Set the schedule
#This portion of the code sets the schedule that will be used by the keys
#to play the sounds. It follows Dr. Donna Maney's recommendation to
#balance exposure to both sounds while still setting a difference in the
#probability with which each key plays any of the sounds.

#A matrix with 2 fields, one for each key, and 4 single-row arrays is built. Each array
#represents a stage during the trial. The number of cells in each array
#depends on the values of Switch1, Switch2, and MaxPresentations, where
#such number is equal to Switch1 in the first array, $$(Switch2 - Switch1)$$ in
#the second, and (MaxPresentations - Switch2) in the third.

#The arrays are filled with zeros and twos, where the ones represent the number of times
#that soundA will be played while the twos, the number of times that sound
#B will be played. Such numbers change with each stage of the trial and
#depend on the odds with which each key plays a given sound at any
#stage. In stage 1, the odds of playing SoundA:SoundB upon pressing keyA
#are 3:1. Such odds at each stage will always be reversed for keyB; in
#stage 1, for example, the odds of playing SoundA:SoundB upon pressing
#keyB are 1:3. In stage 2, the same odds will be 2:1 upon pressing keyA,
#and in stage 3 they will be 1:1.

#To fill the arrays, first a series of fixed ones and twos for each
#corresponding array are built. The number of zeros and twos are
#calculated by multiplying the odds of playing soundA:soundB by the total
#number of cells of the array. The series of ones and twos are
#concatenated to form the array. Finally, the numbers are randomly
#scrambled within each array.

#The purpose of the arrays for the program can be compared to that of a
#magnetic tape in playback device. The program has two "virtual tape heads", one for each key, which
#always sits at the beginning of the tape (cell1 of array1). When a key
#is pressed, the corresponding head reads its tape and plays soundA, if
#the tape reads '1', or soundB, if the tape reads'2'. If, and only if,
#consecutive presses are made on a single key, BOTH tape heads advance. If
#the heads reach the end of the array, then they move to the next array
#(the cassette is changed!). If, however, the bird presses a different
#key, no matter where the heads are, they will be transfered back to the
#beginning of the current array. Also, each time a different key is
#pressed, the program plays the sound associated with that key (soundA for
#keyA and soundB for keyB), regardless of the number stored in the first
#cell of the current array for the key that was pressed.
#The idea of using arrays to control the behavior of the program, instead
#of a single or a few random variablse that would be continously updated during the running
#of the program, was kindly suggested by Emily Brown (Rob Hampton's lab).

if simple != 0:
  CounterSchedule = 0
  SchedulePos = [0, Switch1, Switch2, MaxPresentations]
  Presents = [Switch1, Switch2 - Switch1, MaxPresentations - Switch2]
  Probs = [Prob1, Prob2, Prob3]
  Product = [a*b for a,b in zip(Presents, Probs)]
  Repeats = [round(elem) for elem in Product]
  
  Schedule = [[0, 0],[0, 0], [0, 0]]
  for x in xrange(len(Presents)):
    Schedule[x][0] = np.concatenate([np.ones((Repeats[x])), 2 * np.ones((Presents[x] - Repeats[x]))]) #ScheduleA in Matlab
    Schedule[x][1] = np.concatenate([np.ones((Presents[x] - Repeats[x])), 2 * np.ones((Repeats[x]))]) #ScheduleB in Matlab
    
  #Randomize order of numbers within each schedule
  SoundFeedback = [[0, 0],[0, 0], [0, 0]]
  for x in xrange(len(Presents)):
    SoundFeedback[x][0] = rand.sample(Schedule[x][0], len(Schedule[x][0])) #SoundFeedbackA
    SoundFeedback[x][1] = rand.sample(Schedule[x][1], len(Schedule[x][1])) #SoundFeedbackB
    
  #Integrate all arrays into one matrix per key for easier handling
  #Each array corresponds to a different row of the matrix.
  #Cells corresponding to inexistent cells in each array are filled
  #with zeros. No non-zero values overlap within the same column.
  #Array 2 begins at column number Switch1 + 1, while Array2 begins at
  #column Switch2 + 1.
  #The last column consists of only zeros to mark the end of trials
  SoundFeedbackMatrix = [[0],[0]]
  SoundFeedbackMatrix[0] = np.concatenate([[SoundFeedback[0][0], np.zeros((MaxPresentations + 1 - len(SoundFeedback[0][0])))], 
  [np.zeros((Switch1)), SoundFeedback[1][0], np.zeros((MaxPresentations + 1 - len(SoundFeedback[1][0]) - 12))], 
  [np.zeros((Switch2)), SoundFeedback[2][0], np.zeros((MaxPresentations + 1 - len(SoundFeedback[2][0]) - Switch2))]])
  
  SoundFeedbackMatrix[1] = np.concatenate([[SoundFeedback[0][1], np.zeros((MaxPresentations + 1 - len(SoundFeedback[0][1])))], 
  [np.zeros((Switch1)), SoundFeedback[1][1], np.zeros((MaxPresentations + 1 - len(SoundFeedback[1][1]) - 12))], 
  [np.zeros((Switch2)), SoundFeedback[2][1], np.zeros((MaxPresentations + 1 - len(SoundFeedback[2][1]) - Switch2))]])
  
  #Save matrices to text file
  MatrixA = open('MatrixA.txt', 'w')
  for item in SoundFeedbackMatrix[0]:
    MatrixA.write("%s\n" % item)
    
  MatrixB = open('MatrixB.txt', 'w')
  for item in SoundFeedbackMatrix[1]:
    MatrixB.write("%s\n" % item)
  
#Set ouput matrix
current = time.strftime('%H:%M:%S').split(':')
OutputMatrix = []
OutputMatrix = np.concatenate([np.zeros(4).astype(int), current])
OutputFile = "OutputFile." + time.strftime('%Y%b%d') + '_' + booth + '_Id-' + bird + '_File1-' + sounds[0][0] + '_File2-' + sounds[1][0] + '-' + str(dayTrial) + '.txt'

#Write to output file
with open(OutputFile, 'w') as out:
    Output = csv.writer(out)
    Output.writerow(OutputMatrix)
outputSong = 0

#Write to logOutput file
log = []
log = np.concatenate([np.zeros(1).astype(int), current])
logFile = "log." + time.strftime('%Y%b%d') + '_' + booth + '_Id-' + bird + '_File1-' + sounds[0][0] + '_File2-' + sounds[1][0] + '-' + str(dayTrial) + '.txt'
with open(logFile, 'w') as out:
    logOutput = csv.writer(out)
    logOutput.writerow(log)

#Open Serial Port
#Matrix that stores up to 1000 events from the device. 
#It acts as a memory buffer, overwriting values, 
#starting with th the first rows, once the end has been 
#reached. Theh matrix is necessary to know whether a 
#"press" event is associated with the onset of the 
#pressing or with a pressing that is withheld. Probably, 
#1000 rows is too much for the matrix.
a = [[1,1],[1,1]] #matrix always has two rows counting for onsets and offsets of right and left key

#Run program during ON hours
masterTime = time.strftime('%Y:%-m:%d:%H:%M:%S').split(':')
tic = time.time()
totalSim= 100
simpress = np.zeros(totalSim).astype(int)
simsize = len(simpress)

for x in xrange(simsize):
    simpress[x] = rand.randrange(0,4)
#print simpress
    
simn = 0
secondOld = 0

while int(masterTime[3]) < endRun:
  #print masterTime
  timeFile = np.mod(math.ceil((((int(masterTime[3]) * 60) + int(masterTime[4])) - minStart) / soundChange) + beginFile - 2, numberFiles) + 1 #Tells the program what file whould be played, based on time of the day.
  
  #Update sound
  if currentFile != timeFile: 
    currentFile = timeFile
    
    #record change of file was successful
    logMatrix = np.concatenate([np.array([int(currentFile)]), time.strftime('%Y:%-m:%d:%H:%M:%S').split(':')])
    with open(logFile, 'a') as out:
      logOutput = csv.writer(out)
      logOutput.writerow(logMatrix)
  
  for n in range(2):
  #Set clocks and timers
  #Timer, set by tic/toc functions, have multiple functions in the program. They are used to count how many seconds has
  #it lapsed from the last key stroke. If consecutive pecks happen too
  #soon, the program does not play a sound but it records the peck. They
  #are used to buffer sound when recording, and allow to record sound in
  #the booth before and after the key press.
  #masterTime logs the time from the clock computer. The time will get
  #updated while the program runs. Setting it here is useful for variables
  #that need to be specified before running the loop.
  
    if setProbe == 0:
      probe = probe + (time.time() - tic)
    masterTime = time.strftime('%Y:%-m:%d:%H:%M:%S').split(':')
    
    #Update gap state
    #Enable a key after enough time (in seconds) has passed after its
    #inactivation SOLVE THE ISSUE OF GAPS BEFORE PROCEEDING
    for x in xrange(nKeys):
      if gap[x][1] == 1:
        gap[x][2] = gap[x][2] + (time.time() - tic)
        if gap[x][2] >= gap[x][0]:
          gap[x][1] = 0
    tic = time.time() #tic has to be here so that on the next cycle of updates of device and sound recorder all variables that depend on toc get accurate updates.
    
    if simn < totalSim:
      currentTime = time.strftime('%Y:%-m:%d:%H:%M:%S').split(':')
      secondNew = round((int(currentTime[5])))
      if secondNew != secondOld:
        simn = simn + 1
        #print simn
      else:
        scanned = 3
      secondOld = secondNew
    if simn < totalSim:
      scanned = simpress[simn]
    #print scanned
    
    #0 = key pressed, 1 = key not pressed
    if scanned == 0:
      a[n] = [0, 0]
    elif scanned == 1:
      a[n] = [0, 1]
    elif scanned == 2:
      a[n] = [1, 0]
    elif scanned == 3:
      a[n] == [1, 1]
    else:
      a[n] == [1, 1]
    
    pressed = a[n]
    
    #Detect and respond to key presses
    #print pressed
    #y = [sum(pressed), scanned]
    #print y
    if sum(pressed) != nKeys: #check whether key has been pressed or not
      for j in range(len(pressed)): #scan signal sent by each key
        if a[np.mod(n - 1,2)][j] == 1 and a[n][j] == 0: #check if press is an onset of a press
          #print a
          outputTime = time.strftime('%Y:%-m:%d:%H:%M:%S').split(':')
          #print outputTime
          keys[j][1] = keys[j][1] + 1 #counts number of times key is pressed
          outputPress = outputPress + 1 #transfers information to output
          outputKey = j #transfers information on which key is pressed
          
          #play appropriate sound if key was pressed
          if gap[j][1] == 0:
            if simple != 0:
              if CounterSchedule < 3:
                #activate gap
                gap[j][1] = 1
                gap[j][2] = 0
              
              if Compensation == 0: #Refers to the compensation after a sound has been played MaxTrials/2 times.
                if lastKeySong != j: #If the bird has switched from key, the sound played by the new key is that which has a higher probability of being delivered after pressing that key.
                  sound2Play = j
                  for k in range(nKeys):
                    keys[k][0] = SchedulePos[CounterSchedule]
                else:
                  keys[j][0] = keys[j][0] + 1
                  sound2Play = SoundFeedbackMatrix[j][CounterSchedule][keys[j][0]] - 1 #subtract 1 to follow Python indexing
                  
                #If the sound associated with the key is the sound that has been played with the lowest frequency overall, then a compensation schedule starts, which will play only the sound associated with the key until both sounds have the same amount of playbacks.
                if sound2Play != j and sounds[j][1] < sounds[np.mod(j,2) + 1][1]:
                  sound2Play = j
                print("Playing1")
                
                sounds[sound2Play][1] = sounds[sound2Play][1] + 1 #Counts up the number of times a particular song was played
                outputSong = sound2Play
                lastKeySong = j
                
                #For this to work, only two sounds can be played in each booth. 
                #In conspecific versus heterospecific song preference studies, only two sounds are played in each booth.
                if sounds[sound2Play][1] == MaxPresentations / 2: #When a song has been played 30 times, this code disables the playback of that song in both keys, and only enables the playback of the other song.
                  if sounds2Play == 0:
                    Compensation = 1
                  elif sounds2play == 1:
                    Compensation = 0 
                
                #Switches to next part of the schedule, based on number of consecutive presses of a particular key    
                if SoundFeedbackMatrix[j][CounterSchedule][keys[j][0] + 1] == 0:
                  CounterSchedule = CounterSchedule + 1
                  for k in range(nKeys):
                    keys[k][0] = SchedulePos[CounterSchedule]
              else:
                keys[j][0] = keys[j][0] + 1
                sound2Play = Compensation
                print("Playing2")
                
                sounds[sound2Play][1] = sounds[sound2Play][1] + 1  #Counts up the number of times a particular song was played
                outputSong = sound2Play
                
                #By this time, both songs would have been played 50 times each.
                if sounds[sound2Play][1] == MaxPresenations / 2:
                  CounterSchedule = 3
                for k in range(nKeys):
                  keys[k][0] = SchedulePos[CounterSchedule]
            else:
              #Activate gap
              gap[j][1] = 1
              gap[j][2] = 0
              
              #Play sound
              sound2Play = j #If the program is run on a simple schedule, then the only sound that will be played upon pressing a key is the asound associated with that key.
              
              print("Playing3")
              sounds[sound2Play][1] = sounds[sound2Play][1] + 1 #Counts up the number of times a particular song was played
              outPutSong = sound2Play
              lastKeySong = j
          
          #Write Press Event
          #print(sum(pressed))
          #if (sum(pressed) == 1):
          outputFinal = np.concatenate([np.array([outputPress]), np.array([outputKey]), np.array([outputSong]), np.array([currentFile]), outputTime])
          with open(OutputFile, 'a') as out:
            Output = csv.writer(out)
            Output.writerow(outputFinal)
          outputSong = 0
    
#End Program
logFinal = np.concatenate([np.zeros(1).astype(int), time.strftime('%Y:%-m:%d:%H:%M:%S').split(':')])
with open(logFile, 'a') as out:
  logOutput = csv.writer(out)
  logOutput.writerow(logFinal)
