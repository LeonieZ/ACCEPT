function [coordinates]=pixelsToCoordinates(pixelCoordinates, imgNr, cols, camXSize, camYSize)
row = ceil(imgNr/cols) - 1;
switch row
    case {1,3,5} 
        col=(cols-(imgNr-row*cols));
        coordinates(1)=pixelCoordinates(1)+camXSize*col;
        coordinates(2)=pixelCoordinates(2)+camYSize*row;  
    otherwise
        col=imgNr-1-row*cols;
        coordinates(1)=pixelCoordinates(1)+camXSize*col;
        coordinates(2)=pixelCoordinates(2)+camYSize*row; 
end

end