classdef Marker_Characterization_priorThumbs < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties
    end
    
    methods 
        function this = Marker_Characterization_priorThumbs()
            this.name = 'Marker Characterization priorThumbs';
            this.version = '0.1';
            this.io = IO();  
            this.dataframeProcessor =[];
            this.pipeline = cell(0);
        end
        
        function run(this,inputSample)
            this.dataframeProcessor = DataframeProcessor('Thumbnail_Analysis', this.make_dataframe_pipeline(),'0.1');
            this.pipeline = this.make_sample_pipeline();
            this.pipeline{1}.run(inputSample); 
            
%             if ~isempty(inputSample.results.features)
%                 inputSample.results.features(find(inputSample.results.features.ch_3_Area==0),:) = [];
%                 notNec = find(~ismember(linspace(1,size(inputSample.priorLocations,1),size(inputSample.priorLocations,1)),inputSample.results.features{:,1}));
%                 for i = 1:size(notNec,2)
%                     inputSample.results.thumbnail_images{1,notNec(i)} = [];
%                     inputSample.results.segmentation{1,notNec(i)} = [];
%                 end
%             end
            this.io.save_results_as_xls(inputSample);
            this.dataframeProcessor =[];
            this.pipeline = cell(0);
%             this.io.save_thumbnail(inputSample,[],'prior');
%             this.io.save_thumbnail(inputSample);
        end
        
        function pipeline = make_sample_pipeline(this)
            pipeline = cell(0);
            fc = FeatureCollection(this.dataframeProcessor,this.io,0);
            pipeline{1} = fc;
        end
    end
    
    methods (Static)    
        function pipeline = make_dataframe_pipeline()
            pipeline = cell(0);
            ef = ExtractFeatures();
            pipeline{1} = ef;
        end     
    end
    
end