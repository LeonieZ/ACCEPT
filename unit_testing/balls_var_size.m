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