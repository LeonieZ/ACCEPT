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
classdef CTC_Scoring < SampleProcessor
    %CTC_Marker_Characterization SampleProcessor for the Feature Collection use case.
    % Acts on preselected thumbnails, does segmentation (otsu thresholding)
    % an extracts features for every cell. No classification!
        
    properties
    end
    
    methods 
        function this = CTC_Scoring()
            this.name = 'CTC Scoring';
            this.version = '0.1';
            this.showInList = false;
        end
    end
end