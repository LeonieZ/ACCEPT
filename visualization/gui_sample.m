function handle = gui_sample(base,currentSample)


% Main figure: create and set properies (relative size, color)
screensize = get(0,'Screensize');
rel = (screensize(3))/(screensize(4)); % relative screen size
maxRelHeight = 0.8;
posx = 0.2;
posy = 0.1;
width = ((16/12)/rel)*maxRelHeight; % use 16/12 window ratio on all computer screens
height = maxRelHeight;
gui_sample.fig_main = figure('Units','normalized','Position',[posx posy width height],'Name','ACCEPT - Automated CTC Classification Enumeration and PhenoTyping','MenuBar','none',...
    'NumberTitle','off','Color',[1 1 1],'Resize','off');


%% Main title
gui_sample.title_axes = axes('Units','normalized','Position',[0.5 0.95 0.18 0.04]); axis off;
gui_sample.title = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} Sample Visualizer','Units','normalized','FontUnits','normalized','FontSize',0.8,'verticalAlignment','base','horizontalAlignment','center');


%% Main panels
% create panel for overview (top-left)
gui_sample.uiPanelOverview = uipanel('Parent',gui_sample.fig_main,...
                                     'Position',[0.023 0.712 0.689 0.222],...
                                     'Title','Overview','TitlePosition','CenterTop',...
                                     'Units','normalized','FontUnits','normalized','FontSize',0.1,...
                                     'BackgroundColor',[1 1 1]);

% create panel for thumbnail gallery (bottom-left)
gui_sample.uiPanelGallery = uipanel('Parent',gui_sample.fig_main,...
                                    'Position',[0.023 0.021 0.689 0.669],...
                                     'Title','Cell Gallery','TitlePosition','CenterTop',...
                                     'Units','normalized','FontUnits','normalized','FontSize',0.033,...
                                     'BackgroundColor',[1 1 1]);

% create panel for scatter plots (right)
gui_sample.uiPanelScatter = uipanel('Parent',gui_sample.fig_main,...
                                    'Position',[0.731 0.021 0.245 0.913],...
                                     'Title','Marker Characterization','TitlePosition','CenterTop',...
                                     'Units','normalized','FontUnits','normalized','FontSize',0.023,...
                                     'BackgroundColor',[1 1 1]);

                                 
%% Fill uiPanelOverview
% create table with sample properties as overview
rnames = properties(currentSample);
selectedProps = [1,2,3,5,6,8,9,10]; % properties of data sample to be visualized
rnames = rnames(selectedProps); % row titles
cnames = {}; % col titles
dat = cell(numel(rnames),1);
for i = 1:numel(rnames)
   dat{i} = eval(['currentSample.',rnames{i}]); %getfield(handles.currentFrame,rnames{i});
end
gui_sample.tableDetails = uitable('Parent',gui_sample.uiPanelOverview,...
                                  'Units','normalized','Position',[0.03 0.07 0.2 0.85],...
                                  'Data',dat,'ColumnName',cnames,'RowName',rnames);
% tabExtend = get(tableDetails,'Extent')
% tabPosition = get(tableDetails,'Position');
% tabPosition(3:4) = tabExtend(3:4);
% set(tableDetails,'Position',tabPosition);

% create overview image per channel
gui_sample.axesOverview = axes('Parent',gui_sample.uiPanelOverview,...
                               'Units','normalized','Position',[0.25 0.07 0.73 0.82]);
defCh = 2; % default channel for overview when starting the sample visualizer
gui_sample.imageOverview = imagesc(currentSample.overviewImage(:,:,defCh));
axis image; axis off;

% create choose button to switch color channel
gui_sample.popupChannel = uicontrol('Style','popup','String',currentSample.channelNames,...
                                    'Units','normalized','Position',[0.4 -0.09 0.08 0.85],...
                                    'FontUnits','normalized','FontSize',0.02,...
                                    'Value',defCh,...
                                    'Callback',{@popupChannel_callback});

                                
%% Fill uiPanelGallery

% create slider for gallery
gui_sample.slider = uicontrol('Style','Slider','Parent',gui_sample.uiPanelGallery,...
                              'Units','normalized','Position',[0.98 0 0.02 0.95],...
                              'Value',1,'Callback',{@slider_callback});

