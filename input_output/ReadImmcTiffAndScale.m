function [curr_image, Error_out]= ReadImmcTiffAndScale(ImageName_in, ch, dataP, algP)
% open image with channel info read multipage tiff. Extract info from header
% by customized imtifinfo, get high and low stretch values and
% rescale to approx old values: scales IMMC images back to 0..4095 scale
% Will return if it's not an IMMC image. Customized imtifinfo_immc needed!

% modified without dipimage

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
end %function
        