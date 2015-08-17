classdef threshold < workflow_object
    %THRESHOLD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        thresholds = [];
        maskForChannels = [];
        histogram = [];
        meth = [];
        range = [];
        dataType = '';
        offset=0;
    end
    
    methods
        function self = threshold(meth, range, currentSample)
            %varargin(1) = masksforchannels, varargin(2) = offsets varargin(3) =
            %thresholds of manual ones
            
            validatestring(meth,{'otsu','triangle','manual'});
            self.meth = meth;
            
            validatestring(range,{'global','local'});
            self.range = range;
            
            self.maskForChannels=1:1:currentSample.numChannels;
            self.dataType = currentSample.dataTypeOriginalImage;
            
            if strcmp(currentSample.dataTypeOriginalImage,'uint8')
                bins = 255;
            elseif strcmp(currentSample.dataTypeOriginalImage,'uint16')
                bins = 65535;
            end
            self.hist = zeros(1,bins,currentSample.nrChannels);
            
        end
        
        function returnFrame=run(self,inputFrame)

            %create histogram if thresholding is local otherwise we assume
            %this was already done.
            if strcmp(self.range,'local') && ~strcmp(self.meth,'manual')
                self.histogram = self.create_local_hist(inputFrame);
            end
            if isempty(self.thresholds)
                self.calculate_thresholds()
            end
            
            %Here we will have to do the segmentation. 
            
        
        end
        
        function calculate_threshold(self)
            switch self.meth
                case 'otsu'
                    self.thresholds = self.otsu_method() + self.offset;
                case 'triangle'
                    self.thresholds = self.triangle_method() + self.offset;
                case 'manual'
                    if isempty(self.thresholds)
                        error('please specify the threshold')
                    end
            end
        end
        
        function create_hist(self, inputFrame)
            for j = 1:nrChannels
                if any(self.maskForChannels == j)                
                        imTemp = inputFrame.rawImage(:,:,j);
                          
                        if inputFrame.frameHasEdge
                            imTemp = imTemp(~inputFrame.mask);
                        end
                        hist_temp = histc(imTemp(:),1:1:numel(self.hist))';
                        switch self.range
                            case 'local'                                '
                                self.hist(:,:,j)= hist_temp;
                            case 'global'
                                if ~isempty(hist_temp)
                                    self.hist(:,:,j) = self.hist(:,:,j) + hist_temp;
                                end
                        end
                end
            end
        end
            
        
        function thresh = otsu_method(self)
            % Function carried over from Matlab function graythresh.
            hist = self.histogram;
            thresh = zeros(1,size(hist,3));
            
            for i = 1:size(hist,3)
                if any(self.maskForChannels == i)
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
            thresh = thresh(self.maskForChannels);
        end
        
        function thresh = triangle_method(self)
            % Function carried over from old ACTC script by Sjoerd.
            % adapted it a bit  - need to test if it works correctly!
            hist = self.histogram;
            thresh = zeros(1,size(hist,3));
            num_bins = size(hist(:,:,1),2);
            
            for i = 1:size(hist,3)
                if any(self.maskForChannels == i)
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
            thresh = thresh(self.maskForChannels);
        end
        
    end
end