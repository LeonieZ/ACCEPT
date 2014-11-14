function [MaskAreaToScan_out Error_out] = GetScanArea(ImageDir_in, dataP, algP)
% function to get scan area of cartridge

TifFiles = dir([ImageDir_in filesep '*.tif']);
TifCount = length(TifFiles);
Error_out = 'Border ok';

% assign values to constants
SubSampleFactor = dataP.samplefactor;
ChannelForSegmentation = dataP.channelEdgeremoval;
% KernelSizeGradMag = 8;
% KernelSizeLine = 100;
% MinCartridgeSize = 2500000;
% MaxCartridgeSize = 3200000;

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
FileNameTestOrientation = [ImageDir_in filesep TifFiles(15).name];
[ImageScaled, ErrorTiff] = ReadImmcTiffAndScale(FileNameTestOrientation, ChannelForSegmentation, dataP, algP);

if strcmp(ErrorTiff, 'Tiff is not an IMMC tiff!')
    Error_out = ErrorTiff;
    MaskAreaToScan_out = [];
    return
elseif strcmp(ErrorTiff, ['First tiff from channel ' num2str(ChannelForSegmentation) ' is not readable!'])
    Error_out = ErrorTiff;
    MaskAreaToScan_out = [];
    return
elseif strcmp(ErrorTiff, ['Tiff from channel ' num2str(ChannelForSegmentation) ' is not readable!'])
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

% now length and width of image is known, create big image and output image
% TotalCartridgeImage = newim(XLength*ColsRowsScan(1), YLength*ColsRowsScan(2));
% MaskAreaToScan_out = newim(XLength, YLength, TifCount);
% TotalCartridgeImage = zeros(XLength*ColsRowsScan(1), YLength*ColsRowsScan(2));
% MaskAreaToScan_out = zeros(XLength, YLength, TifCount);
TotalCartridgeImage = zeros(XLength*ColsRowsScan(2), YLength*ColsRowsScan(1));
% [X, Y] = size(TotalCartridgeImage)
MaskAreaToScan_out = zeros(XLength, YLength, TifCount);

% Create kernels for convolution with horizontal or vertical stripe, to
% improve borders at certain orientations. Kernel is divided by its size:
% we don't want to add any intensity
% KernelX = 0*BorderImage;
% KernelY = 0*BorderImage;
% KernelX(round(size(KernelX,1)/2)-KernelSizeLine/2:round(size(KernelX,1)/2)+KernelSizeLine/2, round(size(KernelX,2)/2)) = 1/(KernelSizeLine+1);
% KernelY(round(size(KernelY,1)/2), round(size(KernelY,2)/2)-KernelSizeLine/2:round(size(KernelY,2)/2)+KernelSizeLine/2) = 1/(KernelSizeLine+1);

% create total cartridge image by inserting the images from the cartridge
% piece by piece, subsample 
for ii = 1:TifCount
    
    % read image and stretch values
    FileName = [ImageDir_in filesep TifFiles(ii).name];
    [ImageScaled ErrorTiff] = ReadImmcTiffAndScale(FileName, ChannelForSegmentation, dataP, algP);
    if strcmp(ErrorTiff, 'Tiff is not an IMMC tiff!')
        Error_out = ErrorTiff;
        MaskAreaToScan_out = [];
        return
    elseif strcmp(ErrorTiff, ['Tiff from channel ' num2str(ChannelForSegmentation) ' is not readable!'])
        Error_out =  ErrorTiff;
        MaskAreaToScan_out = [];
        return
    end
    
    if dataP.scaleData == true
        scale = 4095;
    else
        scale = 255;
    end
    ImageScaled = ImageScaled/scale;
    
    % subsample image by a factor to keep things workable
    BorderImage = imresize(ImageScaled, 1/SubSampleFactor);
%         BorderImage = subsample(squeeze(ImageScaled), SubSampleFactor);

    
    % If the image is a border image, but not a corner, convolve with the right
    % kernel to boost edges
%     if ~isempty(find(BorderImageToCheck([2:ColsRowsScan(1)-1 end-ColsRowsScan(1)+2:end-1]) == ii, 1))
% % %         dipshow(BorderImage)
%         BorderImage = conv2(BorderImage, KernelY,'same');
% % %         BorderImage = convolve(BorderImage, KernelX);
% 
% % %         dipshow(BorderImage)
%     elseif ~isempty(find(BorderImageToCheck(ColsRowsScan(1)+1:end-ColsRowsScan(1)) == ii, 1))
%         BorderImage = conv2(BorderImage, KernelX,'same');
% % %         BorderImage = convolve(BorderImage, KernelY);
%     end
    
    % insert image at current column and row
%     TotalCartridgeImage((CurrentCol-1)*XLength:CurrentCol*XLength-1,(CurrentRow-1)*YLength:CurrentRow*YLength-1) = BorderImage;
    TotalCartridgeImage((CurrentCol-1)*XLength+1:CurrentCol*XLength,(CurrentRow-1)*YLength+1:CurrentRow*YLength) = BorderImage;

    
    % if iteration is the number of colums, switch direction
    if rem(ii, ColsRowsScan(1)) == 0
        Directiony = -Directiony;
        CurrentCol = CurrentCol + Directionx;
    else
        CurrentRow = CurrentRow + Directiony;
    end
end

se = strel('disk',20);
TotalCartridgeImage = imopen(TotalCartridgeImage,se);
% dipshow(TotalCartridgeImage);
% icy_imshow(TotalCartridgeImage);


% apply gradient magnitude and threshold to check where border is located
% invert mask to get parts that are not borders
% GradientImage = gradmag(TotalCartridgeImage, KernelSizeGradMag);
% GradientImage = imgradient(TotalCartridgeImage);
% icy_imshow(GradientImage);

