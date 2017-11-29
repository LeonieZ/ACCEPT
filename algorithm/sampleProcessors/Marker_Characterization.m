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
    % CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, segments using active contour
    % and extracts features for every cell. No classification!
    % Note that events that have no CK signal are removed if another event
    % with CK is found in that thumbnail!
        
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
            %create DataframeProcessor
            this.dataframeProcessor = DataframeProcessor('Thumbnail_Analysis', this.make_dataframe_pipeline(),'0.1');
            %create sample pipeline
            this.pipeline = this.make_sample_pipeline();
            %run overview loading
            this.pipeline{1}.run(inputSample);
            %create segmentation object
            ac = ActiveContourSegmentation({'adaptive',0.001,0.005}, 200, 1,{'triangle','global', inputSample.histogram});
            ac.clear_border = 1;
            this.dataframeProcessor.pipeline{1} = ac;
            
            %start processing
            for i = 2:numel(this.pipeline)
                this.pipeline{i}.run(inputSample);
            end  
            
            if ~isempty(inputSample.results.features) %&& ~strcmp(inputSample.type,'ThumbnailLoader')
                %check if thumbs are listed double
                thumbsQuantity = hist(inputSample.results.features{:,1},linspace(1,size(inputSample.priorLocations,1),size(inputSample.priorLocations,1)));
                multiThumbs = find(thumbsQuantity>1)';
                multiThumbs_loc = ismember(inputSample.results.features.ThumbNr,multiThumbs);
                %check which events have no CK signal
                noCK = inputSample.results.features.ch_3_Size==0;
                %if double listed, event without CK signal can be removed
                notNec = noCK & multiThumbs_loc;
                %make sure so thumb is removed completely
                thumbsQuantity_new = hist(inputSample.results.features.ThumbNr(~notNec),linspace(1,size(inputSample.priorLocations,1),size(inputSample.priorLocations,1)));
                removedCompl = find(thumbsQuantity_new == 0 & thumbsQuantity ~= 0);
                if ~isempty(removedCompl)
                    remain = ismember(inputSample.results.features.ThumbNr,removedCompl);
                    notNec(remain) = 0;
                end
                %delete events not needed
                inputSample.results.features(notNec,:) = [];
                inputSample.results.thumbnails(notNec,:) = [];
                inputSample.results.segmentation(:,notNec) = [];      
            end
            %clear pipeline
            this.dataframeProcessor =[];
            this.pipeline = cell(0);
        end
        
        function pipeline = make_sample_pipeline(this)
            %create sample pipeline
            pipeline = cell(0);
            %loading of overview image
            sol = SampleOverviewLoading();
            %extracting of features
            fc = FeatureCollection(this.dataframeProcessor,1);
            pipeline{1} = sol;
            pipeline{2} = fc;
        end
    end
    
    methods (Static)    
        function pipeline = make_dataframe_pipeline()
            %create pipeline for frame processing
            pipeline = cell(0);
            ef = ExtractFeatures();
            pipeline{1} = [];
            pipeline{2} = ef;
        end     
    end
    
end