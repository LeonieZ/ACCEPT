function [ seg_image ] = thresholding(image_to_seg, dataP, algP)
% thresholds the image based on the fixed treshold saved in algP.thresh

seg_image = false(size(image_to_seg));

thresh = (algP.thresh + dataP.thresholdOffset);

for ch = 1:dataP.numFrames

    seg_image(:,:,ch) = image_to_seg(:,:,ch)>thresh(ch);
    seg_image(:,:,ch) = bwareaopen(seg_image(:,:,ch), 9);
    seg_image(:,:,ch) = imclearborder(seg_image(:,:,ch));
end

end

