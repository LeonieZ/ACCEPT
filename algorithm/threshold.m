classdef threshold < workflow_object
    %THRESHOLD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        thresholds = [];
        maskForChannels = [];
        histogram = [];
        meth = [];
        range = [];
    end
    
    methods
        function self = threshold(meth, range, currentFrame, varargin)
            %varargin(1) = masksforchannels, varargin(2) = offsets varargin(3) =
            %thresholds of manual ones
            
            self.meth = meth;
            self.range = range;
            
            if nargin > 3
                self.maskForChannels = varargin{1};
            else
                self.maskForChannels = 1:1:size(currentFrame.rawImage,3);
            end
            
            if strcmp(range,'global')
                self.histogram = create_global_hist(self,currentFrame);
            elseif strcmp(range,'local')
                self.histogram = create_local_hist(self,currentFrame);
            else
                error('Thresholding range unknown.')
            end
            
            if strcmp(meth,'otsu')
                self.thresholds = otsu_method(self);
            elseif strcmp(meth,'triangle')
                self.thresholds = triangle_method(self);
            elseif strcmp(meth,'manual')
                self.thresholds = varargin{3};
            else
                error('Segmentation method unknown.')
            end
            
            if nargin > 4 && ~isempty(varargin{2})                
                self.thresholds = self.thresholds + varargin{2};
            end
        end
        
        function hist = create_global_hist(self, frame)
            
            sample = frame.sample;
            nrFrames = sample.numberOfFrames;
            nrChannels = sample.numChannels;
            if strcmp(sample.dataTypeOriginalImage,'uint8')
                bins = 255;
            elseif strcmp(sample.dataTypeOriginalImage,'uint16')
                bins = 4095;
            end
            hist = zeros(1,bins,nrChannels);

            for j = 1:nrChannels
                if any(self.maskForChannels == j)
                    for i = 1:nrFrames                    
%                         currentFrame = read...
                        imTemp = currentFrame.rawImage(:,:,j);
                            
                        if currentFrame.frameHasEdge
                            imTemp = imTemp(currentFrame.mask);
                        end

                        if max(imTemp) > 32767
                                imTemp = imTemp - 32768;
                        end
                        
                        hist_temp = histc(imTemp(:),1:1:bins)';
                        if ~isempty(hist_temp)
                            hist(:,:,j) = hist(:,:,j) + hist_temp;
                        end

                    end
                end
            end
        end
        
        function hist = create_local_hist(self, currentFrame)
            nrChannels = size(currentFrame.rawImage,3);
            if strcmp(currentFrame.sample.dataTypeOriginalImage,'uint8')
                bins = 255;
            elseif strcmp(currentFrame.sample.dataTypeOriginalImage,'uint16')
                bins = 4095;
            end
            hist = zeros(1,bins,nrChannels);
            for j = 1:nrChannels
                if any(self.maskForChannels == j)
                    imTemp = currentFrame.rawImage(:,:,j);
                    
                    if currentFrame.frameHasEdge
                        imTemp = imTemp(currentFrame.mask);
                    end
            
                    if max(imTemp) > 32767
                            imTemp = imTemp - 32768;
                    end
                    
                    hist(:,:,j) = histc(imTemp(:),1:1:bins)';
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

                    thresh(1,i) = thresh_temp+index-1;
                end
            end  
            thresh = thresh(self.maskForChannels);
        end
        
    end
end