function algP=get_alg_parameter

%% Specify Algorithm Parameter

% segmentation method
% algP.segMeth = @convexSeg; % no reasonable results yet..
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
algP.processXML = false;

% classify results?
algP.classify = false;

end

