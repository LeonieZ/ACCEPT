function seg_image = convexSeg(image, dataP, ~)

seg_image = zeros(size(image));

if dataP.scaleData == true
    image = (double(image)/4095)*255;
end

% use a do-nothing edge detector
edge = ones(size(image(:,:,1)));

for ch = 1:dataP.numFrames
    % process image and convert to binary
    seg_image(:,:,ch) = (sbseg(image(:,:,ch),edge,9e-1)>0.9);
end

end