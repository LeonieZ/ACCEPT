%% This file is part of ACCEPT, 
% A program for the automated classification, enumeration and 
% phenotyping of Circulating Tumor Cells.
% Copyright (C) 2016 Leonie Zeune, Guus van Dalum, Christoph Brune
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% 
function [gui] = gui_mask()

set(0,'units','characters');  
screensz = get(0,'screensize');

nrofChannels = 4;

gui.fig_main = figure('Units','characters','Position',[(screensz(3)-95)/2 (screensz(4)-20)/2 95 14],'Name','ACCEPT - Set Mask','MenuBar','none',...
'NumberTitle','off','Color', [1 1 1],'Resize','off','Visible','on');

gui.headline = uicontrol('Style','text','Parent',gui.fig_main,...
                                    'Units','characters','Position',[2 11 55 2],...
                                    'String','Create Mask for Segmentation','HorizontalAlignment','left',...
                                    'FontUnits', 'normalized','FontSize',0.7,...
                                    'BackgroundColor',[1 1 1]);
                                
                                
gui.panel_main = uipanel('Title','Segmentation Mask','FontSize',12,'BackgroundColor','white','Units','characters','Position',[1 0.5 93 10.3]);                        

gui.name1 = uicontrol('Style','text','Parent',gui.fig_main,'Units','characters','Position',[2 6.5 25 1.92],'String','Original Channel','HorizontalAlignment','left',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[1 1 1]);
gui.name2 = uicontrol('Style','text','Parent',gui.fig_main,'Units','characters','Position',[2 3.5 25 1.92],'String','Channel Used','HorizontalAlignment','left',...
    'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
gui.name3 = uicontrol('Style','text','Parent',gui.fig_main,'Units','characters','Position',[2 1 25 1.92],'String','Dilate','HorizontalAlignment','left',...
    'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);

                                
for j = 1:4  
    gui.channel_panel(j) = uipanel('Parent',gui.fig_main,'BackgroundColor','white','Units','characters','Position',[30+(j-1)*8 6.1 7 2.7]); 
    gui.channel(j) = uicontrol('Style','text','Parent',gui.fig_main,'Units','characters','Position',[31+(j-1)*8 6.2 5 2.5],'String',j,'HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.mask(j) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[30+(j-1)*8 3.1 7 2.7],'String',j,'HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.dilate(j) = uicontrol(gui.fig_main,'Style', 'checkbox','Units','characters','Position', [31.7+(j-1)*8 1.4 3 1.2],'Callback', [],...
                            'FontUnits','normalized', 'FontSize',0.7);
end
                    
gui.addGates = uicontrol(gui.fig_main,'Style','pushbutton','String','+','Units','characters','Position',[62 6.1 7 2.7],'FontUnits','normalized', 'FontSize',0.8,'Callback', @addgate);
gui.deleteGates = uicontrol(gui.fig_main,'Style','pushbutton','String','-','Units','characters','Position',[62 3.1 7 2.7],'FontUnits','normalized', 'FontSize',0.8,'Callback', @deletegate);
gui.done = uicontrol(gui.fig_main,'Style','pushbutton','String','Done!','Units','characters','Position',[79 11.1 15 2],'FontUnits','normalized', 'FontSize',0.8,'Callback', {@exportmask,1});


%---------------------------------------------
function addgate(~,~)
    if nrofChannels < 7
    %     gui.fig_main.Position = [gui.fig_main.Position(1) gui.fig_main.Position(2)-3 gui.fig_main.Position(3) gui.fig_main.Position(4)+3];
        gui.channel_panel(nrofChannels + 1) = uipanel('Parent',gui.fig_main,'BackgroundColor','white','Units','characters','Position',[30+(nrofChannels)*8 6.1 7 2.7]); 
        gui.channel(nrofChannels + 1) = uicontrol('Style','text','Parent',gui.fig_main,'Units','characters','Position',[31+(nrofChannels)*8 6.2 5 2.5],'String',nrofChannels + 1,'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
        gui.mask(nrofChannels + 1) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[30+(nrofChannels)*8 3.1 7 2.7],'String',nrofChannels + 1,'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
        gui.dilate(nrofChannels + 1) = uicontrol(gui.fig_main,'Style', 'checkbox','Units','characters','Position', [31.7+(nrofChannels)*8 1.4 3 1.2],'Callback', [],...
                                'FontUnits','normalized', 'FontSize',0.7);
        gui.addGates.Position(1) = gui.addGates.Position(1) + 8;
        gui.deleteGates.Position(1) = gui.deleteGates.Position(1) + 8;
        nrofChannels = nrofChannels + 1; 
    end
end

function deletegate(~,~)
    if nrofChannels > 1
    %     gui.fig_main.Position = [gui.fig_main.Position(1) gui.fig_main.Position(2)-3 gui.fig_main.Position(3) gui.fig_main.Position(4)+3];
        delete(gui.channel_panel(nrofChannels));
        delete(gui.channel(nrofChannels)); 
        delete(gui.mask(nrofChannels)); 
        delete(gui.dilate(nrofChannels)); 
        gui.addGates.Position(1) = gui.addGates.Position(1) - 8;
        gui.deleteGates.Position(1) = gui.deleteGates.Position(1) - 8;
        nrofChannels = nrofChannels - 1; 
    end
end

function res = exportmask(~,~,close)
    res.mask = zeros(1,nrofChannels);
    res.dilate = zeros(1,nrofChannels);
    for i = 1:nrofChannels
        number = str2double(gui.mask(i).String);
        if ~isempty(number) && number >=0 && number <=nrofChannels
            res.mask(i) = number;
            res.dilate(i) = gui.dilate(i).Value;
        else
            waitfor(msgbox(['Not a valid channel to be used for channel ' num2str(i) '.']));
            close = 0;
        end        
    end
    if close == 1
        set(gui.fig_main,'UserData',res);
        set(gcf,'Visible','off');
    end
end
end

