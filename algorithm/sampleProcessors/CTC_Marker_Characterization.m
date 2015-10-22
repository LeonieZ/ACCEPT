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
        
        function run(this,inputSample)
            this.pipeline{1}.run(inputSample);
            lambda = 0.5*sum(inputSample.histogram(:,:).*repmat((1:size(inputSample.histogram,1))',[1 size(inputSample.histogram,2)]),1)./sum(inputSample.histogram(:,:),1);
            ac = ActiveContourSegmentation(lambda, 100, 1,{'triangle','global', inputSample.histogram});
            this.dataframeProcessor.pipeline{1} = ac;
 
            for i = 2:numel(this.pipeline)
                this.pipeline{i}.run(inputSample);
            end  
            
            if ~isempty(inputSample.results.features)
                inputSample.results.features(find(inputSample.results.features.ch_3_Area==0),:) = [];
            end
            this.io.save_results_as_xls(inputSample);
        end
        
        function pipeline = make_sample_pipeline(this)
            pipeline = cell(0);
            sol = SampleOverviewLoading();
            fc = FeatureCollection(this.dataframeProcessor,this.io,1);
            pipeline{1} = sol;
            pipeline{2} = fc;
        end
    end
    
    methods (Static)    
        function pipeline = make_dataframe_pipeline()
            pipeline = cell(0);
%             
%             ts = ThresholdingSegmentation('otsu','local');
            ef = ExtractFeatures();
%             pipeline{1} = ts;
            pipeline{1} = [];
            pipeline{2} = ef;
        end     
    end
    
end