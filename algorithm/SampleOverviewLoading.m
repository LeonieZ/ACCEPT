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
classdef SampleOverviewLoading < SampleProcessorObject
    %SAMPLEOVERVIEWLOADING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        reductionFactor = 1/8;
    end
    
    methods
        function this = SampleOverviewLoading(reductionFactor)
            if nargin == 1
                this.reductionFactor = reductionFactor;
            end    
        end
        
        function returnSample = run(this, inputSample)
            returnSample = inputSample;
            
            if isempty(returnSample.overviewImage)                    
                loader = inputSample.loader(inputSample);
                if ~isa(loader,'ThumbnailLoader')
                    returnSample.histogram = zeros(65535,inputSample.imageSize(3));
                    returnSample.histogram_down = zeros(65535,inputSample.imageSize(3));
                    frameOrder = loader.calculate_frame_nr_order;
                    reducedSize = [ceil(inputSample.imageSize(1)*this.reductionFactor(1)),inputSample.imageSize(2)*this.reductionFactor(1),inputSample.imageSize(3)];
                    reducedSize = ceil(reducedSize);
                    inputSample.overviewImage = zeros(reducedSize(1)*inputSample.rows,reducedSize(2)*inputSample.columns,reducedSize(3),'uint16');

                    % parallelize with parfor
                    [I,J] = ind2sub([inputSample.rows,inputSample.columns],1:inputSample.rows*inputSample.columns);
                    tempImage = cell(1,inputSample.rows*inputSample.columns);
                    offset = cell(1,inputSample.rows*inputSample.columns);
                    histc1 = cell(1,inputSample.rows*inputSample.columns);
                    histc2 = cell(1,inputSample.rows*inputSample.columns);
                    parfor k=1:inputSample.rows*inputSample.columns
                        i=I(k);
                        j=J(k);                    
                        frame = loader.load_data_frame(frameOrder(i,j)); %costly
                        tempImage{k} = imresize(frame.rawImage,this.reductionFactor);                    
                        offset{k} = [reducedSize(1)*(i-1)+1,reducedSize(2)*(j-1)+1];                                        
                        histc1{k} = histc(reshape(frame.rawImage,numel(frame.rawImage)/frame.nrChannels,frame.nrChannels),1:1:65535); %costly
                        histc2{k} = histc(reshape(tempImage{k},numel(tempImage{k})/frame.nrChannels,frame.nrChannels),1:1:65535); %costly
                    end
                    for k=1:inputSample.rows*inputSample.columns
                        inputSample.overviewImage(offset{k}(1):offset{k}(1)+reducedSize(1)-1,offset{k}(2):offset{k}(2)+reducedSize(2)-1,:) = tempImage{k};
                        inputSample.histogram      = inputSample.histogram      + histc1{k};                    
                        inputSample.histogram_down = inputSample.histogram_down + histc2{k};

                    end
                end
            end
        end
    end
end
