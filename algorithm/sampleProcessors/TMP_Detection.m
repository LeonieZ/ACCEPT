classdef TMP_Detection < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties
    end
    
    methods 
        function this = TMP_Detection()
            this.name = 'TMP Detection';
            this.version = '0.1';
            this.io = IO();  
            this.dataframeProcessor = DataframeProcessor('FullImage_Detection', this.make_dataframe_pipeline(),'0.1');
            this.pipeline = this.make_sample_pipeline();
        end
        
        function run(this,inputSample)
            this.pipeline{1}.run(inputSample);
            this.pipeline{2}.run(inputSample);
%             ac = ActiveContourSegmentation(0.1, 50, 1,{'triangle','global', inputSample.histogram_down},[],3);
            ac = ActiveContourSegmentation('adaptive', 50, 1,{'triangle','global', inputSample.histogram_down},[],3);
            ac.clear_border = 1;
%             this.dataframeProcessor.pipeline{1} = ac;
%             ts = ThresholdingSegmentation('triangle','global', inputSample.histogram, [ 3 3 3 3]);
%             ts = ThresholdingSegmentation('triangle','global', inputSample.histogram);
%             this.dataframeProcessor.pipeline{1} = ts;
            this.dataframeProcessor.pipeline{1} = ac;
            for i = 3:numel(this.pipeline)
                this.pipeline{i}.run(inputSample);
            end  
            
            this.io.save_results_as_xls(inputSample);
        end
        
        function pipeline = make_sample_pipeline(this)
            pipeline = cell(0);
            sol = SampleOverviewLoading();
            md = MaskDetermination();
            fc = FeatureCollection(this.dataframeProcessor,this.io);
            pipeline{1} = sol;
            pipeline{2} = md;
            pipeline{3} = fc;
        end
    end
    
    methods (Static)    
        function pipeline = make_dataframe_pipeline()
            pipeline = cell(0);
            ef = ExtractFeatures();      
%             dm = DetermineMask();
%             pipeline{1} = dm;
            pipeline{1} = [];
            pipeline{2} = ef;
        end     
    end
    
end