function rem = email_reminder()

%window
posx = 0.4; posy = 0.4; width = 0.2; height = 0.2;
gui_color = [1 1 1];
rem = figure('Units','normalized','Position',[posx posy width height],'Name','Email Reminder',...
    'MenuBar','none','NumberTitle','off','Color', gui_color);
            
text_expl = ['\bf\fontsize{20}\fontname{Arial}Email Reminder:' char(10) '\rm\fontsize{15}Please send the scoring results directly to....'];
axes('units','normalized', 'position',[0.05 0.1 0.9 .8],'visible','off')
text(0,1,text_expl,'FontSize', 1.5)
end
