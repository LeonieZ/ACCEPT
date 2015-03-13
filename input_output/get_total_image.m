function [TotalCartridgeImage Error_out] = get_total_image(dataP, algP)
% function to get scan area of cartridge

TifCount = numel(dataP.temp.imageFileNames);
Error_out = 'Border ok';

SubSampleFactor = 1;
BorderImageToCheck = [];

% verify what kind of scan we are dealing with, based on tiff count
switch TifCount
    case 210 % 6*35 images
        ColsRowsScan = [35 6];
        BorderImageToCheck = [1:36 70 71 105 106 140 141 175:210];
    case 180 % 5*36 images
        ColsRowsScan = [36 5];
        BorderImageToCheck = [1:37 72 73 108 109 144 145:180];
    case 175 % 5*35 images
        ColsRowsScan = [35 5];
        BorderImageToCheck = [1:36 70 71 105 106 140 141:175];
    case 170 % 5*34 images
        ColsRowsScan = [34 5];
        BorderImageToCheck = [1:35 68 69 102 103 136:170];
    case 144 % 4*36 images
        ColsRowsScan = [36 4];
        BorderImageToCheck = [1:37 72 73 108 109:144];
    case 140 % 4*35 images
        ColsRowsScan = [35 4];
        BorderImageToCheck = [1:36 70 71 105 106:140];
end

% if no known number of images is found, return error
if isempty(BorderImageToCheck)
    MaskAreaToScan_out = [];
    Error_out = 'Number of images in directory not normal!';
    return
end

% read first test image for determining orientation cartridge. Choose image
% 15, because it will be more or less in the middle of the cartridge
% FileNameTestOrientation = [ImageDir_in filesep TifFiles(TifCount-15).name];

[ImageScaled, ErrorTiff] = readImAndScale(dataP,15,dataP.channelEdgeremoval);

if strcmp(ErrorTiff, 'Tiff is not an IMMC tiff!')
    Error_out = ErrorTiff;
    MaskAreaToScan_out = [];
    return
elseif strcmp(ErrorTiff, ['First tiff from channel ' num2str(dataP.channelEdgeremoval) ' is not readable!'])
    Error_out = ErrorTiff;
    MaskAreaToScan_out = [];
    return
elseif strcmp(ErrorTiff, ['Tiff from channel ' num2str(dataP.channelEdgeremoval) ' is not readable!'])
    Error_out = ErrorTiff;
    MaskAreaToScan_out = [];
    return
end

% create subsampled version of image, to save memory
% BorderImage = subsample(squeeze(ImageScaled), SubSampleFactor);
BorderImage = imresize(mat2gray(ImageScaled),1/SubSampleFactor);

% check image in the middle of first row of cartridge. If upper two rows are darker than
% botoom two rows, scan began on last row (lighter part is border)
[XLength, YLength] = size(BorderImage);
% MeanTopTwoRows = mean(BorderImage(:, 0:2));
% MeanBottomTwoRows = mean(BorderImage(:, end-2:end));
MeanTopTwoRows = mean2(BorderImage(1:3,:));
MeanBottomTwoRows = mean2(BorderImage(end-2:end,:));
% determine directions that cartridge was recorded
if MeanTopTwoRows > MeanBottomTwoRows
    Directionx = 1;
    Directiony = 1;
    CurrentCol = 1;
    CurrentRow = 1;
else
    Directionx = -1;
    Directiony = -1;
    CurrentCol = ColsRowsScan(2);
    CurrentRow = ColsRowsScan(1);
end


% We are preallocating here but i dont know if the data types are correct \G
% now length and width of image is known, create big image and output image
TotalCartridgeImage = zeros(XLength*ColsRowsScan(2), YLength*ColsRowsScan(1),'uint16');
MaskAreaToScan_out = zeros(XLength, YLength, TifCount,'uint8');


% create total cartridge image by inserting the images from the cartridge
% piece by piece, subsample 
for ii = 1:TifCount
    
    % read image and stretch values
    [ImageScaled ErrorTiff] = readImAndScale(dataP,ii,dataP.channelEdgeremoval);
    if strcmp(ErrorTiff, 'Tiff is not an IMMC tiff!')
        Error_out = ErrorTiff;
        MaskAreaToScan_out = [];
        return
    elseif strcmp(ErrorTiff, ['Tiff from channel ' num2str(dataP.channelEdgeremoval) ' is not readable!'])
        Error_out =  ErrorTiff;
        MaskAreaToScan_out = [];
        return
    end
    
    if dataP.scaleData == true
        scale = 4095;
    else
        scale = 255;
    end
%    ImageScaled = ImageScaled/scale;
    
    % subsample image by a factor to keep things workable
    BorderImage = imresize(ImageScaled, 1/SubSampleFactor);

    TotalCartridgeImage((CurrentCol-1)*XLength+1:CurrentCol*XLength,(CurrentRow-1)*YLength+1:CurrentRow*YLength) = BorderImage;

    
    % if iteration is the number of colums, switch direction
    if rem(ii, ColsRowsScan(1)) == 0
        Directiony = -Directiony;
        CurrentCol = CurrentCol + Directionx;
    else
        CurrentRow = CurrentRow + Directiony;
    end
end