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
clear all; close all;
coords = ...
[ 25  45   40
  20  45   100
  15  100   40
  10  100   100];

% coords = ...
% [ 25  35   30
%   20  35   85
%   15  80   30
%   10  80   85];

IM2 = zeros(130,130);

for k = 1:4
    for i = 1:size(IM2,1)
        for j = 1:size(IM2,2)
            r = coords(k,1);
            x = coords(k,2);
            y = coords(k,3);
            R = sqrt((i-x).^2+(j-y).^2);
            if R < r
                IM2(i,j) = 1;
            end
        end
    end
end 

% imagesc(IM); axis image;
IM  = imresize(IM2,1);