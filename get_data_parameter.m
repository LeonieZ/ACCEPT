function dataP = get_data_parameter

%% Specify Data Parameter

dataP.name = [];

% directories (if empty, Matlab asks to specify them later)
dataP.input_folder = '/Users/ZeuneL/Documents/MATLAB/CTC_project/Data/single_data_set'; %path containing cartridge dirs
dataP.output_folder = [pwd filesep 'results']; %directory to save files

% number of frames
dataP.numFrames = 4;

% Threshold and Mask
dataP.samplefactor = 8;
dataP.thresholdChannel = 3;
dataP.thresholdOffset = [50; 25; 25; 0]; %[50 -- 20 --]
dataP.DapiChannel = 1;
dataP.channelEdgeremoval = 2;
% dataP.SizeMinFragment = 25; %was 9 /g 12 april 2013
% dataP.SizeMaxFragment = 1e6;
% dataP.SizeMinThumb = 25;
% dataP.SizeMaxThumb = 10000;

% scale data back to pseudo 12 bit?
dataP.scaleData = true;
% remove cartridge boundaries before processing? (CellSearch)
dataP.removeEdges = true;
% save segmented images?
dataP.saveSeg = true;

end

