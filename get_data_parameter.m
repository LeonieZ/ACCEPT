function dataP = get_data_parameter

%% Specify Data Parameter

dataP.name = [];

% directories (if empty, Matlab asks to specify them later)
dataP.input_folder = []; %'/Users/ZeuneL/Documents/MATLAB/CTC_project/Data/single_data_set'; %path containing cartridge dirs
dataP.output_folder = []; %[pwd filesep 'results']; %directory to save files

% We will have to discuss our naming convention. I think we should keep
% track of both the flouphore and its target, but it gets confusing \G.
dataP.numChannels = 4;
dataP.channelNames={'DAPI','FITC','PE','APC'};
dataP.channelTargets={'DNA','Empty','CK','CD45'}; 

% Threshold and Mask 
dataP.samplefactor = 8;
dataP.thresholdChannel = 3;
dataP.maskForChannel = [1, 3, 3, 3]; %a 3d mask is made so make sure that masks that should be connected are next to eachother
dataP.thresholdOffset = [50; 25; 25; 0]; %[50 -- 20 --]
dataP.DNAChannel = 1;
dataP.channelEdgeremoval = 2;
% dataP.SizeMinFragment = 25; %was 9 /g 12 april 2013
% dataP.SizeMaxFragment = 1e6;
% dataP.SizeMinThumb = 25;
% dataP.SizeMaxThumb = 10000;


%A set of temperary file names which will be reused for each sample.
dataP.temp.imageFileNames   = [];
dataP.temp.imageinfos       = [];
dataP.temp.imagesAreFromCT  = [];
dataP.temp.imagesHaveOffset = [];
dataP.temp.imageSize        = [];
% scale data back to pseudo 12 bit?
dataP.scaleData = true;

% remove cartridge boundaries before processing? (CellSearch)
dataP.removeEdges = true;
% save segmented images?
dataP.saveSeg = true;

end

