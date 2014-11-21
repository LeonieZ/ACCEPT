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
    
    curr_image = zeros(dataP.temp.imageinfos{imageNumber}(1).Height,...
                       dataP.temp.imageinfos{imageNumber}(1).Width,...
                       channels, 'uint16');
    for i=1:channels
    [curr_image(:,:,i),Error_out] = loadOneChannel(dataP,imageNumber,i);
    end
        
elseif numel(varargin)==2
    imageNumber=varargin{1};
    allChannels=false;
    channel=varargin{2};
    [curr_image(:,:),Error_out] = loadOneChannel(dataP,imageNumber,channel);
else
    curr_image=[];
    Error_out='incorrect number of variables passed to readImAndScale';
    return
end %function

end

function [imageout,Error_out]=loadOneChannel(dataP,imageNumber,channel)
    %check if this preallocation is needed? \G
    imageout = zeros(dataP.temp.imageinfos{imageNumber}(channel).Height,...
                     dataP.temp.imageinfos{imageNumber}(channel).Width,...
                     1, 'uint16');
    Error_out = '';
    try
        imageout = imread(dataP.temp.imageFileNames{imageNumber}, channel, 'info',dataP.temp.imageinfos{imageNumber});
    catch
        Error_out = ['Tiff from channel ' num2str(ch) ' is not readable!'];
    return
    end
    if dataP.scaleData == true && dataP.temp.imagesAreFromCT == true
        UnknownTags = dataP.temp.imageinfos{imageNumber}(channel).UnknownTags;
        
        LowValue  =  UnknownTags(2).Value;
        HighValue =  UnknownTags(3).Value;
        
            
        % scale tiff back to "pseudo 12-bit". More advanced scaling necessary? 
        imageout = LowValue + round(double(imageout) * ((HighValue-LowValue)/max(double(imageout(:)))));
    end
end