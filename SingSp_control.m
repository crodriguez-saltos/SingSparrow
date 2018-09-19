%% SingSparrow! control
% Schedules control playbacks based on timestamps from birds that have used SingSparrow!
%
% Writen by Carlos Antonio Rodriguez-Saltos, 2016.

%% Import parameters
% The parameters specified by the user in the 'parameter.txt' textfile are
% imported here.
%
% [Identifiers] - Parameters that permit to identify the trial.
% Bird - Code name of the bird
% Booth - Letter desginating the sound isolation booth in which the experiment is carried. Letters could be one from "A", "B", "C", "D", and "E".
% dayTrial - Day number of experiments with the same bird in the same booth
%
% [Key A/B] - Parameters that specify the audio file that will mostly be played by pressing Key A/B.
% file - Name of the audio file
% name - Type of sound played by the audio file.
%
% [Schedule] - Parameters that specify the schedule of
%                playbacks. Currently, the program accepts just 3 parameters.
% MaxPresentations - Maximum number of sound presentations.
% Switch1/2 - Number fo playbacks, from onset of experiment, at which the program changes the probabilities of playing song A or B by pressing either key.

% [DAQ] - Specifies the name of the DAQ device and which channels will be
% in use for Key A and Key B. The name of the device can be seen by opening
% the program NI-DAQmx while the DAQ card is connected to the computer. The
% name is usually 'Dev1' or 'Dev2'. The number that identifies each input
% line are labeled in the DAQ itself. For example, the line labeled as
% 'P1.7' corresponds to the line 7 of the port 1. In the parameter file,
% both the port and the line numbers have to be specified as in the
% following example: LineA = 'Port1/Line3'.
% device - Name of the device.
% LineA/B - Input lines of the device assigned to Key A or B, respectively.
% EXPLAIN TO NOT PUT DOTS BEFORE FILENAMES, IDEALLY, THEY SHOULD BE
% NUMBERS. BOTH FOLDERS SHOULD HAVE AN EQUAL NUMBER OF FILES.
% Import datafile 'parameters.txt'
clear all

formatSpec = '%*s bird = %s booth = %s pbtype = %s %*s %*s folder = %s %*s %*s folder = %s %*s %*s playbird = %s daystart = %s timezone = %s dayTrial = %f Hour start = %f Hour end = %f Sound change = %f Begin file = %f %*s %*s device = %s LineA = %s LineB = %s';
a = fopen('parameters.txt', 'r');
datafile = textscan(a, formatSpec, 'Delimiter', '\n', 'CollectOutput', true);

fclose(a);
clear a formatSpec;

%% Read general parameters
bird = char(datafile{1}(1));
booth = char(datafile{1}(2));
pbtype = char(datafile{1}(3));

sfoster = char(datafile{1}(4));
salien = char(datafile{1}(5));

playbird = char(datafile{1}(6));
daystart = datetime(datafile{1}(7), 'InputFormat', 'MM/dd/yyyy');
timzone = char(datafile{1}(8));
dayTrial = double(datafile{2}(1));
startRun = double(datafile{2}(2));  % TODO: Specify what to do with 'daystart'
minStart = startRun * 60;
endRun = double(datafile{2}(3));
soundChange = double(datafile{2}(4));
beginFile = double(datafile{2}(5));
currentFile = beginFile - 1; % Making the current file be a different number than beginFile engages the program to load the first file because the program 'thinks' that an update is needed (section Import Files).

device = char(datafile{3}(1));
LineA = char(datafile{3}(2));
LineB = char(datafile{3}(3));

clear datafile

%% Read playback schedule
timedir = dir(['./tmstamps/' playbird]);
timedir = timedir(3:end);
timedir = struct2dataset(timedir);

timedir = timedir(:, {'name', 'date'});
timedir.date = timedir.name;

for i = 1:size(timedir, 1)
	timedir.date{i} = strsplit(timedir.date{i}, '.');
	timedir.date{i} = strsplit(timedir.date{i}{2}, '_');
	timedir.date{i} = timedir.date{i}{1};
end

timedir.date = datetime(timedir.date, 'InputFormat', 'yyyyMMMdd');
timedir = sortrows(timedir, 'date');

currentday = hours(date - daystart) / 24 + 1;
currentday = floor(double(currentday));
currentsch = timedir.name{currentday};

sch = readtable(['./tmstamps/', playbird, '/', currentsch]);
sch = sch(2:end,:);  % Eliminates first row, which contains only zeros
sch(find(sch{:,3} == 0),:) = '';

spkpb = sch{:,2};

