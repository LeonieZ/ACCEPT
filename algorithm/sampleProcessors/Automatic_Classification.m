classdef Automatic_Classification < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties

    end
    
    methods 
        function this = Automatic_Classification()
            this.name = 'Automatic Classification';
        end
    end
end