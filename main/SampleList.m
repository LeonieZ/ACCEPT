classdef SampleList < handle
    %SAMPLELIST keeps track if availablee samples are processed or not. 
    
    properties
        sampleProcessorId='empty';
        inputPath = '';
        resultPath = '';
        isToBeProcessed = [];
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
        function this=SampleList(procId,inputP,resultP,smpleNames,isProc,isToBeProc,loaderUsed)
            
            if nargin==7
                this.sampleProcessorId=procId;
                this.inputPath=inputP;
                this.resultPath=resultP;
                this.sampleNames=smpleNames;
                this.isProcessed=isProc;
                this.isToBeProcessed=isToBeProc;
                this.loaderToBeUsed=loaderUsed;
            end
        end
        
        function set_sampleProcessorId(this,value)
            this.sampleProcessorId=value;
            notify(this,'updatedProcessorId');
        end
        
        function set_inputPath(this,value)
            this.inputPath=value;
            notify(this,'updatedInputPath')
        end
        
        function set_resultPath(this,value)
            this.resultPath=value;
            notify(this,'updatedResultPath')
        end
        
    end
    
end

