function [] = keypress_input(fig_obj,eventData)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
global i score sc_gui score_res

thumbs = sc_gui.thumbs;

key = str2double(get(fig_obj,'CurrentKey'));

if key == 1 || key == 3 || key == 5 || key == 7|| key == 9
    current_nr = sum(cellfun(@(x)~isempty(x),score(1,:)));
    score{i} = key;
%     score_res = update_scores (score_res,score);
    set(sc_gui.score, 'String', num2str(score{i}));
    pause(0.5)
    % update waitbar
    pos = get(sc_gui.waitbar,'position');  
    pos(3) = (sum(cellfun(@(x)~isempty(x),score(1,:))))/size(thumbs,2)*(4*sc_gui.framex+3*sc_gui.spacex); 
    set(sc_gui.waitbar,'position',pos,'string',sprintf('%.0f%%',(sum(cellfun(@(x)~isempty(x),score(1,:))))/size(thumbs,2)*100),'FontUnits', 'normalized','FontSize',0.7) 
    drawnow
    
    if i ~= size(score,2)
        i = i+1;
    else
        i = 1;
    end
    
    refresh_sc_gui(sc_gui,score,i);

    
    if current_nr == size(thumbs,2) - 1
        fontSize = 15;
        fontName = 'FixedWidth';
        msgHandle = msgbox( 'All cells are scored successfully.', 'Done!');

        % get handles to the UIControls ([OK] PushButton) and Text
        kids0 = findobj( msgHandle, 'Type', 'UIControl' );
        kids1 = findobj( msgHandle, 'Type', 'Text' );

        % change the font and fontsize
        extent0 = get( kids1, 'Extent' ); % text extent in old font
        pos0 = get( kids0, 'Position' );
        set( [kids0, kids1], 'FontName', fontName, 'FontSize', fontSize );
        extent1 = get( kids1, 'Extent' ); % text extent in new font

        % need to resize the msgbox object to accommodate new FontName 
        % and FontSize
        delta = extent1 - extent0; % change in extent
        pos = get( msgHandle, 'Position'); % msgbox current position
        pos = pos + delta; % change size of msgbox
        set( msgHandle, 'Position', pos ); % set new position
        set(kids0, 'Position', pos0 + [delta(3)/2 0 0 0]);
    end
        
elseif strcmp(eventData.Key,'leftarrow')
    if i ~= 1
        i = i-1;
    else
        i = size(score,2);
    end
    
    refresh_sc_gui(sc_gui,score,i);

elseif strcmp(eventData.Key,'rightarrow')
    if i ~= size(score,2)
        i = i+1;
    else
        i = 1;
    end
    
    refresh_sc_gui(sc_gui,score,i)
    
end


end

