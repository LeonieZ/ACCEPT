function [Success_out, Msr, algP] = FindAndMeasureObjects(input_cartridge,dataP, algP)

% Function to find actc and wbc in a cartridge

%% variable initialization

Success_out = 'Cartridge ok';
algP.thresh = zeros(dataP.numFrames,1);
Msr = [];

%% Find images in input path
% determine in which directory the tiff files are located.

[dataP, Success_out] = get_image_filenames(dataP, input_cartridge);

if strcmp(Success_out, 'No Tiff dir found') || strcmp(Success_out, 'More than one dir found')
   return 
end

dataP = get_image_info(dataP);
% determine image size
sizeX = dataP.temp.imageinfos{1}(1).Width;
sizeY = dataP.temp.imageinfos{1}(1).Height;
keyboard
%% Detect cartridge edge
if dataP.removeEdges == true
    % Get scan area: exclude border of cartridge
    [MaskEdgesCartridge, BorderCheckSuccess]= GetScanArea(dataP, algP);

    if strcmp(BorderCheckSuccess, 'error reading FITC image in function GetScanArea')
        Success_out = BorderCheckSuccess;
        return
    elseif strcmp(BorderCheckSuccess, 'Number of images in directory not normal!')
        Success_out = BorderCheckSuccess;
        return
    elseif strcmp(BorderCheckSuccess, 'Tiff from channel 2 is not readable!')
        Success_out = BorderCheckSuccess;
        return
    elseif strcmp(BorderCheckSuccess, 'Using Template border mask')
        Success_out = 'Used template border area';
    end
else
    MaskEdgesCartridge = ones(sizeX, sizeY, TiffCount);
end
    

%% Determine threshold if segmentation method is thresholding
if strcmp(func2str(algP.segMeth),'thresholding')
    [Error_Tiff, algP.thresh(1),algP.thresh(2),algP.thresh(3),algP.thresh(4)] = algP.threshMeth(tiff_dir, MaskEdgesCartridge, dataP, algP); % wie laesst sich das besser loesen, ohne das man die 4 einsetzt??
    
    if ~(isempty(Error_Tiff))
        Success_out = Error_Tiff;
        return
    end
end
%% process each tiff - prepare images for segmentation (read in/scale back/apply mask/...) 
for ii = 1:TiffCount

    FileNameTif = [tiff_dir filesep TiffFiles(ii).name];     
    for ch = 1:dataP.numFrames
       
        % try reading the image. If this fails, the image might be corrupt
        try
            curr_image = imread(FileNameTif, ch);
        catch
            Success_out = ['Tiff from channel ' num2str(ch) ' is not readable!'];
            return
        end
        
        if dataP.scaleData == true
            % try reading tiff header. If this fails, the header isn't from an IMMC tiff
            try
                InfoTiff = imtifinfo_immc(FileNameTif);
            catch 
                Success_out = 'Tiff is not an IMMC tiff!';
                return
            end
            
            HighValue =  InfoTiff(ch).HigherStretchLimit;
            LowValue =  InfoTiff(ch).LowerStretchLimit;
            
            % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
            curr_image = LowValue + round(double(curr_image) * ((HighValue-LowValue)/max(double(curr_image(:)))));
        end
        
        if ch == 1
            scaled_image = zeros(sizeX, sizeY, 4);
        end
                
        scaled_image(:,:,ch) = curr_image;
    end
    
    % subtract if offset of 32768 exists
    if max(scaled_image(:)) > 32767
        ImageScaled = ImageScaled - 32768;
    end
    
    % resample border image, create dummy image for transferring mask
    if dataP.removeEdges == true
        MaskEdge = squeeze(MaskEdgesCartridge(:,:,ii)); 
        MaskEdge = repmat(imresize(MaskEdge, [sizeX sizeY]),1,1,dataP.numFrames);
    end

    % create image without edges if removeEdges is activated
    image_to_seg = zeros(size(scaled_image));
    if dataP.removeEdges == true
        image_to_seg(MaskEdge) = scaled_image(MaskEdge);
%         const = ones(size(scaled_image));
%         for i = 1:dataP.numFrames
%             const(:,:,i) = (sum(sum(image_to_seg(:,:,i)))/(sum(sum(sum(MaskEdge)))/4));
%         end
%         image_to_seg(~(MaskEdge)) = const(~(MaskEdge));
        
    else
        image_to_seg = scaled_image;
    end
    
%     icy_im3show(image_to_seg)
    
%% segmentation step    
    
    seg_image = algP.segMeth(image_to_seg, dataP, algP);
%     icy_im3show(seg_image);

%% feature/measurement extraction

    % extract image number for use in measurement ID
    % CELLSEARCH SPECIFIC!! Find a more general way!!
    ending = strfind(TiffFiles(ii).name, '.tif');
    image_number = TiffFiles(ii).name(ending-3:ending-1);
    
    % measure features for each single cell
    New_msr = measurements(seg_image, image_to_seg, image_number, dataP, algP);

    if ii ==1
        Msr = New_msr;
    elseif max(max(seg_image)) > 0
        Msr = [Msr, New_msr];     
    end
    
%% save results of segmentation if wanted    
    if dataP.saveSeg == true
        param = strcat('segMethod=',func2str(algP.segMethod));
        resPath = fullfile(dataP.output_folder, param, input_cartridge, 'segmentation_results');
        if ~exist(resPath, 'dir')
            mkdir(resPath);
        end
        
        imwrite(uint16(seg_image(:,:,1)), [resPath filesep TiffFiles(ii).name]);
        for ch = 2:dataP.numFrames
            imwrite(uint16(seg_image(:,:,ch)), [resPath filesep TiffFiles(ii).name], 'writemode', 'append');
        end
    end
    
end
