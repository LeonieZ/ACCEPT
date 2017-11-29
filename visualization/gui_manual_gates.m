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
function [gui] = gui_manual_gates()

set(0,'units','characters');  
screensz = get(0,'screensize');

nrofGates = 4;

feature_list = {'','Size', 'Eccentricity', 'Perimeter', 'MeanIntensity', 'MaxIntensity', 'MedianIntensity', 'StandardDeviation', 'Mass', 'P2A', 'Overlay with DNA'};

gui.fig_main = figure('Units','characters','Position',[(screensz(3)-95)/2 (screensz(4)-20)/2 95 33],'Name','ACCEPT - Set Manual Gates','MenuBar','none',...
'NumberTitle','off','Color', [1 1 1],'Resize','off','Visible','on');

gui.headline = uicontrol('Style','text','Parent',gui.fig_main,...
                                    'Units','characters','Position',[2 30 35 2],...
                                    'String','Create Manual Gate','HorizontalAlignment','left',...
                                    'FontUnits', 'normalized','FontSize',0.7,...
                                    'BackgroundColor',[1 1 1]);
                                
gui.load = uicontrol(gui.fig_main,'Style','pushbutton','String','Load','Units','characters','Position',[84 30 10 2],...
    'FontUnits','normalized', 'FontSize',0.5,'Callback', @load_gates);
gui.save = uicontrol(gui.fig_main,'Style','pushbutton','String','Save','Units','characters','Position',[73.5 30 10 2],...
    'FontUnits','normalized', 'FontSize',0.5,'Callback', @save_gates);

gui.panel_name = uipanel('Title','Name','FontSize',12,'BackgroundColor','white','Units','characters','Position',[1 25 93 5]);

gui.text_name = uicontrol('Style','text','Parent',gui.fig_main,...
                                    'Units','characters','Position',[2 26 18 1.9],...
                                    'String','Set a name:','HorizontalAlignment','left',...
                                    'FontUnits', 'normalized','FontSize',0.7,...
                                    'BackgroundColor',[1 1 1]);
                                
