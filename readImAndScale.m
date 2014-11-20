function [curr_image, Error_out]= readImAndScale(dataP, varargin)
% use the previously gathered imageinfo and read all images in a multipage
% tiff. read only one channel if a channel is specified. Rescale and
% stretch values and rescale to approx old values if the image is a
% celltracks tiff: scales IMMC images back to 0..4095 scale. Otherwise a
% normal tiff is returned.


Error_out = '';

if numel(varargin)==1
    imageNumber=varargin{1};
    allChannels=true;
    channels=numel(dataP.temp.imageinfos{imageNumber});
elseif numel(varargin)==2
    imageNumber=varargin{1};
    allChannels=false;
    channel=varargin{2};
else
    curr_image=[];
    Error_out='incorrect number of variables passed to readImAndScale';
    return
end %function

if allChannels == true
    curr_image = zeros(dataP.temp.imageinfos{imageNumber}(1).Width,dataP.temp.imageinfos{imageNumber}(1).Height,channels, 'uint16');
    keyboard
    try
        curr_image = imread(dataP.temp.imageFileNames{imageNumber}, 'info',dataP.temp.imageinfos{imageNumber});
    catch
         Error_out = ['Tiff from channel ' num2str(ch) ' is not readable!'];
    return
    end
    
    if dataP.scaleData == true && dataP.temp.imagesAreFromCT == true
        for i=1:channels
            UnknownTags = dataP.temp.imageinfos{imageNumber}(i).UnknownTags;

            LowValue  =  UnknownTags(2).Value;
            HighValue =  UnknownTags(3).Value;

            % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
            keyboard
            curr_image(:,:,i) = LowValue + round(curr_image(:,:,i).*((HighValue-LowValue)/max(curr_image(:,:,i))));
        end
    end
else
    curr_image = zeros(dataP.temp.imageinfos{imageNumber}(channel).Width,dataP.temp.imageinfos{imageNumber}(channel).Height,1, 'uint16');
    try
        curr_image = imread(dataP.temp.imageFileNames{imageNumber}, channel, 'info',dataP.temp.imageinfos{imageNumber});
    catch
        Error_out = ['Tiff from channel ' num2str(ch) ' is not readable!'];
    return
    end
    if dataP.scaleData == true && dataP.temp.imagesAreFromCT == true
        UnknownTags = dataP.temp.imageinfos{imageNumber}(channel).UnknownTags;
        
        LowValue  =  UnknownTags(2).Value;
        HighValue =  UnknownTags(3).Value;
        
            
        % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
        curr_image = LowValue + round(double(curr_image) * ((HighValue-LowValue)/max(double(curr_image(:)))));
    end
end


