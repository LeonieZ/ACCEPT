classdef MCBP < Loader
    %MCBP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name='MCBP'
        hasEdges='false'
        pixelSize
        channelNames
        channelEdgeRemoval
        sample 
    end
    
    events
        logMessage
    end
    
    methods
        function new_sample_path(this,samplePath)
        end
        function dataFrame = load_data_frame(this,frameNr)
        end
        function dataFrame = load_thumb_frame(this,frameNr,option)
        end
        function frameOrder = calculate_frame_nr_order(this)
        end
    end
   
    methods(Access=private)
        
    end
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            bool=false;
        end
    end
end