if pbtype == 'forward'
	soundpb = sch{:,3};
elseif pbtype == 'reverse'
	soundpb = mod(sch{:,3}, 2) + 1;
end

%% Determine coding of files
dashes = regexp(currentsch, '_');
file1 = regexp(currentsch, '_File1-');
file1 = currentsch((file1 + 7):(dashes(find(dashes > file1 + 7, 1)) - 1));

file2 = regexp(currentsch, '_File2-');
file2 = currentsch((file2 + 7):(dashes(find(dashes > file2 + 7, 1)) - 1));

clear dashes;

sounds(1).name = file1;
sounds(2).name = file2;

if strcmp(file1, 'foster')
	soundA = sfoster;
	soundB = salien;
elseif strcmp(file2, 'foster')
	soundA = salien;
	soundB = sfoster;
end

clear sfoster salien file1 file2;

filesA = dir(soundA);
filesA = filesA(3:end);  % eliminates files '.' and '..' from array
numberFiles = length(filesA);  % counts the number of files in folder

filesB = dir(soundB);
filesB = filesB(3:end); % eliminates files '.' and '..' from array


outputstr = strcat(datestr(clock, 'yyyymmmdd'), '_', booth, '_Id-', bird, ...
					'_Model-', playbird, '_', pbtype, '_File1-', ...
					sounds(1).name,'_File2-', sounds(2).name, ...
					'_', num2str(dayTrial), '.txt');

%% Get playback times  
pbtimes = sch(:,5:end);
pbtimes = table2array(pbtimes);
pbtimes = datetime(pbtimes, 'TimeZone', timzone);

if ~isempty(pbtimes)
	for i = 1:size(pbtimes, 1)
		thisday(i,1) = datetime(date, 'TimeZone', timzone);
	end

	[Y, MO, D] = ymd(thisday);
	[H, M, S] = hms(pbtimes);
	H = H + isdst(datetime(date, 'TimeZone', timzone)) - isdst(pbtimes);

	% For test purposes only
	% H = H + 8;
	% M = M + 25;

	pbtimes = datetime([Y MO D H M S], 'TimeZone', timzone);
	clear Y MO D H M S;

	rightnow = clock;
	rightnow(5) = rightnow(5) + 1;  % Helps in searching for the nearest timestamp
									% to 1 minute into the future, thus allowing
									% some time for the program to load.
	rightnow = datetime(rightnow, 'TimeZone', timzone);
	timediffs = hours(pbtimes - rightnow);
	pos = find(timediffs > 0, 1);
	if isempty(pos) pos = size(pbtimes, 1) + 1; end;
	clear timediffs;
end
pbevent = 0;
outputpb = [zeros(1,3) clock];

%% Set counters
nKeys = 2; %Specifies the number of keys, which almost always will be 2. However, having this variable will be useful when the program is upgraded to do more complex experiments.

% Generate counters that register the number of times that each key is pressed.
for m = 1:nKeys
    keys(m).total = 0; % This counter registers the number of times each key is pressed without necesarilly having played song
end

% Generate a counter that registers the number of times that any key has been pressed
output.Press = 0;
    
%% Set output matrix
%This is the matrix that will be filled-up each time the bird presses a
%key and will eventually be writen into a text file once the trial is over.
%
% The columns contain the following data: Press number, Key that was pressed, Sound that was played, Year, Month, Day, Hour, Minute Second

output.Matrix = [zeros(1) zeros(1,2) clock];
OutputFile = table(output.Matrix);
writetable(OutputFile, strcat('OutputFile.', outputstr));

log = [zeros(1) clock]; % Writes a log file table showing that a file 
% was succesfully changed automatically, according to the time specified by the user.
logFile = table(log);
writetable(logFile,strcat('log.', outputstr));

%% Set device parameters
% Required parameters for the Digital Acquisition
% Device (National Instruments). The code will work only with
% digital input devices.
d = daq.getDevices %Get device info

% Set session for the device.
s = daq.createSession('ni');
s.DurationInSeconds = 10;
addDigitalChannel(s, device, LineA, 'InputOnly');
addDigitalChannel(s, device, LineB, 'InputOnly');
s.Channels  % Show channel info.

a = [1:nKeys;1:nKeys];  % Memory buffer
onset = zeros(1,nKeys); 

%% Resume a previous run

