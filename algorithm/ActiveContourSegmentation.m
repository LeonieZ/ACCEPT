%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 
classdef ActiveContourSegmentation < DataframeProcessorObject
    %  ACTIVECONTOUR_SEGMENTATION Computes a segmentation of the input 
    %  frame/image using Active contour segmentation

    properties (SetAccess = private)
        maskForChannels = [];
        lambda = [];
        inner_it = []
        breg_it = [];
        mu_update = [];
        single_channel = [];
        init = [];
        %adaptive choice of reg. parameter yes/no
        adaptive_reg = 0;
        adaptive_start = 0.01;
        adaptive_step = 0.05;
        use_openMP = false;
        dilate = [];
    end

    properties
        clear_border = 0;
        tol   = 1e-13;
    end

    properties (Constant)
        sigma = 1/2.9; 
        tau   = 1/2.9; 
        theta = 0.5;
    end

    methods
        function this = ActiveContourSegmentation(lambda, inner_it, breg_it, varargin)
            if nargin > 7
                %dilate segmentation afterwards?
               this.dilate = varargin{5};
            end
            
            if nargin > 6
                %use openMP in mex file?
               this.use_openMP = varargin{4};
            end
            
            if nargin > 5
                %segment only one channel
                this.single_channel = varargin{3};
            end

            if nargin > 4 && ~isempty(varargin{2})
                %use mask for channels
                this.maskForChannels = varargin{2};
            end

            if isa(lambda,'numeric')
                %regularization parameter
                this.lambda = lambda;
            elseif strcmp(lambda,'adaptive')
                %lambda set adaptively
                this.lambda = this.adaptive_start;
                this.adaptive_reg = 1;
            elseif isa(lambda,'cell') && strcmp(lambda{1},'adaptive') && isa(lambda{2},'numeric') && isa(lambda{3},'numeric')
                %lambda set adaptively with given start and step values
                this.adaptive_start = lambda{2};
                this.lambda = this.adaptive_start;
                this.adaptive_step = lambda{3};
                this.adaptive_reg = 1;
            end
            %number of iterations
            this.breg_it   = breg_it;
            this.inner_it  = inner_it;
            this.mu_update = inner_it+1;

            if nargin > 3
                this.init = varargin{1};
            end
        end

        function returnFrame = run(this, inputFrame)
            % Segmentation on Dataframe: this is the standard call via the graphical user interface
            if isa(inputFrame,'Dataframe') && ~isempty(inputFrame.segmentedImage) %if segmentation is already filled
                returnFrame = inputFrame;
                if this.clear_border == 1
                    for i = 1:size(inputFrame.segmentedImage,3)
                        %remove objects touching the border
                        returnFrame.segmentedImage(:,:,i) = imclearborder(inputFrame.segmentedImage(:,:,i));
                    end
                    %create label image
                    sumImage = sum(returnFrame.segmentedImage,3);
                    labels = repmat(bwlabel(sumImage,4),1,1,size(returnFrame.segmentedImage,3));
                    returnFrame.labelImage = labels.*returnFrame.segmentedImage;
                end
            elseif isa(inputFrame,'Dataframe') && isempty(inputFrame.segmentedImage) %segmentation of dataframe
                %load and initialize data
                returnFrame = inputFrame;
                returnFrame.segmentedImage = false(size(inputFrame.rawImage));
                
                %fill mask variable with default values if not specified
                %before, otherwise according to given values
                if isempty(this.maskForChannels) && isempty(this.single_channel)
                    this.maskForChannels = 1:1:inputFrame.nrChannels;
                elseif isempty(this.maskForChannels) && ~isempty(this.single_channel)
                    this.maskForChannels = zeros(1,inputFrame.nrChannels);
                    this.maskForChannels(this.single_channel) = this.single_channel;
                elseif size(this.maskForChannels,2) == 1
                    this.maskForChannels = this.maskForChannels(1) * ones(1,inputFrame.nrChannels);
                end
                
                %use same lambda in each channel
                if size(this.lambda,2) == 1
                    this.lambda = repmat(this.lambda,1, inputFrame.nrChannels);
                end
                %use same bregman its in each channel
                if size(this.breg_it,2) == 1
                    this.breg_it = repmat(this.breg_it,1, inputFrame.nrChannels);
                end
                
                %fill initialization of segmentation
                if ~isempty(this.init)
                    if isa(this.init,'double') || isa(this.init,'logical')
                        %if segmentation is given
                        cvInit = this.init;
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && isa(this.init{2},'char')
                        %initialize with specified thresholding method
                        %(local or global)
                        validatestring(this.init{1},{'otsu','triangle'});
                        validatestring(this.init{2},{'global','local'});
                        if strcmp(this.init{2},'local')
                            threshSeg = ThresholdingSegmentation(this.init{1},'local',[],this.maskForChannels);
                            cvInit = threshSeg.run(inputFrame.rawImage);
                        elseif strcmp(this.init{2},'global') && ~isempty(this.init{3})
                            threshSeg = ThresholdingSegmentation(this.init{1},'global',this.init{3},this.maskForChannels);
                            cvInit = threshSeg.run(inputFrame.rawImage);
                        else 
                            cvInit = [];
                        end
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && strcmp(this.init{1},'manual')
                        %initialize with fixed thresholding
                        manualSeg = ThresholdingSegmentation('manual','local',[],[],[],this.init{2});
                        cvInit = manualSeg.run(inputFrame.rawImage);
                    else
                        cvInit = [];
                    end
                else
                    cvInit = [];
                end

                % Parallelize among channels if multiple channels are available,
                % otherwise use openMP if only one channel is processed
                chMask = this.maskForChannels(this.maskForChannels ~= 0); % indices of channels to be analyzed
                nbrChSeg = size(chMask,2);
                chSeg_uni = unique(chMask); %determine which channels should be segmented
                nbrChSeg_uni = size(chSeg_uni,2); %number of channels to be segmented
                if nbrChSeg > 1
                    % parallelize in Matlab and do not use openMP in C-code
                    this.use_openMP = 0;
                    segmentedImages = cell(nbrChSeg_uni,1);
                    parfor i = 1:nbrChSeg_uni
                        %call bregman segmentation code
                        tmp = bregman_cv(this,inputFrame,chSeg_uni(i),cvInit);
                        boundary = bwperim(tmp);
                        %remove small objects
                        tmp_cleared = bwareaopen(tmp - boundary,10);
                        %thicken remaining ones
                        tmp = bwmorph(tmp_cleared,'thicken',1);
                        %again (helps to remove unwanted small noise
                        %events)
                        boundary = bwperim(tmp);
                        tmp_cleared = bwareaopen(tmp - boundary,10);
                        %store segmentation
                        segmentedImages{i} = bwmorph(tmp_cleared,'thicken',1);
                    end
                    %fill dataframe with segmentation
                    for i = 1:inputFrame.nrChannels
                        if ismember(this.maskForChannels(i),chMask)
                            % store segmentation
                            if  ~isempty(this.dilate) && this.dilate(i) == 1
                                % dilate first if chosen
                                returnFrame.segmentedImage(:,:,i) = bwmorph(segmentedImages{chSeg_uni==this.maskForChannels(i)},'thicken',4);
                            else
                                returnFrame.segmentedImage(:,:,i) = segmentedImages{chSeg_uni==this.maskForChannels(i)};
                            end
                        end
                    end
                else
                    % only one channel, hence no parallelization in Matlab
                    % parallelize in C-code using openMP instead
                    % (problematic on Windows at the moment, no executable available) 
                    
                    %call bregman segmentation code
                    tmp = bregman_cv(this,inputFrame,chMask,cvInit);
                    %remove small objects
                    boundary = bwperim(tmp);
                    tmp_cleared = bwareaopen(tmp - boundary,10);
                    %thicken remaining ones
                    tmp = bwmorph(tmp_cleared,'thicken',1);
                    %again (helps to remove unwanted small noise
                    %events)
                    boundary = bwperim(tmp);
                    tmp_cleared = bwareaopen(tmp - boundary,10);
                    %store segmentation
                    returnFrame.segmentedImage(:,:,this.maskForChannels==chMask) = bwmorph(tmp_cleared,'thicken',1);
                end
                
                sumImage = sum(returnFrame.segmentedImage,3);
                labels = repmat(bwlabel(sumImage,4),1,1,size(returnFrame.segmentedImage,3));
                returnFrame.labelImage = labels.*returnFrame.segmentedImage;

            % Segmentation on double array: this case can be used for separate image segmentation and testing purposes
            elseif isa(inputFrame,'double') || isa(inputFrame,'single')
                %initialize output frame
                returnFrame = false(size(inputFrame));
                
                %fill mask for channels
                if isempty(this.maskForChannels) && isempty(this.single_channel)
                    this.maskForChannels = 1:1:size(inputFrame,3);
                elseif ~isempty(this.single_channel)
                    this.maskForChannels = zeros(1,size(inputFrame,3));
                    this.maskForChannels(this.single_channel) = this.single_channel;
                end
                
                %same lambda for all channels
                if size(this.lambda,2) == 1
                    this.lambda = repmat(this.lambda,1,size(inputFrame,3));
                end
                %same number of bregman its for all channels
                if size(this.breg_it,2) == 1
                    this.breg_it = repmat(this.breg_it,1,size(inputFrame,3));
                end

                %fill initialization for segmentation
                if ~isempty(this.init)
                    if isa(this.init,'double') || isa(this.init,'single') || isa(this.init,'logical')
                        %given segmentation
                        cvInit = this.init;
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && isa(this.init{2},'char')
                        %use specified thresholding method (global/local)
                        validatestring(this.init{1},{'otsu','triangle'});
                        validatestring(this.init{2},{'global','local'});
                        if strcmp(this.init{2},'local')
                            threshSeg = ThresholdingSegmentation(this.init{1},'local',[],this.maskForChannels);
                        elseif strcmp(this.init{2},'global') && ~isempty(this.init{3})
                            threshSeg = ThresholdingSegmentation(this.init{1},'global',this.init{3},this.maskForChannels);
                        end
                        cvInit = threshSeg.run(inputFrame);
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && strcmp(this.init{1},'manual')
                        %use fixed treshold
                        manualSeg = ThresholdingSegmentation('manual','local',[],[],[],this.init{2});
                        cvInit = manualSeg.run(inputFrame);
                    else
                        cvInit = [];
                    end
                else
                    cvInit = [];
                end

                for i = 1:size(inputFrame,3)
                    if any(this.maskForChannels == i)
                        %call bregman segmentation code
                        tmp = bregman_cv(this, inputFrame, i, cvInit);
                        %remove small objects
                        tmp = bwareaopen(tmp, 10);
                        %store segmentation
                        returnFrame(:,:,i) = tmp;
                    end
                end
                
                %fill channels with segmentation of frame specified in mask
                if isempty(this.single_channel)
                    returnFrame = returnFrame(:,:,this.maskForChannels);
                end

            elseif ~isa(inputFrame,'double') && ~isa(inputFrame,'Dataframe')
                error('Active Contour Segmentation can only be used on dataframes or double images.')
            end
        end

        function bin = bregman_cv(this, dataFrame, k, init)
            %segmentation method (core in mex file)
            if isa(dataFrame,'Dataframe')
                f = dataFrame.rawImage(:,:,k);
            elseif isa(dataFrame,'double') || isa(dataFrame,'single')
                f = dataFrame;
            end
            % the data type of input data f dominates the general data type
            % used within bregman_cv, preferrably it is 'single'
            type = 'single';
            f = cast(f,type);

            % set lambda
            lambda = this.lambda(k);

            % dimensions
            [nx, ny] = size(f);
            dim = ndims(f);

            %scale data f
            f = f-min(f(:)); f = f/max(f(:));

            if isempty(init)
                init(:,:,k) = f;
                % initialize primal variables as zero
                u = zeros(nx,ny,type);
                u_bar = u; % dims: nx x ny
            else
                % initialize primal variables with given init
                u = init(:,:,k);
                u_bar = u; % dims: nx x ny
            end
            
            %determine mu1 and mu0 used in active contour segmentation
            if max(max((init(:,:,k)<0.5))) == 1 && max(max((init(:,:,k)>=0.5))) == 1
                mu0 = max(mean(mean(f(init(:,:,k)<0.5))),0); % mean value outside object
                mu1 = max(mean(mean(f(init(:,:,k)>=0.5))),0); % mean value inside object
            elseif max(max((init(:,:,k)<0.5))) == 0
                mu0 = min(f(:));
                mu1 = mean(mean(f(init(:,:,k)>=0.5)));
            elseif max(max((init(:,:,k)>=0.5))) == 0
                mu0 = mean(mean(f(init(:,:,k)<0.5)));
                mu1 = max(f(:));
            end

            useMask = false;
            mask    = [];
            if isa(dataFrame,'Dataframe') && dataFrame.frameHasEdge == true && ~isempty(dataFrame.mask)
                %if dataframe has edge to be removed, set it to mean
                %background intensity
                f(dataFrame.mask)     = mu0;
                u(dataFrame.mask)     = 0;
                u_bar(dataFrame.mask) = 0;
                useMask = true;
                mask = dataFrame.mask;
            end %note: in case you are using the AC function on a double image using a mask is not possible
            
            %compute contour for max. 20 diffferent reg parameters
            maxContourUpd = 20;
            
            for l = 1:maxContourUpd
                
                %% Specify usage of C-implementation for Bregman CV Core
                useC = true;

                %%%%%%%%%%%%%%% Bregman_CV_CORE START %%%%%%%%%%%%%%%%%%%%%
                if (~useC)
                    % initialize dual variable
                    p = zeros(nx,ny,dim,type); % dims: nx x ny x dim, dual variable
                    b = zeros(nx,ny,type);     % dims: nx x ny , bregman variable
                    u = bregman_cv_core(f,nx,ny,lambda,this.breg_it(k),this.inner_it,...
                                        this.tol,p,u,u_bar,b,this.sigma,this.tau,this.theta,...
                                        init(:,:,k),this.mu_update,mu0,mu1,useMask,mask);
                    %figure; imagesc(u); colorbar;
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % C/mex code parallelized via openMP
                if (useC)
                    % cast to type (e.g. single) is needed due to C arrays
                    u = cast(u,type); u_bar = cast(u,type);
                    % init of dual variable p is done within C-code (calloc)
                    if this.use_openMP && exist('bregman_cv_core_mex_openMP','file') == 3
                        u = bregman_cv_core_mex_openMP(...
                                       f,nx,ny,lambda,this.breg_it(k),this.inner_it,...
                                       this.tol,u,u_bar,this.sigma,this.tau,this.theta,...
                                       mu0,mu1);
                    else
                        u = bregman_cv_core_mex(...
                                       f,nx,ny,lambda,this.breg_it(k),this.inner_it,...
                                       this.tol,u,u_bar,this.sigma,this.tau,this.theta,...
                                       mu0,mu1);
                    end
                    %figure; imagesc(u); colorbar;
                end
                %%%%%%%%%%%%%%% Bregman_CV_CORE END %%%%%%%%%%%%%%%%%%%%%%%
                
                %threshold solution
                bin = u >= 0.5;
                
                
                if this.adaptive_reg == 1 %if adaptive reg is chosen
                    % disp('Entering the adaptive segmentation case now...')
                    %compute solidity (Area/ConvexArea) and eccentricity of found objects
                    stats = regionprops(bin,'Solidity','Eccentricity','PixelIdxList');
                    go_on = 0;

                    for s = 1:size(stats,1)
                        if size(stats(s).PixelIdxList,1) < 10 || stats(s).Eccentricity > 0.98
                            %remove small and line-like objects
                            bin(stats(s).PixelIdxList) = 0;
                        end
                        if stats(s).Solidity < 0.95
                            % if objects are not close to convex consider to increase
                            % reg. parameter
                            go_on = 1;
                        end
                    end

                    if go_on == 1
                        %watershed solution to seperate clustered cells
                        D = bwdist(~bin);
                        D = -D;
                        D(~bin) = -Inf;
                        L = watershed(D);

                        bin(L <= 1) = 0;
                        bin(L > 1) = 1;
                        %compute again eccentricity and solidity
                        stats = regionprops(bin,'Solidity','Eccentricity','PixelIdxList');
                        go_on = 0;

                        for s = 1:size(stats,1)
                            if size(stats(s).PixelIdxList,1) < 3 || stats(s).Eccentricity > 0.95
                                %remove small or line like objects
                                bin(stats(s).PixelIdxList) = 0;
                            end
                            if stats(s).Solidity < 0.95
                                %if objects still not close to convex
                                %increase lambda and segment again
                                go_on = 1;
                            end
                        end
                    end

                    if go_on == 1
                        i = 1; j = 1;
                        %increase lambda
                        lambda = lambda + this.adaptive_step; %#ok<PROPLC>

                        if isempty(init)
                            init(:,:,k) = f;
                            % initialize primal variables as zero
                            u = zeros(nx,ny);
                            u_bar = u; % dims: nx x ny
                        else
                            % initialize primal variables with given init
                            u = init(:,:,k);
                            u_bar = u; % dims: nx x ny
                        end
                    else
                        break
                    end
                else
                    break
                end
            end
            
            if this.clear_border
                %remove objects touching the border
                bin = imclearborder(bin);
            end
        end
    end

end
