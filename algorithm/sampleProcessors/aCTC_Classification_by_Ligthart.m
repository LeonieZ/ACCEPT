classdef aCTC_Classification_by_Ligthart < SampleProcessor
    %aCTC_Classification_by_Ligthart SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
    
    %NOTE:change segmentation to AC lateron.
    
    properties
        name='aCTC_Classification_by_Ligthart'
        version='0.1'
        dataframeProcessor 
        pipeline = cell(0)
        io = IO();
    end
    
    methods 
        function this = aCTC_Classification_by_Ligthart()
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