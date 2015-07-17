classdef determine_mask < workflow_object
    %DETERMINE_MASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mask = []
    end
    
    methods
        function self = determine_mask(dataFrame)
            %necessary or is thresholding enough?
            tmp = activecontour_segmentation(dataFrame, 10000, 50, 1, [], [], dataFrame.sample.channelEdgeRemoval).segmentedFrame;
            se = strel('disk',50);
            self.mask = imopen(tmp,se);
            % too large or small?
            self.mask = bwmorph(self.mask,'thicken',25);
        end
    end
    
end

