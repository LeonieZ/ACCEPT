function [ seg_image ] = thresholding(image_to_seg, dataP, algP)
% thresholds the image based on the fixed treshold saved in algP.thresh

seg_image = false(size(image_to_seg));
seg_image_temp = false(size(image_to_seg));
channelsToThreshold=unique(dataP.maskForChannel);

for i = 1:numel(channelsToThreshold)
    ch=channelsToThreshold(i);
    seg_image_temp(:,:,ch) = image_to_seg(:,:,ch)>algP.thresh(ch);
    seg_image_temp(:,:,ch) = bwareaopen(seg_image_temp(:,:,ch), 9);
    seg_image_temp(:,:,ch) = imclearborder(seg_image_temp(:,:,ch));
end

for ch = 1:dataP.numChannels
    seg_image(:,:,ch)=seg_image_temp(:,:,dataP.maskForChannel(ch));
end

end

