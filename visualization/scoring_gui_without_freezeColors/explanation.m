function fig_expl = explanation(varargin)

%window
posx = 0.3; posy = 0.2; width = 0.4; height = 0.6;
gui_color = [1 1 1];
fig_expl = figure('Units','normalized','Position',[posx posy width height],'Name','Scoring Tool for CTCs - Explanations',...
    'MenuBar','none','NumberTitle','off','Color', gui_color);
            
text_expl = ['\bf\fontsize{20}\fontname{Arial}Manual on how to score CTCs using this CTC Scoring tool:' char(10) '\rm\fontsize{15}As a first step, please fill out your name and institute.'...
    char(10) '\rightarrow'];
axes('units','normalized', 'position',[0.05 0.1 0.9 .8],'visible','off')
text(0,1,text_expl)
end
