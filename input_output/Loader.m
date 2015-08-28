classdef (Abstract) Loader < handle
    %LOADER abstract loading class  
    %   The io class needs input for each data type. The loader class
    %   defines the functions which must be implemented in its subclasses
    %   so that the io class is able to load the appropriate data. 
    
    properties(Abstract)
        name
        hasEdges
        pixelSize
        sample
        
    end
    
    events
        logMessage
    end
    
    
    methods(Abstract)
        new_sample_path(this,samplePath)
        dataFrame = load_data_frame(this,frameNr)
    end
     
    methods
          
    end
    
    methods(Static)
        function bool = can_load_this_folder(path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            bool=false;
        end
    end
end

