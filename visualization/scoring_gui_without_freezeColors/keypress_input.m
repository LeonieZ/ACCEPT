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
        box_finish = msgbox('All cells are scored successfully.','Success');
%         ah = get( box_finish, 'CurrentAxes' );
%         ch = get( ah, 'Children' );
%         set( ch, 'FontSize', 15 );
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

