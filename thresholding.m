function [ seg_image ] = thresholding(image_to_seg, dataP, algP)
% thresholds the image based on the fixed treshold saved in algP.thresh
seg_image = zeros(size(image_to_seg));

if dataP.scaleData == true
    scale = 4095;
else
    scale = 255;
end

thresh = (algP.thresh + dataP.thresholdOffset) / scale;
image_to_seg = image_to_seg / scale;

for ch = 1:dataP.numFrames
%     if ch == dataP.DapiChannel
%         seg_image(:,:,ch) = im2bw(image_to_seg(:,:,ch),thresh(ch));
%     else
        seg_image(:,:,ch) = im2bw(image_to_seg(:,:,ch), thresh(ch));
%     end
    
    seg_image(:,:,ch) = bwareaopen(seg_image(:,:,ch), 2);
    seg_image(:,:,ch) = imclearborder(seg_image(:,:,ch));
end

end

