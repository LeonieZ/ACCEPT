function [curr_image, Error_out]= readImAndScale(dataP, varargin)
% use the previously gathered imageinfo and read all images in a multipage
% tiff. read only one channel if a channel is specified. Rescale and
% stretch values and rescale to approx old values if the image is a
% celltracks tiff: scales IMMC images back to 0..4095 scale. Otherwise a
% normal tiff is returned.


if numel(varargin)==1

curr_image = [];
Error_out = '';
% try reading the image. If this fails, the image might be corrupt
try
    curr_image = imread(ImageName_in, ch);
catch
    Error_out = ['Tiff from channel ' num2str(ch) ' is not readable!'];
    return
end

if dataP.scaleData == true
    % try reading tiff. If this fails, the header isn't from an IMMC tiff
    try
      InfoTiff = imtifinfo_immc(ImageName_in);
    catch 
        Error_out = 'Tiff is not an IMMC tiff!';
        return
    end
            
    HighValue =  InfoTiff(ch).HigherStretchLimit;
    LowValue =  InfoTiff(ch).LowerStretchLimit;
            
    % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
    curr_image = LowValue + round(double(curr_image) * ((HighValue-LowValue)/max(double(curr_image(:)))));
end
elseif numel(varargin)==2

else
curr_image=[];
Error_out='incorrect number of variables passed to readImAndScale';
end %function
        