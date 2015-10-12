classdef ACCEPT_Classification_latest_version < SampleProcessor
    %ACCEPT_Classification_latest_version SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
    
    %NOTE:change segmentation to AC lateron.
    
    properties
    end
    
    methods 
        function this = ACCEPT_Classification_latest_version()
            this.name='ACCEPT Classification [latest_version]';
            this.version='0.1';
            this.io = IO();
            this.dataframeProcessor = DataframeProcessor('', this.make_dataframe_pipeline(),'0.1');
            this.pipeline = this.make_sample_pipeline();
        end
        
        function pipeline = make_sample_pipeline(this)
            pipeline = cell(0);   
        end
    end
    
    methods (Static)    
        function pipeline = make_dataframe_pipeline()
            pipeline = cell(0);
        end     
    end
    
end