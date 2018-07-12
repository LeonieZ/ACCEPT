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
classdef CustomCsv < handle
    %Class for loading of the xls files created by the icy plugin.
    
    properties
     
    end
    
    methods 
        function channelsUsed=look_for_custom_channels(this,samplePath)
            channelsUsed=[];
            [sample.priorPath,bool]=this.find_dir(samplePath,'csv',1);
            if bool==1 
                try t=readtable([sample.priorPath filesep 'customChannels.csv'],'delimiter',';','Format', ['%s','%s']);
                    channelsUsed=t.channelUsed;
                catch
                    %add logging
                end
            else
                %add logging
            end
        end
    end
    methods(Static)
        function create_custom_text(fileName,channelsUsed)
            n=numel(channelsUsed);
            names={'Exclusion Marker','Nucleus','Inclusion Marker', 'Additional Marker 1', 'Additional Marker 2','Additional Marker 3'};
            channelsUsed=[names(1:n);channelsUsed];
            t=table(names(1:n)',channelsUsed','variableNames',{'Type','channelsUsed'});
            writetable(t,'test.csv','delimiter',';')
        end
    end
end