classdef SampleProcessor < handle
    %SAMPLEPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='Empty'
        version='0.1'
        dataframeProcessor;
        pipeline=cell(0);
        io;
    end
    
    events
        logMessage
    end
    
    methods
function this = SampleProcessor(dataframeProcessor,io,varargin)
            this.io = io;
            this.dataframeProcessor = dataframeProcessor;
            
            if nargin > 2
                this.name = varargin{1};
            end
            
            if nargin > 3
                this.pipeline = varargin{2};  
            end
            
            if nargin > 4
                this.version = varargin{3};
            end
            
            if isempty(varargin{1})
                this.name = 'Empty';
            end


%             if strcmp(this.name,'...') && isempty(this.pipeline)
%                 this.version = ...
%                 pipe = ;
%                 set.pipeline(pipe);
%             end
        end
        
        function outputStr = id(this)
            outputStr=[this.name,'_',this.version];
        end
      
        
        function run(this,inputSample)

            if isempty(this.dataframeProcessor) || isempty(this.pipeline)
                inputSample.id %only for testing!
                %notify(this,'logMessage',logmessage(1,[this.name,'no results, applied an empty workflow on sample.']));
            else
                for i = 1:numel(this.pipeline)
                    this.pipeline{i}.run(inputFrame);
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

