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
%where in a cartridige are the scored events:
%first open a processed sample
%then display the opened 
[file,dir]=uigetfile('*.mat','Please select a ACCEPT cartridge result');
load(fullfile(dir,file));

thumbContainer = ThumbContainer(currentSample);

locations=[];
for i=1:size(currentSample.priorLocations,1)
    locations(i,:)=IO.calculate_overview_location(currentSample,i);
end
figure
imshow(thumbContainer.overviewImage(:,:,2),parula(4000))
hold on
if ~isempty(locations)
    scatter(locations(:,2),locations(:,1),'red')
end
hold off