function = detectPress()
for n = 1:2  % Update buffer
        masterTime = clock;
		
        tic; % tic must be here for update accuracy
        a(n,:) = inputSingleScan(s);
        pressed = a(n,:);
        
        if sum(pressed) ~= 4 % Check whether a key has been pressed. 
							 % for each element in pressed: Press = 0, no press = 1
            for j = 1:length(pressed) % Scan the signal sent by each key
                if a(mod(n - 2,2) + 1,j) == 1 && a(n,j) == 0 % Check whether the press is an onset of press.
                    onset(j) = 1;
				end
            end
			if sum(onset) > 0
				% Count the key press
				output.time = clock;
				output.Press = output.Press + 1; % Transfers info to output
				
				%% Write press event
				disp([onset, output.time]);
				output.Matrix = [output.Matrix; [output.Press, currentFile, onset, output.time]];
				OutputFile = table(output.Matrix);
				writetable(OutputFile, strcat('OutputFile.', outputstr));                    
				output.Song = 0;
				onset = zeros(1,4);
			end
        end
    end