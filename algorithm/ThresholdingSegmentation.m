classdef ThresholdingSegmentation < DataframeProcessorObject
    %THRESHOLDING_SEGMENTATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        thresholds = [];
        maskForChannels = [];
        meth = [];
        range = [];
        offset = [];
    end
    
    properties (Access = public)
        histogram = [];
    end
    
    methods
        function this = ThresholdingSegmentation(meth,range,varargin)
             
            %varargin(1) = masksforchannels, varargin(2) = offsets varargin(3) =
            %thresholds of manual ones
            
            validatestring(meth,{'otsu','triangle','manual'});
            this.meth = meth;
            
            validatestring(range,{'global','local'});
            this.range = range;
            
            if nargin > 3
                this.maskForChannels = varargin{1};  
            end
            
            if nargin > 4
                this.offset = varargin{2};
            end
            
            if nargin > 5
                this.thresholds = varargin{3};
            end
            
            if strcmp(this.meth,'manual') && isempty(this.thresholds)
                error('Please specify the threshold.')
            end
            
        end
        
        function returnFrame = run(this,inputFrame)
            if isa(inputFrame,'Dataframe')
                returnFrame = inputFrame;
                returnFrame.segmentedImage = false(size(inputFrame.rawImage));
                bins = 65535;

                if isempty(this.offset)
                    this.offset = zeros(1,inputFrame.nrChannels);
                end

                if isempty(this.maskForChannels)
                    this.maskForChannels = 1:1:inputFrame.nrChannels;
                end

                this.histogram = zeros(1,bins,inputFrame.nrChannels);

                %create histogram if thresholding is local otherwise we assume
                %this was already done.

                if strcmp(this.range,'local') && ~strcmp(this.meth,'manual')
                    this.create_local_hist(inputFrame);
                end

                if ~strcmp(this.meth,'manual')
                    this.calculate_threshold()
                end

                for i = 1:inputFrame.nrChannels
                    tmp = inputFrame.rawImage(:,:,i) > this.thresholds(i);
                    if inputFrame.frameHasEdge == true && ~isempty(inputFrame.mask)
                        tmp(inputFrame.mask) = false;
                    end
                    tmp = bwareaopen(tmp, 10);
                    returnFrame.segmentedImage(:,:,i) = tmp;    
                end
            elseif isa(inputFrame,'double') || isa(inputFrame,'single') || isa(inputFrame,'uint8') || isa(inputFrame,'uint16')
                % note: 1. in case you are using the TS function on a double/single/... image using a mask is not possible
                % 2. not for images scaled from 0 to 1.
                returnFrame = false(size(inputFrame));
                bins = 65535;

                if isempty(this.offset)
                    this.offset = zeros(1,size(inputFrame,3));
                end

                if isempty(this.maskForChannels)
                    this.maskForChannels = 1:1:size(inputFrame,3);
                end

                this.histogram = zeros(1,bins,size(inputFrame,3));

                %create histogram if thresholding is local otherwise we assume
                %this was already done.

                if strcmp(this.range,'local') && ~strcmp(this.meth,'manual')
                    this.create_local_hist(inputFrame);
                end

                if ~strcmp(this.meth,'manual')
                    this.calculate_threshold()
                end

                for i = 1:size(inputFrame,3)
                    tmp = inputFrame(:,:,i) > this.thresholds(i);
                    tmp = bwareaopen(tmp, 10);
                    returnFrame(:,:,i) = tmp;    
                end
            else
                error('Thresholding Segmentation can only be used on dataframe or single/double/uint8/uint16 images.')
            end
        end
        
        function calculate_threshold(this)
            switch this.meth
                case 'otsu'
                    this.thresholds = this.otsu_method() + this.offset;
                case 'triangle'
                    this.thresholds = this.triangle_method() + this.offset;
            end
        end
        
        function create_local_hist(this, inputFrame)
            if isa(inputFrame,'Dataframe')
                for j = 1:inputFrame.nrChannels
                    if any(this.maskForChannels == j)                
                        imTemp = inputFrame.rawImage(:,:,j);

                        if inputFrame.frameHasEdge
                            imTemp = imTemp(~inputFrame.mask);
                        end
                        this.histogram(:,:,j) = histc(imTemp(:),1:1:numel(this.histogram(:,:,j)))';
                    end
                end
            elseif isa(inputFrame,'double') || isa(inputFrame,'single') || isa(inputFrame,'uint8') || isa(inputFrame,'uint16')
                for j = 1:size(inputFrame,3)
                    if any(this.maskForChannels == j)                
                        imTemp = inputFrame(:,:,j);
                        this.histogram(:,:,j) = histc(imTemp(:),1:1:numel(this.histogram(:,:,j)))';
                    end
                end
            end
        end
            
        
        function thresh = otsu_method(this)
            % Function carried over from Matlab function graythresh.
            hist = this.histogram;
            thresh = zeros(1,size(hist,3));
            
            for i = 1:size(hist,3)
                if any(this.maskForChannels == i)
                    % Variable names are chosen to be similar to the formulas in
                    % the Otsu paper.

                    num_bins = size(hist(:,:,i),2);
                    p = hist(:,:,i) / sum(hist(:,:,i));
                    omega = cumsum(p);
                    mu = cumsum(p .* (1:num_bins));
                    mu_t = mu(end);

                    sigma_b_squared = (mu_t * omega - mu).^2 ./ (omega .* (1 - omega));

                    % Find the location of the maximum value of sigma_b_squared.
                    % The maximum may extend over several bins, so average together the
                    % locations.  If maxval is NaN, meaning that sigma_b_squared is all NaN,
                    % then return 0.
                    maxval = max(sigma_b_squared);
                    isfinite_maxval = isfinite(maxval);
                    if isfinite_maxval
                      thresh(1,i) = mean(find(sigma_b_squared == maxval));
                    else
                      thresh(1,i) = 1.0;
                    end
                end
            end
            thresh = thresh(this.maskForChannels);
        end
        
        function thresh = triangle_method(this)
            % Function carried over from old ACTC script by Sjoerd.
            % adapted it a bit  - need to test if it works correctly!
            hist = this.histogram;
            thresh = zeros(1,size(hist,3));
            num_bins = size(hist(:,:,1),2);
            
            for i = 1:size(hist,3)
                if any(this.maskForChannels == i)
                    % function to determine a threshold value using the "triangle threshold"
                    % method. This method determines the maximum distance of the image
                    % histogram to a line from the maximum count to the maximum bin. 

                    % determine maximum counts and index to derive slope
                    hist_temp=smooth(hist(:,:,i),10)';
                    maxBin = find(hist_temp, 1, 'last');
                    [maxCounts, index]= max(hist_temp);

                    % if maximum number of pixels are saturated, neglect these pixels in
                    % determining the threshold
                    if index == num_bins
                        hist_temp(end) = 0; 
                        [maxCounts, index]= max(hist_temp);
                    end
                    rcRamp = (hist_temp(maxBin)-maxCounts)/(maxBin-index);

                    % solve linear equation ax+b=-(x-c)/a+d for x
                    % solution: x = (d-b+c/a)/(a+1/a)
                    xCrossing = (hist_temp(index:maxBin)-maxCounts+((index:1:maxBin)-index)/rcRamp)/(rcRamp+1/rcRamp);
                    yCrossing = rcRamp*xCrossing + maxCounts;

                    distToRamp = sqrt((xCrossing-(index:1:maxBin)).^2+(yCrossing-hist_temp(index:maxBin)).^2);
                    [~, thresh_temp] = max(distToRamp);
                    
                    if  ~isempty(thresh_temp)
                        thresh(1,i) = thresh_temp+index-1;
                    else
                        thresh(1,i) = 0;
                    end
                end
            end  
            thresh = thresh(this.maskForChannels);
        end
        
    end
    
end