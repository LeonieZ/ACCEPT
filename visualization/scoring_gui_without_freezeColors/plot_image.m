function handle = plot_image(ax_h,imageIn,maxi,scale)
    d=size(imageIn,3);
    orange = [1,0.5,0];
    blue = [0,0.5,1];
    magenta = [1,0,1];
    green =[0,1,0];
    switch d
        case 1
            map = parula(maxi);
            %map = gray(maxi)
            switch scale
                case 'fullscale'
                    image = imageIn/maxi;
                case 'normalized'
                    
                    image = (imageIn-min(min(imageIn)))/max(max(imageIn));
            end
        handle = imshow(image,'parent',ax_h,'Colormap',map,'InitialMagnification','fit');    
        case 3
            image=imageIn;
            switch scale
                case 'fullscale_rgb'
                    image = imageIn/maxi;
                case 'fullscale_mg'
                    for i=1:3
                        image(:,:,i) = imageIn(:,:,1)./maxi.*magenta(i)+imageIn(:,:,2)./maxi.*green(i);
                    end
                case 'fullscale_ob'
                    for i=1:3
                        image(:,:,i) = imageIn(:,:,1)./maxi.*blue(i)+imageIn(:,:,2)./maxi.*orange(i);
                    end
                case 'normalized_rgb'
                    for i=1:3
                        image(:,:,i) = (imageIn(:,:,i)-min(min(imageIn(:,:,i))))/max(max(imageIn(:,:,i)));
                    end
                case 'normalized_mg'
                    for i=1:2
                        timage(:,:,i) = (imageIn(:,:,i)-min(min(imageIn(:,:,i))))/max(max(imageIn(:,:,i)));
                    end
                    for i=1:3
                        image(:,:,i) = timage(:,:,1).*magenta(i)+timage(:,:,2).*green(i);
                    end
                case 'normalized_ob'
                    for i=1:2
                        timage(:,:,i) = (imageIn(:,:,i)-min(min(imageIn(:,:,i))))/max(max(imageIn(:,:,i)));
                    end
                    for i=1:3
                        image(:,:,i) = timage(:,:,1).*blue(i)+timage(:,:,2).*orange(i);
                    end
            end
        handle = imshow(image,'parent',ax_h,'InitialMagnification','fit'); 
    end
end
