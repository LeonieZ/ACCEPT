classdef Automatic_Classification < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties
        
    end
    
    methods 
        function this = Automatic_Classification()
            this.name = 'Automatic Classification';
            this.showInList = false;
        end
    end
end