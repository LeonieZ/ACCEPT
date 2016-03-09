classdef MaskDetermination < SampleProcessorObject
    %DETERMINE_MASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channelEdgeRemoval = []
    end
    
    methods
        function this = DetermineMask(varargin)
            if nargin > 0
                this.channelEdgeRemoval = varargin{1};
            end
        end
        
        function returnSample = run(this,inputSample)
                returnSample = inputSample;
%                 mask_small = false(size(inputSample.overviewImage));
                se = strel('disk',50);
                
                if isempty(this.channelEdgeRemoval)
                    this.channelEdgeRemoval = inputSample.channelEdgeRemoval;
                end
                
                openImg = imopen(inputSample.overviewImage(:,:,this.channelEdgeRemoval),se);
                mask_small = regiongrowing(double(openImg)/max(double(openImg(:))), 0.1, [round(size(openImg,1)/2),round(size(openImg,2)/2)]);
                returnSample.mask = bwmorph(~mask_small,'open');
                
        end
    end
    
end
