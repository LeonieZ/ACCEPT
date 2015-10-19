function openSpecificImage
    type = get(gcf,'SelectionType');
    switch type
        case 'open' % double-click
            im = get( gcbo,'cdata' );
            get(gcbo,'Parent')
            gca
            figure; imagesc(im); colorbar; colormap(gray); axis equal; axis off;
        case 'normal'   
            %left mouse button action
            %get(gcbo)
            set(gcbo,'Selected','on');
        case 'extend'
            % shift & left mouse button action
        case 'alt'
            % alt & left mouse button action
    end
end