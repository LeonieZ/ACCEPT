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
classdef (ConstructOnLoad) LogMessage < event.EventData
    %LOGMESSAGE is a custom event class that is used to pass messages to the logger class. 

    
    properties
        message  %The log message, this has to be a string. 
        logLevel %1..4 future proofing so we can decide on the amount of logging. 
    end
    
    methods
        function this=LogMessage(level,message)
        validateattributes(level,{'numeric'},{'integer','>=',1,'<=',4},'','level');
        validateattributes(message,{'char'},{'nonempty'},'','message');
        this.message=message;
        this.logLevel=level;
        end
    end
    
end

