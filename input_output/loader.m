classdef (Abstract) loader < handle
    %LOADER abstract loading class  
    %   The io class needs input for each data type. The loader class
    %   defines the functions which must be implemented in its subclasses
    %   so that the io class is able to load the appropriate data. 
    
    properties
        loaderType
        imagePath
        priorPath
        nrOfFrames
        nrOfChannels
        imageSize
        sample
    end
    
    events
        logMessage
    end
    
    
    methods
        function sample=load_sample(self,samplePath)
        
        end
       
        function dataFrame = load_data_frame(self,frameNr)

        end
   end
    methods(Static)
        function bool = can_load_this_folder(self,path)
            %function that must be present in all loader types to test
            %if the current sample can be loaded by this class. 
            bool=false;
        end
    end
end

