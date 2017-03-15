classdef DataframeProcessor < handle
    %DATAFRAMEPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
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
            if nargin > 0
                this.name = varargin{1};
            end
            
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
            if any(cellfun(@(x) ~isa(x,'DataframeProcessorObject'),this.pipeline))
                error('Cannot process dataframes. There are no DataframeProcessorObjects in the pipeline.')                
            end
            if isempty(this.pipeline)
                notify(this,'logMessage',logmessage(1,[this.name,'image not processed, applied an empty workflow on dataframe.']));
            else
                for i=1:numel(this.pipeline)
                    this.pipeline{i}.run(inputFrame);
                end 
            end
        end 
    end
    
end

