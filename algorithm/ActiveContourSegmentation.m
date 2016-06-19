classdef ActiveContourSegmentation < DataframeProcessorObject
    %ACTIVECONTOUR_SEGMENTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        maskForChannels = [];
        lambda = [];
        inner_it = []
        breg_it = [];
        mu_update = [];
        single_channel = [];
        init = [];
        adaptive_reg = 0;
        adaptive_start = 0.01;
        adaptive_step = 0.05;
    end
    
    properties
        clear_border = 0;
        tol   = 1e-9;
    end
    
    properties (Constant)
        sigma = 0.1;
        tau   = 0.1;
        theta = 0.5;
    end
    
    
    methods
        function this = ActiveContourSegmentation(lambda, inner_it, breg_it, varargin)
            if nargin > 5
                this.single_channel = varargin{3};
            end
            
            if nargin > 4 && ~isempty(varargin{2})
                this.maskForChannels = varargin{2};
            end

            if isa(lambda,'numeric')
                this.lambda = lambda;
            elseif strcmp(lambda,'adaptive')
                this.lambda = this.adaptive_start;
                this.adaptive_reg = 1;
            elseif isa(lambda,'cell') && strcmp(lambda{1},'adaptive') && isa(lambda{2},'numeric') && isa(lambda{3},'numeric')
                this.adaptive_start = lambda{2};
                this.lambda = this.adaptive_start;
                this.adaptive_step = lambda{3};
                this.adaptive_reg = 1;
            end

            this.breg_it   = breg_it;
            this.inner_it  = inner_it;
            this.mu_update = inner_it+1;
            
            if nargin > 3
                this.init = varargin{1};
            end
        end
        
        function returnFrame = run(this, inputFrame)
            % Segmentation on Dataframe: this is the standard call via the graphical user interface
            if isa(inputFrame,'Dataframe')
                returnFrame = inputFrame;
                returnFrame.segmentedImage = false(size(inputFrame.rawImage));

                if isempty(this.maskForChannels) && isempty(this.single_channel)
                    this.maskForChannels = 1:1:inputFrame.nrChannels;
                elseif ~isempty(this.single_channel)
                    this.maskForChannels = zeros(1,inputFrame.nrChannels);
                    this.maskForChannels(this.single_channel) = this.single_channel;
                elseif size(this.maskForChannels,2) == 1
                    this.maskForChannels = this.maskForChannels(1) * ones(1,inputFrame.nrChannels);
                end

                if size(this.lambda,2) == 1
                    this.lambda = repmat(this.lambda,1, inputFrame.nrChannels);
                end

                if size(this.breg_it,2) == 1
                    this.breg_it = repmat(this.breg_it,1, inputFrame.nrChannels);
                end
                
                if ~isempty(this.init) 
                    if isa(this.init,'double') || isa(this.init,'logical')
                        cvInit = this.init;
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && isa(this.init{2},'char')
                        validatestring(this.init{1},{'otsu','triangle'});
                        validatestring(this.init{2},{'global','local'});
                        if strcmp(this.init{2},'global') && ~isempty(this.init{3})
                            threshSeg = ThresholdingSegmentation(this.init{1},'global',this.init{3},this.maskForChannels);
                        else
                            threshSeg = ThresholdingSegmentation(this.init{1},'local',[],this.maskForChannels);
                        end
                        cvInit = threshSeg.run(inputFrame.rawImage);
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && strcmp(this.init{1},'manual')
                        manualSeg = ThresholdingSegmentation('manual','local',[],[],[],this.init{2});
                        cvInit = manualSeg.run(inputFrame.rawImage);
                    else
                        cvInit = [];
                    end
                else
                    cvInit = [];
                end
               
                for i = 1:inputFrame.nrChannels
                    if any(this.maskForChannels == i)
                        tmp = bregman_cv(this, inputFrame, i, cvInit);
                        tmp = bwareaopen(tmp, 10);
                        returnFrame.segmentedImage(:,:,i) = tmp;
                    end
                end

                if isempty(this.single_channel) && isa(inputFrame,'Dataframe')
                    returnFrame.segmentedImage = returnFrame.segmentedImage(:,:,this.maskForChannels);
                end
                
                sumImage = sum(returnFrame.segmentedImage,3); 
                labels = repmat(bwlabel(sumImage,8),1,1,size(returnFrame.segmentedImage,3));
                returnFrame.labelImage = labels.*returnFrame.segmentedImage; 

            % Segmentation on double array: this case can be used for separate image segmentation and testing purposes
            elseif isa(inputFrame,'double') || isa(inputFrame,'single')
                returnFrame = false(size(inputFrame));

                if isempty(this.maskForChannels) && isempty(this.single_channel)
                    this.maskForChannels = 1:1:size(inputFrame,3);
                elseif ~isempty(this.single_channel)
                    this.maskForChannels = zeros(1,size(inputFrame,3));
                    this.maskForChannels(this.single_channel) = this.single_channel;
                end

                if size(this.lambda,2) == 1
                    this.lambda = repmat(this.lambda,1,size(inputFrame,3));
                end

                if size(this.breg_it,2) == 1
                    this.breg_it = repmat(this.breg_it,1,size(inputFrame,3));
                end
                
                if ~isempty(this.init) 
                    if isa(this.init,'double') || isa(this.init,'single') || isa(this.init,'logical')
                        cvInit = this.init;
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && isa(this.init{2},'char')
                        validatestring(this.init{1},{'otsu','triangle'});
                        validatestring(this.init{2},{'global','local'});
                        if strcmp(this.init{2},'local')
                            threshSeg = ThresholdingSegmentation(this.init{1},'local',[],this.maskForChannels);
                        elseif strcmp(this.init{2},'global') && ~isempty(this.init{3})
                            threshSeg = ThresholdingSegmentation(this.init{1},'global',this.init{3},this.maskForChannels);
                        end
                        cvInit = threshSeg.run(inputFrame);
                    elseif isa(this.init,'cell') && isa(this.init{1},'char') && strcmp(this.init{1},'manual')
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
                        tmp = bregman_cv(this, inputFrame, i, cvInit);
                        tmp = bwareaopen(tmp, 10);
                        returnFrame(:,:,i) = tmp;
                    end
                end

                if isempty(this.single_channel)
                    returnFrame = returnFrame(:,:,this.maskForChannels);
                end
                
            else
                error('Active Contour Segmentation can only be used on dataframes or double images.')
            end
        end
        
        function bin = bregman_cv(this, dataFrame, k, init)
            if isa(dataFrame,'Dataframe')
                f = dataFrame.rawImage(:,:,k);
            elseif isa(dataFrame,'double') || isa(dataFrame,'single')
                f = dataFrame;
            end
            % the data type of input data f dominates the general data type
            % used within bregman_cv, preferrably it is 'single'
            type = class(f);
            f = cast(f,type);

            % set lambda
            lambda_reg = this.lambda(k);

            % dimensions
            [nx, ny] = size(f);
            dim = ndims(f);

            %scale data f    
            f = f-min(f(:)); f = f/max(f(:));

            % initialize dual variable
            p = zeros(nx,ny,dim,type); % dims: nx x ny x dim, dual variable
            b = zeros(nx,ny,type); % dims: nx x ny , bregman variable

            if isempty(init)
                init(:,:,k) = f;
                % initialize primal variables
                u = zeros(nx,ny,type);
                u_bar = u; % dims: nx x ny
            else
                % initialize primal variables
                u = init(:,:,k);
                u_bar = u; % dims: nx x ny
            end

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
                f(dataFrame.mask) = mu0;
                useMask = true;
                mask = dataFrame.mask;
            end %note: in case you are using the AC function on a double image using a mask is not possible
            
            for l = 1:20

                %%%%%%%%%%%%%%% Bregman_CV_CORE %%%%%%%%%%%%%%%%%%%%%
                % this part is parallelized via C/mex and openMP code
                u = bregman_cv_core(f,nx,ny,lambda_reg,this.breg_it(k),this.inner_it,...
                                    this.tol,p,u,u_bar,b,this.sigma,this.tau,this.theta,...
                                    init(:,:,k),this.mu_update,mu0,mu1,useMask,mask);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                bin = u >= 0.5;

                if this.adaptive_reg == 1
                    stats = regionprops(bin,'Solidity','Eccentricity','PixelIdxList');
                    go_on = 0;

                    for s = 1:size(stats,1)
                        if size(stats(s).PixelIdxList,1) < 10 || stats(s).Eccentricity > 0.95
                            bin(stats(s).PixelIdxList) = 0;
                        end
                        if stats(s).Solidity < 0.95
                            go_on = 1;
                        end
                    end

                    if go_on == 1
                        D = bwdist(~bin);
                        D = -D;
                        D(~bin) = -Inf;
                        L = watershed(D);

                        bin(L <= 1) = 0;
                        bin(L > 1) = 1;
                        stats = regionprops(bin,'Solidity','Eccentricity','PixelIdxList');
                        go_on = 0;

                        for s = 1:size(stats,1)
                            if size(stats(s).PixelIdxList,1) < 3 || stats(s).Eccentricity > 0.95
                                bin(stats(s).PixelIdxList) = 0;
                            end
                            if stats(s).Solidity < 0.95
                                go_on = 1;
                            end
                        end
                    end

                    if go_on == 1
                        i = 1; j = 1;
                        lambda_reg = lambda_reg + this.adaptive_step;
                        p = zeros(nx,ny,dim); % dims: nx x ny x dim, dual variable
                        b = zeros(nx,ny); % dims: nx x ny , bregman variable

                        if isempty(init)
                            init(:,:,k) = f;
                            % initialize primal variables
                            u = zeros(nx,ny);
                            u_bar = u; % dims: nx x ny
                        else
                            % initialize primal variables
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
                bin = imclearborder(bin);
            end
        end
    end
    
end