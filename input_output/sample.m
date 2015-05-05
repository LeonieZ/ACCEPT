classdef sample < handle
    %This class will hold all essential data related variables 
    
    properties
        type='Default'; % this can be replaced with a specific data type such as CellSearch. 
        
        scaledData = true;   % scale data back to pseudo 12 bit?
        removeEdges = true; % do we need to removeEdges using this datatype (for example CellSearch )

        % We will have to discuss our naming convention. I think we should keep
        % track of both the flouphore and its target, but it gets confusing \G.
        channelNames={'DAPI','FITC','PE','APC'};
        channelTargets={'DNA','Empty','CK','CD45'}; 
        numChannels = 4;
        DNAChannel = 1;
        inclusionChannel=3;
        exclusionChannel=4;
        channelEdgeremoval=2;



% variables that havent been replaced yet.
%ACTC.Algoritm.saveSegmentation = true; % save segmented images?

% temperary struct containing file names which will be reused for each
% sample. They should not live in a global variable
% dataP.temp.imageFileNames   = [];
% dataP.temp.imageinfos       = [];
% dataP.temp.imagesAreFromCT  = [];
% dataP.temp.imagesHaveOffset = [];
% dataP.temp.imageSize        = [];

% Some old variables from the original script that should not live here: 
% dataP.SizeMinFragment = 25; %was 9 /g 12 april 2013
% dataP.SizeMaxFragment = 1e6;
% dataP.SizeMinThumb = 25;
% dataP.SizeMaxThumb = 10000;

% Threshold and Mask 
% ACTC.Data.samplefactor = 8;
% dataP.thresholdChannel = 3;
% ACTC.Data.maskForChannel = [1, 3, 3, 3]; %a 3d mask is made so make sure that masks that should be connected are next to eachother
% ACTC.Data.thresholdOffset = [50, 0, 30, 70]; %[50 -- 20 --]
        
        CTCLocations
    end
    methods
        function Data=Data()
            %construction function
        end
        function load_image(i)
        end
    end
    methods (Access = protected) 
        function get_available_types(self)
            
        
            
        end
    end
end