% create panel for thumbnails next to slider                          
gui_sample.uiPanelThumbsOuter = uipanel('Parent',gui_sample.uiPanelGallery,...
                                        'Position',[0 0 0.98 0.95],...
                                        'BackgroundColor',[1 1 1]);

%-----
% compute relative dimension of the thumbnail grid
nbrAvailableRows = size(currentSample.priorLocations,1)
nbrColorChannels = 4; 
nbrImages        = nbrAvailableRows * (nbrColorChannels+1);
maxNumCols       = 5; % design decision, % maxNumCols = 1 (overlay) + nbrChannels

if nbrImages > maxNumCols^2
    cols  = maxNumCols;
    rows  = ceil(nbrImages/cols);
    set(gui_sample.slider,'enable','on','value',1); % enable and upper position
else % exceptional case
    cols = ceil( sqrt(nbrImages) );    % number of columns
    rows = cols - floor( (cols^2 - nbrImages)/cols );
    set(gui_sample.slider,'enable','off');
end
% pitch (box for axis) height and width
rPitch  = 0.98/rows;
cPitch  = 0.98/cols;
% axis height and width
axHight = 0.9/rows;
axWidth = 0.9/cols;
%-----

height = rows/cols;
%height = 3; %3 means 300% size of inner panel containing the image axes
width  = 1;
gui_sample.uiPanelThumbsInner = uipanel('Parent',gui_sample.uiPanelThumbsOuter,...
                                        'Position',[0 1-height width height],...
                                        'BackgroundColor',[1 1 1]);

%-----
hAxes = zeros(nbrImages,1);
% define common properties and values for all axes
axesProp = {'dataaspectratio' ,...
            'Parent',...
            'PlotBoxAspectRatio', ...
            'xgrid' ,...
            'ygrid'};
axesVal = {[1,1,1] , ...
           gui_sample.uiPanelThumbsInner,...
           [1 1 1]...
           'off',...
           'off'};
       
% go through all thumbnails (resp. dataframes)
for thumbInd=1:nbrAvailableRows
    % specify row location for all columns
    y = 1-thumbInd*rPitch;
    % obtain dataFrame from io
    dataFrame = base.io.load_thumbnail_frame(currentSample,thumbInd,'prior');
    % plot overlay image in first column
    x = 0;
    ind = (thumbInd-1)*nbrColorChannels + nbrColorChannels + 1; % index for first column element
    hAxes(ind) = axes('Position',[x y axWidth axHight],axesProp,axesVal);
    plotImInAxis(dataFrame.rawImage,hAxes(ind));
    % plot image for each color channel in column 2 till nbrChannels
    for ch = 1:nbrColorChannels
        x = 1-(nbrColorChannels-ch+1)*cPitch;
        ind = (thumbInd-1)*nbrColorChannels + ch;
        hAxes(ind) = axes('Position',[x y axWidth axHight],axesProp,axesVal);
        plotImInAxis(dataFrame.rawImage(:,:,ch),hAxes(ind));
    end
end
%-----

%-----
% TEST: a test axis and image to check scrolling behaviour
% gui_sample.bigTestAxes = axes('Parent',gui_sample.uiPanelThumbsInner,...
%                    'Position',[0 0 1 1],'xgrid','off','ygrid','off');
% imagesc(imread('eight.tif'),'parent',gui_sample.bigTestAxes); axis image;
%-----
                                
                                
%% Callback and helper functions

% --- Executes on selection in popupChannel.
function popupChannel_callback(hObject,~,~)
    selectedChannel = get(hObject,'Value');
    set(gui_sample.imageOverview,'CData',currentSample.overviewImage(:,:,selectedChannel));
end

% --- Executes on slider movement.
function slider_callback(hObject,~,~)
    val = get(hObject,'Value');
    set(gui_sample.uiPanelThumbsInner,'Position',[0 -val*(height-1) width height])
end

% --- Helper function used in thumbnail gallery to plot thumbnails in axes
function plotImInAxis(im,hAx)
    if size(im,3) > 1
        % create overlay image here
        imagesc(sum(im,3),{'ButtonDownFcn'},{'openSpecificImage( guidata(gcf) )'},'parent',hAx);
    else
        imagesc(im,{'ButtonDownFcn'},{'openSpecificImage( guidata(gcf) )'},'parent',hAx);
    end
    axis(hAx,'image');
    axis(hAx,'off');
    colormap(gray);
    drawnow;
