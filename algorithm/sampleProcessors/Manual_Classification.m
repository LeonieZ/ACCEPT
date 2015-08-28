classdef Manual_Classification < SampleProcessor
    %Manual_Classification SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
    
    %NOTE:change segmentation to AC lateron.
    
    properties
    end
    
    methods 
        function this = Manual_Classification()
            this.name = 'Manual Classification';
            this.version = '0.1';
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