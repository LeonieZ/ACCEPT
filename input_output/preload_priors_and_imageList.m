function  Temp=preload_priors_and_imageList(sampleList(i))
% function that explores the sample directory and determins the sample
% type.
global ACTC
ACTC.Data.



end

function Temp=create_temp_images(Temp);
%Create a empty temp struct with default variables
global ACTC

Temp.rawImage=zeros(Temp.imageSize,ACTC.data.numChannels,'double');
Temp.processedImage=zeros(Temp.imageSize,ACTC.data.numChannels,'double');
Temp.maskImage=zeros(Temp.imageSize,ACTC.data.numChannels,'double');
end

function Temp=create_temp();
Temp.imageFileNames   = [];
Temp.imageInfos       = [];
Temp.imagesAreFromCT  = [];
Temp.imagesHaveOffset = [];
Temp.imageSize        = [];
Temp.rawImage         = [];
Temp.processedImage   = [];
Temp.maskImage        = [];
end