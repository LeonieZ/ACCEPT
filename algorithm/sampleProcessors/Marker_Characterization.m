%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 
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
            inputSample.results.sampleProcessorUsed = this.name;
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
                notNec = find(inputSample.results.features.ch_3_Size==0);
                inputSample.results.features(notNec,:) = [];
                inputSample.results.thumbnails(notNec,:) = [];
                inputSample.results.segmentation(:,notNec) = [];      
            end
            
            this.dataframeProcessor =[];
            this.pipeline = cell(0);
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