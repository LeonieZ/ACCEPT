classdef CTC_Marker_Characterization < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
    
    %NOTE:change segmentation to AC lateron.
    
    properties
    end
    
    methods 
        function this = CTC_Marker_Characterization()
            this.name = 'CTC Marker Characterization';
            this.version = '0.1';
            this.io = IO();  
            this.dataframeProcessor = DataframeProcessor('Thumbnail_Analysis', this.make_dataframe_pipeline(),'0.1');
            this.pipeline = this.make_sample_pipeline();
        end
        
        function pipeline = make_sample_pipeline(this)
            pipeline = cell(0);
            fc = FeatureCollection(this.dataframeProcessor,this.io,1);
            pipeline{1} = fc;
        end
    end
    
    methods (Static)    
        function pipeline = make_dataframe_pipeline()
            pipeline = cell(0);
            ts = ThresholdingSegmentation('otsu','local');
            ef = ExtractFeatures();
            pipeline{1} = ts;
            pipeline{2} = ef;
        end     
    end
    
end