end


% return handle 
handle = gui_sample;

end
                                 
                                 
%% ----

% gui.process_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Process','Units','normalized','Position',[0.22 0.1 0.22 0.05],'FontUnits','normalized', 'FontSize',0.3,'Callback', {@process,base}); 
% gui.visualize_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Visualize','Units','normalized','Position',[0.56 0.1 0.22 0.05],'FontUnits','normalized', 'FontSize',0.3,'Callback', {@visualize,base});
% gui.update_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Update sample list','Units','normalized','Position',[0.711 0.561 0.15 0.05],'FontUnits','normalized', 'FontSize',0.3,'Callback', {@update,base});
% 
% % gui.titel = uicontrol(gui.fig_main,'Style','text', 'String','ACCEPT','Units','normalized','Position',[0.41 0.83 0.18 0.04],'FontUnits','normalized', 'FontSize',1,'BackgroundColor',[1 1 1],'ForegroundColor',[0.729 0.161 0.208]);
% % gui.title_axes = axes('Units','normalized','Position',[0.41 0.83 0.18 0.04]);
% % gui.titel = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} ACCEPT','Units','normalized','FontUnits','normalized', 'FontSize',1,'verticalAlignment','base','horizontalAlignment','left');
% gui.title_axes = axes('Units','normalized','Position',[0.5 0.83 0.18 0.04]); axis off;
% gui.titel = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} ACCEPT','Units','normalized','FontUnits','normalized', 'FontSize',1,'verticalAlignment','base','horizontalAlignment','center');
% 
% gui.subtitle_axes = axes('Units','normalized','Position',[0.082 0.77 0.85 0.03]);axis off;
% gui.subtitel = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208}A\color[rgb]{0,0,0}utom\color[rgb]{0,0,0}ated \color[rgb]{0.729,0.161,0.208}C\color[rgb]{0,0,0}TC \color[rgb]{0.729,0.161,0.208}C\color[rgb]{0,0,0}lassification \color[rgb]{0.729,0.161,0.208}E\color[rgb]{0,0,0}numeration and \color[rgb]{0.729,0.161,0.208}P\color[rgb]{0,0,0}heno\color[rgb]{0.729,0.161,0.208}T\color[rgb]{0,0,0}yping','Units','normalized','FontUnits','normalized', 'FontSize',1,'verticalAlignment','base','horizontalAlignment','left');
% % gui.subtitle_axes = axes('Units','normalized','Position',[0.5 0.77 0.5 0.03]);
% % gui.subtitel = text('Position',[0 0],'String','Automated CTC Classification Enumeration and PhenoTyping','Units','normalized','FontUnits','normalized', 'FontSize',1,'verticalAlignment','base','horizontalAlignment','center');
% 
% 
% gui.task = uicontrol(gui.fig_main,'Style','text', 'String','Choose a task:','Units','normalized','Position',[0.22 0.7 0.15 0.02],'FontUnits','normalized', 'FontSize',1,'BackgroundColor',[1 1 1]);
% gui.task_list = uicontrol('Style', 'popup','String', tasks,'Units','normalized','Position', [0.39 0.703 0.39 0.019],'Callback', {@choosetask,base}, 'FontUnits','normalized', 'FontSize',1);  
% set(gui.task_list,'Value',defaultSampleProcessorNumber);
% % create sampleProcessor object for - per default - selected sampleProcessor 
% currentSampleProcessorName = strrep(gui.tasks_raw{get(gui.task_list,'Value')},'.m','');
% eval(['base.sampleProcessor = ',currentSampleProcessorName,'();']);
% 
% gui.input_path_frame = uipanel('Parent',gui.fig_main, 'Units','normalized','Position',[0.14 0.597 0.359 0.038]);
% gui.input_path = uicontrol(gui.fig_main,'Style','text', 'String','','Units','normalized','Position',[0.143 0.608 0.353 0.016],'FontUnits','normalized', 'FontSize',1);
% gui.input_path_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Select input folder','Units','normalized','Position',[0.5 0.597 0.2 0.038],'FontUnits','normalized', 'FontSize',0.4,'Callback', @input_path);
% 
% gui.results_path_frame = uipanel('Parent',gui.fig_main, 'Units','normalized','Position',[0.14 0.537 0.359 0.038]);
% gui.results_path = uicontrol(gui.fig_main,'Style','text', 'String','','Units','normalized','Position',[0.143 0.548 0.353 0.016],'FontUnits','normalized', 'FontSize',1);
% gui.results_path_button = uicontrol(gui.fig_main,'Style','pushbutton','String','Select results folder','Units','normalized','Position',[0.5 0.537 0.2 0.038],'FontUnits','normalized', 'FontSize',0.4,'Callback', @results_path);
% 
% gui.uni_logo_axes = axes('Units','normalized','Position',[0.57 0.025 0.4 0.4*uni_logo_rel*rel]);
% gui.uni_logo = imagesc(uni_logo);  axis off;
% 
% gui.cancerid_logo_axes = axes('Units','normalized','Position',[0.66 0.83 0.3 0.3*cancerid_logo_rel*rel]); 
% gui.cancerid_logo = imagesc(cancerid_logo); axis off;
% 
% % gui.subtitle_axes = axes('Units','normalized','Position',[0.13 0.77 0.74 0.74*subtitle_rel*rel]);
% % gui.subtitle = imagesc(subtitle);  axis off;
% 
% gui.table_frame = uipanel('Parent',gui.fig_main, 'Units','normalized','Position',[0.34 0.1805 0.32 0.326], 'BackgroundColor', [1 1 1]);
% gui.table = uitable('Parent', gui.table_frame, 'Data', [],'ColumnName', {'Sample name','Processed'},'ColumnFormat', {'char','logical'},'ColumnEditable', false,'RowName',[],'Units','normalized',...
%     'Position', [0 0 1 1],'ColumnWidth',{0.32*0.5869*0.5*gui.screensize(3) 0.32*0.3869*0.5*gui.screensize(3)}, 'FontUnits','normalized', 'FontSize',0.05,'CellSelectionCallback',@(src,evnt)set(src,'UserData',evnt.Indices));
% 
% handle = gui.fig_main;
% end
% 
% function process(~,~,base)
% global gui
% display('Process samples...')
% selectedCellsInTable = get(gui.table,'UserData');
% selectedSamples = selectedCellsInTable(:,1);
% % update the current sampleList: selected samples should be processed
% base.sampleList.toBeProcessed(selectedSamples) = 1;
% base.run();
% end
% 
% function update(~,~,base)
% global gui
% display('Load samples...')
% inputPath = get(gui.input_path,'String');
% resultPath = get(gui.results_path,'String');
% base.sampleList = base.io.create_sample_list(...
%                         inputPath,resultPath,base.sampleProcessor);
% sl = base.sampleList;
% nbrSamples = size(sl.sampleNames,2);
% nbrAttributes = 2;
% dat = cell(nbrSamples,nbrAttributes);
% for r=1:nbrSamples
%     dat{r,1} = sl.sampleNames{1,r};
%     dat{r,2} = sl.isProcessed(1,r);
% end                    
% set(gui.table,'data', dat);
% end
% 
% function visualize(~,~,base)
% global gui
% display('Visualize samples...')
% selectedCellsInTable = get(gui.table,'UserData');
% selectedSamples = selectedCellsInTable(:,1);
% if numel(selectedSamples) == 1
%     % load selected sample
%     currentSample = base.io.load_sample(base.sampleList,selectedSamples);
%     % run sampleVisGui with loaded sample
%     gui_sample_visualizer(base,currentSample);
% else
%     warning('Too many samples selected for visualization');
% end
% end
% 
% function input_path(~,~)
% global gui
% inputPath = uigetdir(pwd,'Please select an input folder.');
% set(gui.input_path,'String',inputPath);
% end
% 
% function results_path(~,~)
% global gui
% resultPath = uigetdir(pwd,'Please select a results folder.');
% set(gui.results_path,'String',resultPath);
% end
% 
% function choosetask(source,~,base)
% global gui
% val = get(source,'Value');        
% set(gui.task_list,'Value',val);
% % create sampleProcessor object for selected sampleProcessor 
% currentSampleProcessorName = strrep(gui.tasks_raw{val},'.m','');
% eval(['base.sampleProcessor = ',currentSampleProcessorName,'();']);
% end
% 
