function [gui] = gui_manual_gates()

set(0,'units','characters');  
screensz = get(0,'screensize');

nrofGates = 4;

feature_list = {'','Size', 'Eccentricity', 'Perimeter', 'MeanIntensity', 'MaxIntensity', 'StandardDeviation', 'Mass', 'P2A', 'Overlay CD45','Overlay CK'};

gui.fig_main = figure('Units','characters','Position',[(screensz(3)-95)/2 (screensz(4)-20)/2 95 23],'Name','ACCEPT - Set Manual Gates','MenuBar','none',...
    'NumberTitle','off','Color', [1 1 1],'Resize','off','Visible','on');

gui.text = uicontrol('Style','text','Parent',gui.fig_main,...
                                    'Units','characters','Position',[2 20 35 2],...
                                    'String','Set manual gates:','HorizontalAlignment','left',...
                                    'FontUnits', 'normalized','FontSize',0.7,...
                                    'BackgroundColor',[1 1 1]);
                                
gui.explanation = uicontrol('Style','text','Parent',gui.fig_main,...
                                    'Units','characters','Position',[2 1 85 3],...
                                    'String','Channel 1: Excl. Marker, Channel 2: Nucl. Marker, Channel 3: Incl Marker, Channel 4: Extra Marker 1, Channel 5: Extra Marker 2, ...'...
                                    ,'HorizontalAlignment','left','FontUnits', 'normalized','FontSize',0.33,'BackgroundColor',[1 1 1]);
for j = 1:4                    
    gui.channel(j) = uicontrol('Style','text','Parent',gui.fig_main,'Units','characters','Position',[2 (20-3*j) 12 1.5],'String','Channel','HorizontalAlignment','left',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.channel_nr(j) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[14.5 (20-3*j) 5.5 1.5],'String',[],'HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.feature_list(j) = uicontrol(gui.fig_main,'Style', 'popup','String', feature_list,'Units','characters','Position', [21 (20-3*j)+0.225 35 1.5],'Callback', [],...
                            'FontUnits','normalized', 'FontSize',0.7);  
    gui.largerThan(j) = uicontrol(gui.fig_main,'Style','togglebutton','String','>','Value', 0,'Units','characters','Position',[57 (20-3*j) 5 1.5],'FontUnits','normalized',...
                            'FontSize',0.7,'Callback', {@larger,j}); 
    gui.smallerThan(j) = uicontrol(gui.fig_main,'Style','togglebutton','String','<=','Value', 0,'Units','characters','Position',[63 (20-3*j) 5 1.5],'FontUnits','normalized',...
                            'FontSize',0.7,'Callback', {@smaller,j}); 
    gui.value(j) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[69 (20-3*j) 10 1.5],'String',[],'HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
end
                    
gui.addGates = uicontrol(gui.fig_main,'Style','pushbutton','String','+','Units','characters','Position',[81 8 5 1.5],'FontUnits','normalized', 'FontSize',0.8,'Callback', @addgate);
gui.deleteGates = uicontrol(gui.fig_main,'Style','pushbutton','String','-','Units','characters','Position',[87 8 5 1.5],'FontUnits','normalized', 'FontSize',0.8,'Callback', @deletegate);
gui.done = uicontrol(gui.fig_main,'Style','pushbutton','String','Done!','Units','characters','Position',[72 5 15 2],'FontUnits','normalized', 'FontSize',0.8,'Callback', @exportgates);


%---------------------------------------------
function addgate(~,~)
    gui.fig_main.Position = [gui.fig_main.Position(1) gui.fig_main.Position(2)-3 gui.fig_main.Position(3) gui.fig_main.Position(4)+3];
    gui.text.Position(2) = gui.text.Position(2)+3;
    for i = 1:nrofGates
        gui.channel(i).Position(2) = gui.channel(i).Position(2) + 3;
        gui.channel_nr(i).Position(2) = gui.channel_nr(i).Position(2) + 3; 
        gui.feature_list(i).Position(2) = gui.feature_list(i).Position(2) + 3;  
        gui.largerThan(i).Position(2) = gui.largerThan(i).Position(2) + 3;  
        gui.smallerThan(i).Position(2) = gui.smallerThan(i).Position(2) + 3; 
        gui.value(i).Position(2) = gui.value(i).Position(2) + 3; 
    end 
    gui.channel(nrofGates+1) = uicontrol('Style','text','Parent',gui.fig_main,'Units','characters','Position',[2 8 12 1.5],'String','Channel','HorizontalAlignment','left',...
                        'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.channel_nr(nrofGates+1) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[14.5 8 5.5 1.5],'String',' ','HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    gui.feature_list(nrofGates+1) = uicontrol(gui.fig_main,'Style', 'popup','String', feature_list,'Units','characters','Position', [21 8.225 35 1.5],'Callback', [],...
                            'FontUnits','normalized', 'FontSize',0.7);  
    gui.largerThan(nrofGates+1) = uicontrol(gui.fig_main,'Style','togglebutton','String','>','Value', 0,'Units','characters','Position',[57 8 5 1.5],'FontUnits','normalized',...
                            'FontSize',0.7,'Callback', {@larger,nrofGates+1}); 
    gui.smallerThan(nrofGates+1) = uicontrol(gui.fig_main,'Style','togglebutton','String','<=','Value', 0,'Units','characters','Position',[63 8 5 1.5],'FontUnits','normalized',...
                            'FontSize',0.7,'Callback', {@smaller,nrofGates+1}); 
    gui.value(nrofGates+1) = uicontrol('Style','edit','Parent',gui.fig_main,'Units','characters','Position',[69 8 10 1.5],'String',' ','HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.7,'BackgroundColor',[ 1 1 1]);
    nrofGates = nrofGates + 1;                    
end

function deletegate(~,~)
    if nrofGates > 1
        gui.fig_main.Position = [gui.fig_main.Position(1) gui.fig_main.Position(2)+3 gui.fig_main.Position(3) gui.fig_main.Position(4)-3];
        gui.text.Position(2) = gui.text.Position(2)-3;
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

function gates = exportgates(~,~)
    gates = cell(nrofGates,3);
    for i = 1:nrofGates
        if (~isempty(gui.channel_nr(i).String) && gui.feature_list(i).Value ~= 1 && ...
                gui.largerThan(i).Value ~= gui.smallerThan(i).Value && ~isempty(gui.value(i).String))
            gates{i,1} = ['ch_' regexprep(gui.channel_nr(i).String,' ','') '_' feature_list{gui.feature_list(i).Value}];
            if strcmp(feature_list{gui.feature_list(i).Value},'Overlay CD45') || strcmp(feature_list{gui.feature_list(i).Value},'Overlay CK')
                if str2double(gui.channel_nr(i).String) == 2
                    gates{i,1} = strrep(gates{i,1}, 'Overlay CD45', 'Overlay_ch_1');
                    gates{i,1} = strrep(gates{i,1}, 'Overlay CK', 'Overlay_ch_3');
                else
                    gates{i,1} = [];
                end
            end
            if gui.largerThan(i).Value == 1 && gui.smallerThan(i).Value == 0
                gates{i,2} = 'lower';
            elseif gui.largerThan(i).Value == 0 && gui.smallerThan(i).Value == 1
                gates{i,2} = 'upper';
            end
            gates{i,3} = str2double(gui.value(i).String);
        end
    end
    set(gui.fig_main,'UserData',gates);
    set(gcf,'Visible','off');
end
end

