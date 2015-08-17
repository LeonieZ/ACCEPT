classdef DetermineMask < workflow_object
    %DETERMINE_MASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mask = []
    end
    
    methods
        function this = determine_mask(dataFrame)
            this.mask = false(size(dataFrame.rawImage,1),size(dataFrame.rawImage,2));
            se = strel('disk',50);
            frame = imopen(dataFrame.rawImage(:,:,dataFrame.sample.channelEdgeRemoval),se);
            
            %necessary or is thresholding enough?
            tmp = activecontour_segmentation(dataFrame, 10000, 50, 1, [], [], [], frame).segmentedFrame;
            [r,c] = find(tmp == 1);
            
            % adapt for corner images;
            this.mask(min(r):max(r),min(c):max(c)) = true;
            this.mask = bwmorph(this.mask,'thicken',100);
        end
    end
    
end

