function im = cutMiddle(im,rPixels,cPixels)

    rr = floor(rPixels/2);
    cc = floor( cPixels/2 );
    
    s =size(im);
    r = 1:s(1); c = 1:s(2);
    
    if s(1) > rPixels
        mR = round( s(1)/2 );
        r = mR-rr:mR+rr+1;
    end
    if s(2) > cPixels
        mC = round( s(2)/2 );
        c = mC-cc:mC+cc+1;
    end
    im = im(r,c);    
