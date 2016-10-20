classdef CTC_Scoring < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties
    end
    
    methods 
        function this = CTC_Scoring(io)
            this.name = 'CTC Scoring';
            this.version = '0.1';
            this.io = io; 
        end
    end
end