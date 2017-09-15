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
classdef DataframeProcessor < handle
    %  DATAFRAMEPROCESSOR is the base class for all possible processors of 
    %  frames. Adapted to each use case by specifying a pipeline how to
    %  process the frames.
    %  There are two levels, sample and dataframe level. All
    %  SampleProcessor/-objects act on sample level, while
    %  DataframeProcessor/-objects acts on an individual frame
    
    properties
        name='Empty'
        version='0.1'
        pipeline=cell(0);
    end
    
    events
        logMessage
    end
    
    methods
        function this = DataframeProcessor(varargin)
            %specify name
            if nargin > 0
                this.name = varargin{1};
            end
            %specify pipeline with dataframeprocessorObjects acting on
            %individual frame
            if nargin > 1
                this.pipeline = varargin{2};  
            end
            
            if nargin > 2
                this.version = varargin{3};
            end
            
            if isempty(this.name)
                this.name = 'Empty';
            end
        end
        
        
        function run(this,inputFrame)
            % run function, starts each dataframeprocessor object
            % successively
            
            %check if pipeline is only filled with DataframeProcessorObjects
            if any(cellfun(@(x) ~isa(x,'DataframeProcessorObject'),this.pipeline))
                error('Cannot process dataframes. There are no DataframeProcessorObjects in the pipeline.')                
            end
            %check if pipeline is not empty
            if isempty(this.pipeline)
                notify(this,'logMessage',logmessage(1,[this.name,'image not processed, applied an empty workflow on dataframe.']));
            else
                %start processing
                for i=1:numel(this.pipeline)
                    this.pipeline{i}.run(inputFrame);
                end 
            end
        end 
    end
    
end

