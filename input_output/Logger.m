%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 
classdef Logger < handle
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
        function this = Logger(programLocation,level)
            this.logPath=[programLocation,filesep,'log',filesep];
            
            if ~exist([programLocation filesep 'log'], 'dir') 
                mkdir(programLocation, 'log');
            end
            
            this.fid = fopen(fullfile(this.logPath,this.logFile),'a');
            if nargin==2
            this.level=level;
            end
        end
        
        function entry(this,~,eventData)
            % General function to display and log events to a text file for easy debugging and
            % bookkeeping. Up to messages up to level 2 will also be displayed. 

            %only process logMessages that are below the current logging
            %level
            if eventData.logLevel <= this.level
                entry = [datestr(now,13),': ',eventData.message];
                fprintf(this.fid,'%s\r\n', entry);
                if eventData.logLevel <= 2
                    disp(entry)
                end
            end
        
        end
        function delete(this)
            fclose(this.fid);
        end
    end
end

    

