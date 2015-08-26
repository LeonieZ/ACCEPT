classdef SampleList < handle
    %SAMPLELIST keeps track if availablee samples are processed or not. 
    
    properties
        sampleProcessorId='empty';
        inputPath = '';
        resultPath = '';
        toBeProcessed = [];
    end
    
    properties(SetAccess={?IO})
        sampleNames = {}
        isProcessed = []    
    end
    
    properties(Access={?IO})
        loaderToBeUsed = {}
    end
        
    events
        updatedProcessorId
        updatedInputPath
        updatedResultPath
    end
    
    methods
        function this=SampleList(procId,inputP,resultP,smpleNames,isProc,loaderUsed)
            if nargin==6
                this.sampleProcessorId=procId;
                this.inputPath=inputP;
                this.resultPath=resultP;
                this.sampleNames=smpleNames;
                this.isProcessed=isProc;
                this.loaderToBeUsed=loaderUsed;
                %this.isToBeProcessed=isToBeProc;
                this.toBeProcessed=zeros(size(isProc)); 
            end
        end
        
        function outputStr=save_path(this)
            outputStr=[this.resultPath,filesep,this.sampleProcessorId,filesep];
        end
            
        function set.sampleProcessorId(this,value)
            this.sampleProcessorId=value;
            notify(this,'updatedProcessorId');
        end
        
        function set.inputPath(this,value)
            this.inputPath=value;
            notify(this,'updatedInputPath')
        end
        
        function set.resultPath(this,value)
            this.resultPath=value;
            notify(this,'updatedResultPath')
        end
        
    end
    
end

