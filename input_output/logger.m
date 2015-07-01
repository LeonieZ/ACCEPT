classdef logger < handle
% class that deals with the logging. Is quite simple now can be expanded
% later /G.
    properties
        logPath
        logFile='log.txt'
        fid
        sessionlog
    end
    
    methods
        function self=logger(programLocation)
            self.logPath=[programLocation,filesep,'log',filesep];
            
            if ~exist([programLocation filesep 'log'], 'dir') 
                mkdir(programLocation, 'log');
            end
            
            self.fid = fopen(fullfile(self.logPath,self.logFile),'a');
        end
        
        function entry(self,entry,saveToFile,display)
            % General function to log events to a text file for easy debugging and
            % bookkeeping. Can also display the entry if required.
            switch nargin 
                case 0
                    error('actc:logger.entry:TooManyInputs', ...
                        'requires at most 3 optional inputs');
                case 1
                    saveToFile=1;
                    display=0;
                case 2
                    display = 0;

            end

            entry = [datestr(now,13),': ',entry];

            if saveToFile
                fprintf(self.fid,'%s\r\n', entry);
            end

            if display
                disp(entry)
            end
        
        end
        function delete(self)
            fclose(self.fid);
        end
    end
end

    