%  dipshow(GradientImage)
% MaskNotBorder = ~(threshold(GradientImage, 'triangle'));
% MaskNotBorder = ~(im2bw(TotalCartridgeImage,thresh));
%  icy_imshow(MaskNotBorder)

% % create seeding point for binary propagation: pick middle pixel of giant image
% SeedingPoint = [round(size(MaskNotBorder,1)/2) round(size(MaskNotBorder,2)/2)];
% it = 0;
% SizeMaskScanArea = 0;
% 
% % check if selected part of mask is big, otherwise choose different seeding
% % point and try again. Stop after 10 iterations
% while SizeMaskScanArea < MinCartridgeSize && it < 10
%     it = it + 1;
%     
%     % if pixel is seeding point is not part of a mask, choose another seeding point
%     while MaskNotBorder(SeedingPoint(1), SeedingPoint(2)) == 0
%         SeedingPoint = SeedingPoint + 5;
%     end
%     % create seed image
%     ImageSeed = 0*MaskNotBorder > 0;
%     ImageSeed(SeedingPoint(1), SeedingPoint(2)) = 1;
%     
%     % propagate mask to get big part in the middle of MaskNotBorder
%     MaskScanAreaBig = bpropagation(ImageSeed, MaskNotBorder, inf, -1, 0);
%     SizeMaskScanArea = sum(MaskScanAreaBig);
% end

% % dilate mask to correct for gaussian blur of gradient magnitude filter
% MaskScanAreaBig = bdilation(MaskScanAreaBig, KernelSizeGradMag, -1, 0);
% % fill holes in big mask
% MaskScanAreaBig = fillholes(MaskScanAreaBig);

MaskInit = zeros(size(TotalCartridgeImage));
    switch TifCount
        case 210 % 6*35 images
            MaskInit(round(XLength):end-1-round(XLength/2),round(YLength):end-round(YLength)) = 1;
        case 180 % 5*36 images
%             MaskInit(round(0.66*XLength):end-1-round(0.66*XLength),round(YLength/2):end+1-round(YLength/2)) = 1;
            MaskInit(round(XLength):end-1-round(XLength),round(1.5*YLength):end+1-round(1.5*YLength)) = 1;
        case 175 % 5*35 images
            MaskInit(round(XLength/2):end-1-round(XLength/2),round(YLength/2):end+1-round(YLength/2)) = 1;
        case 170 % 5*34 images
            MaskInit(:,round(YLength/2):end+1-round(YLength/2)) = 1;
        case 144 % 4*36 images
            MaskInit(round(XLength/2):end-1-round(XLength/2),:) = 1;
        case 140 % 4*35 images
            MaskInit(:,:) = 1;
    end
%     icy_imshow(MaskInit);
    
MaskScanAreaBig = activecontour(TotalCartridgeImage,MaskInit);
% icy_imshow(MaskScanAreaBig);
% % icy_imshow(MaskNotBorder);
% se = strel('disk',5);
% MaskScanAreaBig = imopen(MaskNotBorder,se);
% SizeMaskScanArea = sum(MaskScanAreaBig(:));

% check if mask is within size range established by checking easy cartridges
% if SizeMaskScanArea < MinCartridgeSize  || SizeMaskScanArea > MaxCartridgeSize 
%     
%     % if size is not within range, reset mask    
%     MaskScanAreaBig = 0*MaskScanAreaBig;
%     
%     % create a standard shaped mask, which is 4*35 in size (so, 5600X512 in most cases)
%     Error_out = 'Using Template border mask';
%    
%     switch TifCount
%         case 210 % 6*35 images
%             MaskScanAreaBig(round(XLength):end-1-round(XLength/2),round(YLength):end-round(YLength)) = 1;
%         case 180 % 5*36 images
%             MaskScanAreaBig(round(0.66*XLength):end-1-round(0.66*XLength),round(YLength/2):end+1-round(YLength/2)) = 1;
%         case 175 % 5*35 images
%             MaskScanAreaBig(round(XLength/2):end-1-round(XLength/2),round(YLength/2):end+1-round(YLength/2)) = 1;
%         case 170 % 5*34 images
%             MaskScanAreaBig(:,round(YLength/2):end+1-round(YLength/2)) = 1;
%         case 144 % 4*36 images
%             MaskScanAreaBig(round(XLength/2):end-1-round(XLength/2),:) = 1;
%         case 140 % 4*35 images
%             MaskScanAreaBig(:,:) = 1;
%     end
%     
%     % mask image was double, make it binary
%     MaskScanAreaBig = MaskScanAreaBig > 0;
% end
% icy_imshow(MaskScanAreaBig);
% reset column and row numbers and direction to process big image
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

% create stack of images containing border from big image: invert
% first operation to create big image
for ii = 1:TifCount
%     MaskAreaToScan_out(:,:, ii-1) = MaskScanAreaBig((CurrentCol-1)*XLength:CurrentCol*XLength-1,(CurrentRow-1)*YLength:CurrentRow*YLength-1);
    MaskAreaToScan_out(:,:, ii) = MaskScanAreaBig((CurrentCol-1)*XLength+1:CurrentCol*XLength,(CurrentRow-1)*YLength+1:CurrentRow*YLength);


    
    if rem(ii, ColsRowsScan(1)) == 0
        Directiony = -Directiony;
        CurrentCol = CurrentCol + Directionx;
    else
        CurrentRow = CurrentRow + Directiony;
    end
end

MaskAreaToScan_out = MaskAreaToScan_out > 0;
% icy_im3show(MaskAreaToScan_out);