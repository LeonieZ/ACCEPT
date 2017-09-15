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
classdef Candidate_Selection < SampleProcessor
    % Candidate Selection SampleProcessor. Does the same as the Full
    % Detection Processor with a gating afterwards. Detects all objects by
    % Active Contour, extracts features and applies a specified line gate
    % combination. 
        
    properties
    end
    
    methods 
        function this = Candidate_Selection()
            this.name = 'Candidate Selection';
            this.version = '0.1';
            this.dataframeProcessor = DataframeProcessor('FullImage_Detection', this.make_dataframe_pipeline(),'0.1');
            this.pipeline = this.make_sample_pipeline();
        end
        
        function run(this,inputSample)            
            this.pipeline{1}.run(inputSample);
            this.pipeline{2}.run(inputSample);
            lambda          = 0.01;
            inner_it        = 200;
            breg_it         = 1;
            init            = {'triangle','global', inputSample.histogram_down};
            maskForChannels = [];
            single_ch       = []; %3;
            use_openMP      = true;
            ac = ActiveContourSegmentation(lambda,inner_it,breg_it,init,...
                                           maskForChannels,single_ch,use_openMP);
            ac.clear_border = 1;
            this.dataframeProcessor.pipeline{1} = ac;
            for i = 3:numel(this.pipeline)
                this.pipeline{i}.run(inputSample);
            end  
            IO.save_thumbnail(inputSample,[],[],[],1);
        end
        
        function pipeline = make_sample_pipeline(this)
            pipeline = cell(0);
           
            sol = SampleOverviewLoading();
            md = MaskDetermination();
            fc = FeatureCollection(this.dataframeProcessor);    
            mc = ManualClassification(cell(0),'ManualGates');
            
            pipeline{1} = sol;
            pipeline{2} = md;
            pipeline{3} = fc;
            pipeline{4} = mc;
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