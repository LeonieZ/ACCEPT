classdef logger < handle
% class that deals with the logging. Is quite simple now can be expanded
% later /G.
    properties
        logPath
        logFile='log.txt'
        fid
        sessionlog
        level=4; % There are 4 log levels with increasing detail. 
                 % Level 1=critical contains messages that are always displayed. 
                 % Level 2=logging containts messages of important steps. 
                 % Level 3=verbose contains all information on data processing.
                 % Level 4=debugging contains everthing. 
    end
    
    methods
        function self=logger(programLocation,level)
            self.logPath=[programLocation,filesep,'log',filesep];
            
            if ~exist([programLocation filesep 'log'], 'dir') 
                mkdir(programLocation, 'log');
            end
            
            self.fid = fopen(fullfile(self.logPath,self.logFile),'a');
            if nargin==2
            self.level=level;
            end
        end
        
        function entry(self,~,eventData)
            % General function to display and log events to a text file for easy debugging and
            % bookkeeping. Up to messages up to level 2 will also be displayed. 

            %only process logMessages that are below the current logging
            %level
            if eventData.logLevel <= self.level
            entry = [datestr(now,13),': ',eventData.message];
            fprintf(self.fid,'%s\r\n', entry);
            if eventData.logLevel <= 2
                disp(entry)
            end
            end
        
        end
        function delete(self)
            fclose(self.fid);
        end
    end
end

    

