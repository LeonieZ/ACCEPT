classdef Marker_Characterization < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties
    end
    
    methods 
        function this = Marker_Characterization()
            this.name = 'Marker Characterization';
            this.version = '0.1';  
            this.dataframeProcessor =[];
            this.pipeline = cell(0);
        end
        
        function run(this,inputSample)
            this.dataframeProcessor = DataframeProcessor('Thumbnail_Analysis', this.make_dataframe_pipeline(),'0.1');
            this.pipeline = this.make_sample_pipeline();
            this.pipeline{1}.run(inputSample);
            ac = ActiveContourSegmentation({'adaptive',0.001,0.005}, 200, 1,{'triangle','global', inputSample.histogram});
            ac.clear_border = 1;
            this.dataframeProcessor.pipeline{1} = ac;
 
            for i = 2:numel(this.pipeline)
                this.pipeline{i}.run(inputSample);
            end  
            
            if ~isempty(inputSample.results.features)
                inputSample.results.features(find(inputSample.results.features.ch_3_Size==0),:) = [];
                notNec = find(~ismember(linspace(1,size(inputSample.priorLocations,1),size(inputSample.priorLocations,1)),inputSample.results.features{:,1}));
                for i = 1:size(notNec,2)
                    inputSample.results.thumbnail_images{1,notNec(i)} = [];
                    inputSample.results.segmentation{1,notNec(i)} = [];
                end
            end
            IO.save_results_as_xls(inputSample);
            this.dataframeProcessor =[];
            this.pipeline = cell(0);
%             IO.save_thumbnail(inputSample,[],'prior');
            IO.save_thumbnail(inputSample);
        end
        
        function pipeline = make_sample_pipeline(this)
            pipeline = cell(0);
            sol = SampleOverviewLoading();
            fc = FeatureCollection(this.dataframeProcessor,1);
            pipeline{1} = sol;
            pipeline{2} = fc;
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