gui.name = uicontrol('Style','edit','Units','characters','Position',[21 26 35 1.9],'String','Manual Gate','HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[1 1 1]);

gui.panel_gates = uipanel('Title','Gates','FontSize',12,'BackgroundColor','white','Units','characters','Position',[1 7.5 93 17]);                        

gui.text = uicontrol('Style','text','Parent',gui.fig_main,...
                                    'Units','characters','Position',[2 20.5 35 1.9],...
                                    'String','Set manual gates:','HorizontalAlignment','left',...
                                    'FontUnits', 'normalized','FontSize',0.7,...
                                    'BackgroundColor',[1 1 1]);
                                
gui.explanation = uicontrol('Style','text','Parent',gui.fig_main,...
                                    'Units','characters','Position',[2 1 85 3],...
                                    'String','Channel 1: Excl. Marker, Channel 2: Nucl. Marker, Channel 3: Incl Marker, Channel 4: Extra Marker 1, Channel 5: Extra Marker 2, ...'...
                                    ,'HorizontalAlignment','left','FontUnits', 'normalized','FontSize',0.33,'BackgroundColor',[1 1 1]);
for j = 1:4                    
    gui.channel(j) = uicontrol('Style','text','Parent',gui.fig_main,'Units','characters','Position',[2 (21-3*j) 12 1.5],'String','Channel','HorizontalAlignment','left',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.channel_nr(j) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[14.5 (21-3*j) 5.5 1.5],'String',[],'HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.feature_list(j) = uicontrol(gui.fig_main,'Style', 'popup','String', feature_list,'Units','characters','Position', [21 (21-3*j)+0.225 35 1.5],'Callback', [],...
                            'FontUnits','normalized', 'FontSize',0.7);  
    gui.largerThan(j) = uicontrol(gui.fig_main,'Style','togglebutton','String','>','Value', 0,'Units','characters','Position',[57 (21-3*j) 5 1.5],'FontUnits','normalized',...
                            'FontSize',0.7,'Callback', {@larger,j}); 
    gui.smallerThan(j) = uicontrol(gui.fig_main,'Style','togglebutton','String','<=','Value', 0,'Units','characters','Position',[63 (21-3*j) 5 1.5],'FontUnits','normalized',...
                            'FontSize',0.7,'Callback', {@smaller,j}); 
    gui.value(j) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[69 (21-3*j) 10 1.5],'String',[],'HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
end
                    
gui.addGates = uicontrol(gui.fig_main,'Style','pushbutton','String','+','Units','characters','Position',[81 8 5 1.5],'FontUnits','normalized', 'FontSize',0.8,'Callback', @addgate);
gui.deleteGates = uicontrol(gui.fig_main,'Style','pushbutton','String','-','Units','characters','Position',[87 8 5 1.5],'FontUnits','normalized', 'FontSize',0.8,'Callback', @deletegate);
gui.done = uicontrol(gui.fig_main,'Style','pushbutton','String','Done!','Units','characters','Position',[79 5 15 2],'FontUnits','normalized', 'FontSize',0.8,'Callback', {@exportgates,1});


%---------------------------------------------
function addgate(~,~)
    gui.fig_main.Position = [gui.fig_main.Position(1) gui.fig_main.Position(2)-3 gui.fig_main.Position(3) gui.fig_main.Position(4)+3];
    gui.text.Position(2) = gui.text.Position(2)+3;
    gui.headline.Position(2) = gui.headline.Position(2)+3;
    gui.load.Position(2) = gui.load.Position(2)+3;
    gui.save.Position(2) = gui.save.Position(2)+3;
    gui.panel_name.Position(2) = gui.panel_name.Position(2)+3;
    gui.text_name.Position(2) = gui.text_name.Position(2)+3;
    gui.name.Position(2) = gui.name.Position(2)+3;
    gui.panel_gates.Position(4) = gui.panel_gates.Position(4)+3;
    for i = 1:nrofGates
        gui.channel(i).Position(2) = gui.channel(i).Position(2) + 3;
        gui.channel_nr(i).Position(2) = gui.channel_nr(i).Position(2) + 3; 
        gui.feature_list(i).Position(2) = gui.feature_list(i).Position(2) + 3;  
        gui.largerThan(i).Position(2) = gui.largerThan(i).Position(2) + 3;  
        gui.smallerThan(i).Position(2) = gui.smallerThan(i).Position(2) + 3; 
        gui.value(i).Position(2) = gui.value(i).Position(2) + 3; 
    end 
    gui.channel(nrofGates+1) = uicontrol('Style','text','Parent',gui.fig_main,'Units','characters','Position',[2 9 12 1.5],'String','Channel','HorizontalAlignment','left',...
                        'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.channel_nr(nrofGates+1) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[14.5 9 5.5 1.5],'String',' ','HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.feature_list(nrofGates+1) = uicontrol(gui.fig_main,'Style', 'popup','String', feature_list,'Units','characters','Position', [21 9.225 35 1.5],'Callback', [],...
                            'FontUnits','normalized', 'FontSize',0.7);  
    gui.largerThan(nrofGates+1) = uicontrol(gui.fig_main,'Style','togglebutton','String','>','Value', 0,'Units','characters','Position',[57 9 5 1.5],'FontUnits','normalized',...
                            'FontSize',0.7,'Callback', {@larger,nrofGates+1}); 
    gui.smallerThan(nrofGates+1) = uicontrol(gui.fig_main,'Style','togglebutton','String','<=','Value', 0,'Units','characters','Position',[63 9 5 1.5],'FontUnits','normalized',...
                            'FontSize',0.7,'Callback', {@smaller,nrofGates+1}); 
    gui.value(nrofGates+1) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[69 9 10 1.5],'String',' ','HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    nrofGates = nrofGates + 1;                    
end

function deletegate(~,~)
    if nrofGates > 1
        gui.fig_main.Position = [gui.fig_main.Position(1) gui.fig_main.Position(2)+3 gui.fig_main.Position(3) gui.fig_main.Position(4)-3];
        gui.text.Position(2) = gui.text.Position(2)-3;
        gui.headline.Position(2) = gui.headline.Position(2)-3;
        gui.load.Position(2) = gui.load.Position(2)-3;
        gui.save.Position(2) = gui.save.Position(2)-3;
        gui.panel_name.Position(2) = gui.panel_name.Position(2)-3;
        gui.text_name.Position(2) = gui.text_name.Position(2)-3;
        gui.name.Position(2) = gui.name.Position(2)-3;
        gui.panel_gates.Position(4) = gui.panel_gates.Position(4)-3;
        for i = 1:nrofGates-1
            gui.channel(i).Position(2) = gui.channel(i).Position(2) - 3;
            gui.channel_nr(i).Position(2) = gui.channel_nr(i).Position(2) - 3; 
            gui.feature_list(i).Position(2) = gui.feature_list(i).Position(2) - 3;  
            gui.largerThan(i).Position(2) = gui.largerThan(i).Position(2) - 3;  
            gui.smallerThan(i).Position(2) = gui.smallerThan(i).Position(2) - 3; 
            gui.value(i).Position(2) = gui.value(i).Position(2) - 3; 
        end 
        delete(gui.channel(nrofGates));
        delete(gui.channel_nr(nrofGates)); 
        delete(gui.feature_list(nrofGates));
        delete(gui.largerThan(nrofGates));
        delete(gui.smallerThan(nrofGates));
        delete(gui.value(nrofGates));

        nrofGates = nrofGates - 1;  
    end
end

function larger(~,~,nr)
    set(gui.largerThan(nr),'Value',1);
    set(gui.smallerThan(nr),'Value',0);
end

function smaller(~,~,nr)
    set(gui.largerThan(nr),'Value',0);
    set(gui.smallerThan(nr),'Value',1);
end

function save_gates(~,~)
    res = exportgates([],[],0);
    gates = res.gates;
    file = which('ACCEPT.m');
    installDir = fileparts(file);
    [file_name, folder_name] = uiputfile([installDir filesep 'misc' filesep 'saved_gates' filesep res.name '.mat'],'Save gate.');
    save([folder_name filesep file_name],'gates')
end

function load_gates(~,~)
    file = which('ACCEPT.m');
    installDir = fileparts(file);
    [file_name, folder_name] = uigetfile([installDir filesep 'misc' filesep 'saved_gates' filesep '*.mat'],'Load gate.');
    gates = importdata([folder_name filesep file_name]);
    gates(sum(cellfun('isempty',gates),2)>0,:) = [];
    gui.name.String = strrep(strrep(file_name,'.mat',''),'_',' ');
    nrDiff = nrofGates - size(gates,1);
    for i = 1:abs(nrDiff)
        if nrDiff > 0
            deletegate();
        else
            addgate();
        end
    end
    nrofGates = size(gates,1);
    for i = 1:nrofGates
        infos = strsplit(gates{i,1},'_');  
        if isempty(strfind(infos{3},'Overlay'))
            gui.channel_nr(i).String = infos{2};
            gui.feature_list(i).Value = find(strcmp(infos{3},feature_list));
        else
            gui.channel_nr(i).String = infos{5};
            gui.feature_list(i).Value = find(strcmp('Overlay with DNA',feature_list));
        end
        if strcmp(gates{i,2},'upper')
            gui.largerThan(i).Value = 0;
            gui.smallerThan(i).Value = 1;
        elseif strcmp(gates{i,2},'lower')
            gui.largerThan(i).Value = 1;
            gui.smallerThan(i).Value = 0;
        end
        gui.value(i).String = num2str(gates{i,3});    
    end
end

function res = exportgates(~,~,close)
    res.name = strrep(gui.name.String,' ','_');
    res.gates = cell(nrofGates,3);
    for i = 1:nrofGates
        if (~isempty(gui.channel_nr(i).String) && gui.feature_list(i).Value ~= 1 && ...
                gui.largerThan(i).Value ~= gui.smallerThan(i).Value && ~isempty(gui.value(i).String))
            res.gates{i,1} = ['ch_' regexprep(gui.channel_nr(i).String,' ','') '_' feature_list{gui.feature_list(i).Value}];
            if strcmp(feature_list{gui.feature_list(i).Value},'Overlay with DNA')
                if str2double(gui.channel_nr(i).String) ~= 2
                    res.gates{i,1} = ['ch_2_Overlay_' strrep(res.gates{i,1}, '_Overlay with DNA', '')];
                else
                    res.gates{i,1} = [];
                end
            end
            if gui.largerThan(i).Value == 1 && gui.smallerThan(i).Value == 0
                res.gates{i,2} = 'lower';
            elseif gui.largerThan(i).Value == 0 && gui.smallerThan(i).Value == 1
                res.gates{i,2} = 'upper';
            end
            res.gates{i,3} = str2double(gui.value(i).String);
        end
    end
    if close == 1
        set(gui.fig_main,'UserData',res);
        set(gcf,'Visible','off');
    end
end
end

