classdef Default < Loader
    %DEFAULT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='Default'
        hasEdges='false'
        pixelSize=1
        sample
    end
    
    methods
        function new_sample_path(this,samplePath)
        
        end
        
        function dataFrame = load_data_frame(this,frameNr)
        
        end
    end
    
end

