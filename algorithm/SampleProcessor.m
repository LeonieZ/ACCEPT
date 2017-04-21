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
classdef SampleProcessor < handle
    %SAMPLEPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        version
        dataframeProcessor;
        pipeline=cell(0);
        showInList=true;
    end
    
    events
        logMessage
    end
    
    methods
        function this = SampleProcessor(dataframeProcessor,varargin)
            if nargin > 0
                this.dataframeProcessor = dataframeProcessor;

                if nargin > 2
                    this.name = varargin{1};
                end

                if nargin > 3
                    this.pipeline = varargin{2};  
                end

                if nargin > 4
                    this.version = varargin{3};
                else
                    this.version = '0.1';
                end

                if isempty(this.name)
                    this.name = 'Empty';
                end
            end
         end
        
        function outputStr = id(this)
            outputStr=[this.name,'_',this.version];
        end
      
        
        function run(this,inputSample)

            if isempty(this.pipeline)
                notify(this,'logMessage',logmessage(1,[this.name,'no results, applied an empty workflow on sample.']));
            else
                for i = 1:numel(this.pipeline)
                    this.pipeline{i}.run(inputSample);
                end
            end
        end
        
        function  set.pipeline(this,value)
            if any(cellfun(@(x) ~isa(x,'SampleProcessorObject'),value))
                error('cannot add non workflow_objects to algorithm')                
            end
            this.pipeline=value;
        end
        
        
     
    end
    
end

