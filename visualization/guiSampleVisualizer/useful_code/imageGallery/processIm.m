function [im score] = processIm(im)

    % Enter your processing function here...
    score = std(im(:));
    im = cutMiddle(im,512,512);
    
    im = histeq(im);
    im = conv2( double(im), gausswin(5),'same');


