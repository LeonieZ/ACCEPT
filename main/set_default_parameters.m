function set_default_parameters();
% Set default parameters to the global for the actc program.
% the following substruct are defined:
% Program   -> contains all values relevant to the general program such as
%              version paths etc.
% Data      -> contains all sample specific values these will be
%              these values will be overwritten by the input script
% Algorithm -> contains all values relevant to the image processing. 
% 

global ACTC;

%define default program parameters 
%Lets include a default example folder with both the input and results. 
ACTC.Program.logfile='actc_log.txt';  
ACTC.Program.input_folder= [pwd filesep 'example' filesep 'test_images']; %path containing image folders
ACTC.Program.output_folder= [pwd filesep 'example' filesep 'results'];    %directory to save files


ACTC.Data.removeEdges = true; % do we need to removeEdges using this datatype (for example CellSearch )

ACTC.Data.type='Default' % this can be replaced with a specific data type such as CellSearch. 
ACTC.Data.scaleData = true;   % scale data back to pseudo 12 bit?

% We will have to discuss our naming convention. I think we should keep
% track of both the flouphore and its target, but it gets confusing \G.
ACTC.Data.numChannels = 4;
ACTC.Data.channelNames={'DAPI','FITC','PE','APC'};
ACTC.Data.channelTargets={'DNA','Empty','CK','CD45'}; 
ACTC.Data.DNAChannel = 1;
ACTC.Data.inclusionChannel=3;
ACTC.Data.exclusionChannel=4;
ACTC.Data.channelEdgeremoval=2;


algP.segMeth = @thresholding;
algP.threshMeth = @maxTriangle;
algP.thresh = [];

% profile on?
algP.profile_on = false;

% algP.feedback = true;
algP.save_result = true;
algP.ignore_existing_results = true;

% parallel processing
algP.parallelProcessing = false; % use parallel processing toolbox? true or false
algP.numCores = 2; % number of cores, if not specified Matlab uses the number of physcial cores

% segmentation method
algP.segMethod = @triangle_method;

% process xml file if available?
algP.processXML = true;

% classify results?
algP.classify = true;


ACTC.Algoritm.saveSegmentation = true; % save segmented images?

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
ACTC.Data.samplefactor = 8;
%dataP.thresholdChannel = 3;
ACTC.Data.maskForChannel = [1, 3, 3, 3]; %a 3d mask is made so make sure that masks that should be connected are next to eachother
ACTC.Data.thresholdOffset = [50, 0, 30, 70]; %[50 -- 20 --]
 
end












