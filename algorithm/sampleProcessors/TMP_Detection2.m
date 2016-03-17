classdef TMP_Detection2 < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties
    end
    
    methods 
        function this = TMP_Detection2()
            this.name = 'TMP Detection2';
            this.version = '0.1';
            this.io = IO();  
            this.dataframeProcessor = DataframeProcessor('FullImage_Detection', this.make_dataframe_pipeline(),'0.1');
            this.pipeline = this.make_sample_pipeline();
        end
        
        function run(this,inputSample)
            this.pipeline{1}.run(inputSample);
            this.pipeline{2}.run(inputSample);
%             ac = ActiveContourSegmentation('adaptive', 100, 1,{'triangle','global', inputSample.histogram});
            ac = ActiveContourSegmentation('adaptive', 100, 1,{'triangle','global', inputSample.histogram_down});
            ac.clear_border = 1;
%             ts = ThresholdingSegmentation('triangle','global', inputSample.histogram, 3,10);
            ts = ThresholdingSegmentation('triangle','global', inputSample.histogram_down, 3);
            this.dataframeProcessor.pipeline{1} = ts;
            this.pipeline{3}.run(inputSample);
            inputSample.priorLocations = inputSample.results.thumbnails;
            inputSample.results = Result();
            this.dataframeProcessor.pipeline{1} = ac;
            fc = FeatureCollection(this.dataframeProcessor,this.io,1);
            this.pipeline{3} = fc;
            this.pipeline{3}.run(inputSample); 
            if ~isempty(inputSample.results.features)
                inputSample.results.thumbnail_images(find(inputSample.results.features.ch_3_Area==0),:) = [];
                inputSample.results.thumbnails(find(inputSample.results.features.ch_3_Area==0),:) = [];
                inputSample.results.segmentation(find(inputSample.results.features.ch_3_Area==0),:) = [];
                inputSample.results.features(find(inputSample.results.features.ch_3_Area==0),:) = [];
            end
            this.io.save_results_as_xls(inputSample);
        end
        
        function pipeline = make_sample_pipeline(this)
            pipeline = cell(0);
            sol = SampleOverviewLoading();
            md = MaskDetermination([],0.1);
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
            pipeline{1} = [];
            pipeline{2} = ef;
        end     
    end
    
end