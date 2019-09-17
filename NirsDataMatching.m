classdef NirsDataMatching
    %to match log files to NIRS
    %%
    properties
        Property1
    end
    %%I Think this was attempt 1 on NIRS Trigger Matchingo
    
    
    
    
    
    
    %from .log files (xcl or txt format) find all "New Trial" Times, save the line and pull out the relevant
    %strings if any
    methods (Static)
        %%
        %Done
        %Edited to only pull out the trigger data were looking for.
        %Output matches that of NirsLog2Table()
        function [SortedLogTriggerTimes, TriggerText] = TriggerLog2Table(filePath)
            logFile = importdata(filePath);
            counter = 1;
            outputCell = cell(length(logFile),4);
            for i = 1:length(logFile)
                if(contains(string(logFile(i)),"New trial"))
                    line = strsplit(string(logFile(i)),'\t');
                    identifiers = extractBetween(line(3),"'","'");
                    try
                        outputCell(counter,:) = {line(1),identifiers(1),identifiers(2),line(3)};
                        
                    catch
                        if(isempty(identifiers))
                            outputCell(counter,:) = {line(1)," "," ",line(3)};
                        else
                            outputCell(counter,:) = {line(1),identifiers(1)," ",line(3)};
                        end
                    end
                    counter=counter+1;
                end
            end
            xls = outputCell(~cellfun('isempty',outputCell(:,1)),:);
            logFileStrings = xls(:,2:end);
            blockTimeIndices = (find(ismember(transpose([logFileStrings{:,1}]),'selectBlock')));
            TriggerText = logFileStrings(blockTimeIndices,:);
            TriggerText = cellfun(@char,TriggerText,'UniformOutput',false);
            clear('logFileStrings');
            for i=1:length(blockTimeIndices)
                unsortedLogData.TriggerTimes(i,:) = xls(blockTimeIndices(i),:);%grab the lines that signify block start
            end
            unsortedLogData.TriggerTimesString = [unsortedLogData.TriggerTimes{:,1}];
            SortedLogTriggerTimes = sort(str2num(char(unsortedLogData.TriggerTimesString(:))));
            
            
        end
        %%
        %DONE
        function out = NirsLog2Table(nirsFile)
            fileData = load(nirsFile,'-mat');
            indexArr = find(fileData.s);
            tData = repmat(fileData.t,length(indexArr));
            triggerTimes = tData(indexArr);
            out = triggerTimes;
            
            
            
        end
        %Inputs should be file path of .log file and .nirs file to match
        %together
        %Output is the matched relative trigger times normalized to 0 and
        %plot unaligned triggers of both files and aligned versions of each
        %file
        
        
        
        %fairly hardcoded when finding nirs to log so errors will happen
        %and wont be caught easily
        function [nirsFile,logFile] = matchLogFile2Nirs(nirsFile)
            [path,name,~] = fileparts(nirsFile);
            nameStrings(:) = strsplit(name,'_');
            IDstring = char(nameStrings(length(nameStrings)));
            IDstringToSearch = strcat(path,'/*',IDstring(1:end-2),'*.log');
            
            logFileStruct = dir(IDstringToSearch);
            logFile = strcat(logFileStruct.folder,'/',logFileStruct.name);
        end
        
        
        
        
        
        %%
        function [TriggerMatchedOutput,logTriggers,nirsTriggers,triggerTimes] = run(nirsFile,logFile)
            if nargin<2
                [nirsFile,logFile] = NirsDataMatching.matchLogFile2Nirs(nirsFile);
            end
            [TriggerMatchedOutput,logTriggers,nirsTriggers,triggerTimes] = NirsDataMatching.matchLogTriggerTimeToNirsTriggerTime(nirsFile,logFile);
        end
        
        
        %%
        function [TriggerMatchedOutput,logTriggers,nirsTriggers,triggerTimes] = matchLogTriggerTimeToNirsTriggerTime(nirsFile,logFile)
            
            %Get pertinent data from log and nirs files
            %only pulls in trigger times
            [triggerTimes.SortedLogTriggerTimes, triggerTimes.BlockText] = NirsDataMatching.TriggerLog2Table(logFile);%Trigger Blocks with time, and block stamps
            triggerTimes.SortedNirsTriggerTimes = sort(NirsDataMatching.NirsLog2Table(nirsFile));%Time from nirs files of triggers and start and end trigger time
            
            
            %identify lowest time trigger to be start and mark highest
            %trigger to end trigger
            triggers.tNirsStart = min(triggerTimes.SortedNirsTriggerTimes);%match based on the time difference for that trigger
            triggers.tNirsEnd = max(triggerTimes.SortedNirsTriggerTimes);%if no matches are apparent for tStart try matching on tEnd
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            triggerTimes.TimeDiff.SortedNirsTimeDifferences = (diff(triggerTimes.SortedNirsTriggerTimes(:)-triggers.tNirsStart));% differences,normalizes NIRS times into numeric order
            triggerTimes.TimeDiff.SortedLogTimeDifferences= diff(triggerTimes.SortedLogTriggerTimes);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            
            
            
            
            triggers.tLogStarti = triggerTimes.SortedLogTriggerTimes(1);
            triggers.tLogEndi = triggerTimes.SortedLogTriggerTimes(length(triggerTimes.SortedLogTriggerTimes));
            %which file has more triggers.
            maxTriggerLength = max(length(triggerTimes.TimeDiff.SortedLogTimeDifferences),length(triggerTimes.TimeDiff.SortedNirsTimeDifferences));
            minTriggerLength = min(length(triggerTimes.TimeDiff.SortedLogTimeDifferences),length(triggerTimes.TimeDiff.SortedNirsTimeDifferences));
            %Assuming no missing triggers
            possiblePermutations = ((maxTriggerLength)-(minTriggerLength)+1);
            
            diffTable = zeros(minTriggerLength,1);
            MSETable = zeros(possiblePermutations,1);
            
            logVal = 0;
            if(maxTriggerLength == length(triggerTimes.TimeDiff.SortedNirsTimeDifferences))%if we have more nirs triggers than log
                for i = 1:possiblePermutations
                    offset = i-1;%this is the real offset since matlab doesnt let you start at 0
                    diffTable(:) = triggerTimes.TimeDiff.SortedNirsTimeDifferences(i:offset+minTriggerLength)-triggerTimes.TimeDiff.SortedLogTimeDifferences(:);
                    diffTable(:) = diffTable.^2;
                    diffTableMean = sum(diffTable)/length(diffTable);
                    MSETable(i) = diffTableMean;
                    logVal = 1;
                    
                end
                
                
                
            else%if we have more log triggers than nirs
                for i = 1:possiblePermutations
                    offset = i-1;%this is the real offset since matlab doesnt let you start at 0
                    diffTable(:) = triggerTimes.TimeDiff.SortedLogTimeDifferences(i:offset+minTriggerLength)-triggerTimes.TimeDiff.SortedNirsTimeDifferences(:);
                    diffTable(:) = diffTable.^2;
                    diffTableMean = sum(diffTable)/length(diffTable);
                    MSETable(i) = diffTableMean;
                end
            end
            
            [value,TriggerMatchedOutput] = min(MSETable(:));%needs better name
            
            if(logVal == 1)
                %logTriggers = padarray(triggerTimes.SortedLogTriggerTimes,TriggerMatchedOutput-1);
            end
            logTriggers = triggerTimes.TimeDiff.SortedLogTimeDifferences;
            nirsTriggers = triggerTimes.TimeDiff.SortedNirsTimeDifferences;
            
            
            %TO DO
            %Step through and look at the differences to see if we can
            %match any of them visually and code to match
            
        end
        function plotVals(nirsFile)
            nirs = load(nirsFile,'-mat');
            [nirsFile, logFile] = NirsDataMatching.matchLogFile2Nirs(nirsFile);
            offset = NirsDataMatching.matchLogTriggerTimeToNirsTriggerTime(nirsFile,logFile)-1;
            
            
            
            
        end
    end
end