%% Run the program during On hours
masterTime = clock;
tic;
while masterTime(4) < endRun % Runs program until time specified by user (endRun).
    %% Load sound
    % SHOULD PLACE INSIDE OUTER LOOP.
    % The sounds are imported as numeric matrixes contained within the
    % structure array 'sounds(1/2)'. The structure sounds(1) contains the sound
    % data for the playback of Key A while the structure sounds(2) contains
    % that for Key B. Within each structure there is information on the type of
    % sound contained in the file (sound().name) and the number of times that
    % the file has been played in the current session (sounds().counter).
    % The sounds loaded into sounds(1) are always played to the Left output
    % channel, while the sounds loaded into sounds(2) are always played to the
    % Right output channel. Note that the orientation of the computer output
    % channels may not be the same as the physical orientation of the speakers
    % playing the sound inside the booth. It is recommended to always associate 
	% KeyA with the Left ouput channel and KeyB with the Right output channel.
    
    % Get directory files for sound A and B
    % currentFile will get
    % updated every 15 minutes
    % MAYBE THERE IS A WAY TO OPTIMIZE THE PROGRAM BY EXTRACTING BEGINFILE
    % BELOW
    timeFile = mod(ceil((((masterTime(4) * 60) + masterTime(5)) - minStart) / soundChange) + beginFile - 2, numberFiles) + 1;
    
	if ~isempty(pbtimes)
		if ~(currentFile == timeFile) % Update sound
			[sounds(1).data, sounds(1).Fs] = audioread(strcat('./',soundA, '/', filesA(timeFile).name));
			if size(sounds(1).data, 2) == 1  % If sound is mono, this command converts it to stereo
				sounds(1).data = [sounds(1).data sounds(1).data];
			end
			
			[sounds(2).data, sounds(2).Fs] = audioread(strcat('./',soundB, '/', filesB(timeFile).name));
			if size(sounds(2).data, 2) == 1  % If sound is mono, then duplicate the channels
				sounds(2).data = [sounds(2).data sounds(2).data];
			end
			
			currentFile = timeFile;
			
			% Notify when change of file is succesful
			log = [log; [currentFile, clock]];
			logFile = table(log);
			writetable(logFile,strcat('log.', outputstr));    
		end
		
		%% Play sound according to playback schedule
		if pos <= size(pbtimes, 1)
			timdiff = hours(pbtimes(pos) - datetime(clock, 'TimeZone', timzone));
			if timdiff < - 1/36000
				rightnow = clock;
				rightnow(5) = rightnow(5)
				rightnow = datetime(rightnow, 'TimeZone', timzone);
				timediffs = hours(pbtimes - rightnow);
				pos = find(timediffs > 0, 1);
				if isempty(pos) pos = size(pbtimes, 1) + 1; end;
				clear timediffs;
				timdiff = hours(pbtimes(pos) - datetime(clock, 'TimeZone', timzone));
			end
			if timdiff < 1 / 36000 & timdiff > - 1/36000
				% Play sound
				sound2Play = soundpb(pos);
				j = spkpb(pos);
				
				queueSound = sounds(sound2Play).data;
				queueSound(:,mod(j,2) + 1) = zeros(size(queueSound, 1),1);
				sound(queueSound, sounds(sound2Play).Fs);
				disp(strcat('Playing',32, sounds(sound2Play).name,32, 'at',32, ...
					datestr(clock, 'yyyy-mm-dd HH:MM:SS')));
				
				% update parameters
				output.time = clock;
				pos = pos + 1;
				pbevent = pbevent + 1;
				
				%% Write playback event
				outputpb = [outputpb; [pbevent j sound2Play output.time]];
				outputpbf = table(outputpb);
				writetable(outputpbf, strcat('playback.', outputstr))
			end
			
			% For testing purposes only
			% disp([pos timdiff]);
		end
	end
	
	%% Detect key press
    for n = 1:2  % Update buffer
		masterTime = clock;
		
		tic; % tic must be here for update accuracy
		a(n,:) = inputSingleScan(s);
		pressed = a(n,:);
		
		if sum(pressed) < nKeys % Check whether a key has been pressed. 
							 % for each element in 'pressed': press = 0, no press = 1
			onset = a(mod(n - 2,2) + 1,:)- a(n,:);
			onset(find(onset < 0)) = 0;

			if sum(onset) > 0
				output.time = clock;
				output.Press = output.Press + 1;
				
				%% Write press event
				disp([onset, output.time]);
				output.Matrix = [output.Matrix; [output.Press, onset, output.time]];
				OutputFile = table(output.Matrix);
				writetable(OutputFile, strcat('OutputFile.', outputstr));                    
				output.Song = 0;
				onset = zeros(1,nKeys);
			end
		end
	end
end

%% End program
log = [log; [0, clock]];
logFile = table(log);
writetable(logFile, strcat('log.', outputstr));