function GuiSampleHandle = gui_sample(base,currentSample)

% Main figure: create and set properies (relative size, color)
screensize = get(0,'Screensize');
rel = (screensize(3))/(screensize(4)); % relative screen size
maxRelHeight = 0.8;
posx = 0.2;
posy = 0.1;
width = ((16/12)/rel)*maxRelHeight; % use 16/12 window ratio on all computer screens
height = maxRelHeight;
GuiSampleHandle.fig_main = figure('Units','normalized','Position',[posx posy width height],'Name','ACCEPT - Automated CTC Classification Enumeration and PhenoTyping','MenuBar','none',...
    'NumberTitle','off','Color',[1 1 1],'Resize','off');

%% Set maximum instensiy
if strcmp(currentSample.dataTypeOriginalImage,'uint8')
    maxi = 255;
elseif strcmp(currentSample.dataTypeOriginalImage,'uint12')
    maxi = 4095;
else
    maxi = 65535;
end
% Set maxi to 4095 until uint12 is implemented
maxi = 4095;
% if sc_gui.maxi == 65535 && max(cellfun(@(x)max(max(max(x))),sc_gui.thumbs(1,:))) <= 4095
%     sc_gui.maxi = 4095;
% end

%% Main title
GuiSampleHandle.title_axes = axes('Units','normalized','Position',[0.5 0.95 0.18 0.04]); axis off;
GuiSampleHandle.title = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} Sample Visualizer','Units','normalized','FontUnits','normalized','FontSize',0.8,'verticalAlignment','base','horizontalAlignment','center');


%% Main panels
% create panel for overview (top-left)
GuiSampleHandle.uiPanelOverview = uipanel('Parent',GuiSampleHandle.fig_main,...
                                     'Position',[0.023 0.712 0.689 0.222],...
                                     'Title','Overview','TitlePosition','CenterTop',...
                                     'Units','normalized','FontUnits','normalized','FontSize',0.1,...
                                     'BackgroundColor',[1 1 1]);

% create panel for thumbnail gallery (bottom-left)
GuiSampleHandle.uiPanelGallery = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Position',[0.023 0.021 0.689 0.669],...
                                     'Title','Cell Gallery','TitlePosition','CenterTop',...
                                     'Units','normalized','FontUnits','normalized','FontSize',0.033,...
                                     'BackgroundColor',[1 1 1]);

% create panel for scatter plots (right)
GuiSampleHandle.uiPanelScatter = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Position',[0.731 0.021 0.245 0.913],...
                                     'Title','Marker Characterization','TitlePosition','CenterTop',...
                                     'Units','normalized','FontUnits','normalized','FontSize',0.023,...
                                     'BackgroundColor',[1 1 1]);

                                 
%% Fill uiPanelOverview
% create table with sample properties as overview
propnames = properties(currentSample);
selectedProps = [1,2,5,6,10]; % properties of data sample to be visualized
propnames = propnames(selectedProps); % row titles
dat = cell(numel(propnames),1);
entry = cell(numel(propnames),1);
rnames = {'Sample ID','Type','Nr of Frames', 'Nr of Channels', 'Pixel Size','Nr of Scored Events'};
for i = 1:numel(propnames)
   dat{i} = eval(['currentSample.',propnames{i}]);
   entry{i} = [rnames{i}, ': ',num2str(dat{i})];
end

dat{6} = size(currentSample.results.thumbnails,1);
entry{6} = [rnames{6}, ': ',num2str(dat{6})];

GuiSampleHandle.uiPanelTable = uipanel('Parent',GuiSampleHandle.uiPanelOverview,...
                                     'Position',[0.01 0.1 0.25 0.9],...
                                     'Title','Sample Information','TitlePosition','CenterTop',...
                                     'Units','normalized','BackgroundColor',[1 1 1]);

GuiSampleHandle.tableDetails = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelTable,...
                                  'Units','normalized','Position',[0 0 1 1],...
                                  'String',entry,'FontUnits','normalized', 'FontSize',0.6*(1/size(entry,1)),'BackgroundColor',[1 1 1],'HorizontalAlignment','left','FontName','FixedWidth');

tabExtend = get(GuiSampleHandle.tableDetails,'Extent');
tabPosition = get(GuiSampleHandle.uiPanelTable,'Position');
%panelPosition = get(GuiSampleHandle.uiPanelOverview,'Position');
%tabPosition(4) = tabExtend(4).*tabPosition(4);
%tabPosition(3) = tabExtend(3).*tabPosition(3);
%set(GuiSampleHandle.uiPanelTable,'Position',tabPosition);

 
% % create overview image per channel
 GuiSampleHandle.axesOverview = axes('Parent',GuiSampleHandle.uiPanelOverview,...
                                'Units','normalized','Position',[tabPosition(1)+tabPosition(3)+0.01 0.07 1-(tabPosition(1)+tabPosition(3)+0.02) 0.82]);
%                            
 defCh = 2; % default channel for overview when starting the sample visualizer
 blank=zeros(size(currentSample.overviewImage(:,:,defCh)));
 GuiSampleHandle.imageOverview = imshow(blank,'parent',GuiSampleHandle.axesOverview,'InitialMagnification','fit');
 colormap(GuiSampleHandle.axesOverview,parula(4096));
 high=prctile(reshape(currentSample.overviewImage(:,:,defCh),[1,size(currentSample.overviewImage,1)*size(currentSample.overviewImage,2)]),99);
 plotImInAxis(currentSample.overviewImage(:,:,defCh).*(4095/high),[],GuiSampleHandle.axesOverview,GuiSampleHandle.imageOverview);
  
% % create choose button to switch color channel
 GuiSampleHandle.popupChannel = uicontrol('Style','popup','String',currentSample.channelNames,...
                                     'Units','normalized','Position',[0.4 -0.09 0.08 0.85],...
                                     'FontUnits','normalized','FontSize',0.02,...
                                     'Value',defCh,...
                                     'Callback',{@popupChannel_callback});

                                
%% Fill uiPanelGallery
gui_sample_color = [1 1 1];


% create column names for gallery
columnTextSize = 0.55;
GuiSampleHandle.textCol1 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.04 0.94 0.1 0.05],...
                                'String','Overlay','HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);
                            
GuiSampleHandle.textCol2 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.23 0.94 0.1 0.05],...
                                'String',currentSample.channelNames{1},'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);

GuiSampleHandle.textCol3 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.43 0.94 0.1 0.05],...
                                'String',currentSample.channelNames{2},'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);

GuiSampleHandle.textCol4 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.62 0.94 0.1 0.05],...
                                'String',currentSample.channelNames{3},'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);
                            
GuiSampleHandle.textCol5 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.81 0.94 0.1 0.05],...
                                'String',currentSample.channelNames{4},'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);
                       
% create panel for thumbnails next to slider                          
GuiSampleHandle.uiPanelThumbsOuter = uipanel('Parent',GuiSampleHandle.uiPanelGallery,...
                                        'Position',[0 0 0.98 0.94],...
                                        'BackgroundColor',gui_sample_color);
                                   
% create slider for gallery
GuiSampleHandle.slider = uicontrol('Style','Slider','Parent',GuiSampleHandle.uiPanelGallery,...
                              'Units','normalized','Position',[0.98 0 0.02 0.94],...
                              'Callback',{@slider_callback});
                                    
% compute relative dimension of the thumbnail grid
nbrAvailableRows = 5;
nbrColorChannels = 4; 
nbrImages        = nbrAvailableRows * (nbrColorChannels+1);
maxNumCols       = 5; % design decision, % maxNumCols = 1 (overlay) + nbrChannels

cols  = maxNumCols;
rows  = nbrAvailableRows;

% pitch (box for axis) height and width
rPitch  = 0.98/rows;
cPitch  = 0.98/cols;
% axis height and width
axHight = 0.9/rows;
axWidth = 0.9/cols;

%-----
hAxes   = zeros(nbrImages,1);
hImages = zeros(nbrImages,1);
% define common properties and values for all axes
axesProp = {'dataaspectratio' ,...
            'Parent',...
            'PlotBoxAspectRatio', ...
            'xgrid' ,...
            'ygrid'};
axesVal = {[1,1,1] , ...
           GuiSampleHandle.uiPanelThumbsOuter,...
           [1 1 1]...
           'off',...
           'off'};
% define color pam and include color for contour
map = colormap(parula(maxi+1));
% add color for contour
map(end+1,:) = [1,0,0];

for i=1:rows
    % specify row location for all columns
    y = 1-i*rPitch;
    % plot overlay image in first column
    x = 0;
    ind = (i-1)*(maxNumCols) + 1; % 5,10,15... index for first column element
    hAxes(ind) = axes('Position',[x y axWidth axHight],axesProp,axesVal);
    hImages(ind)= imshow([],'parent',hAxes(ind),'InitialMagnification','fit');
    set(hImages(ind),'ButtonDownFcn',{@openSpecificImage,i});
    % plot image for each color channel in column 2 till nbrChannels
    for ch = 1:nbrColorChannels
        x = (ch)*cPitch;
        ind = ((i-1)*maxNumCols + ch +1); % 1-4,6-9,... index for four color channels
        hAxes(ind) = axes('Position',[x y axWidth axHight],axesProp,axesVal);
        hImages(ind)= imshow([],'parent',hAxes(ind),'InitialMagnification','fit');
        set(hImages(ind),'ButtonDownFcn',{@openSpecificImage,i});
        colormap(hAxes(ind),map);
    end
end
% check if slider is needed     
if  size(currentSample.results.thumbnails,1)>5
    set(GuiSampleHandle.slider,'Max',-3,'Min',-size(currentSample.results.thumbnails,1)+2,...
        'Value',-3,'SliderStep', [1, 1] / (size(currentSample.results.thumbnails,1) - 5));
else
    set(GuiSampleHandle.slider,'enable','off');
end
% only first overlay image per thumbnail can be selected
% hence total number of selectable resp. table rows is 
numberOfThumbs = size(currentSample.results.thumbnails,1);
% note: one thumbnail can have several cells to be measured
GuiSampleHandle.selectedFrames = zeros(numberOfThumbs,1);

% go through all thumbnails (resp. dataframes)
plot_thumbnails(3);


%% Fill uiPanelScatter
%
%replace NaN values with zeros
sampleFeatures = currentSample.results.features;
sampleFeatures_noNaN = sampleFeatures{:,:};
sampleFeatures_noNaN(isnan(sampleFeatures_noNaN)) = 0;
sampleFeatures{:,:} = sampleFeatures_noNaN;

%handle selections
GuiSampleHandle.selectedFrames = false(size(currentSample.results.thumbnails,1),1);
GuiSampleHandle.selectedCells = false(size(sampleFeatures,1),1);
rgbTriple = repmat([0 0 1],[size(sampleFeatures,1),1]);

marker_size = 30;
% create data for scatter plot at the top
GuiSampleHandle.axesTop = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','normalized','Position',[0.17 0.72 0.75 0.23]); %[left bottom width height]
topFeatureIndex1 = 9; topFeatureIndex2 = 17;
gca; GuiSampleHandle.axesScatterTop = scatter(sampleFeatures.(topFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                      sampleFeatures.(topFeatureIndex2+1),marker_size,'filled','CData',rgbTriple);
xlim([0,max(ceil(1.1*max(sampleFeatures.(topFeatureIndex1+1))),1)]); ylim([0,max(ceil(1.1*max(sampleFeatures.(topFeatureIndex2+1))),1)]);
% GuiSampleHandle.pointsTop=get(GuiSampleHandle.axesScatterTop,'Children');
% for i=1:numel(GuiSampleHandle.pointsTop)
% set(GuiSampleHandle.pointsTop(i),'HitTest','on','ButtonDownFcn',@(handle,event,pointNr)click_point(handle,event,i));
% end
% % add callback to single scatter points
% %points=get(GuiSampleHandle.axesScatterTop,'Children');
% %set(points,'HitTest','on','ButtonDownFcn',{@clickScatterPoint});
                                  
% initialize cell counter (scatter elements) in title
set(GuiSampleHandle.uiPanelScatter,'Title',...
    [get(GuiSampleHandle.uiPanelScatter,'Title'),' ',num2str(0),'/',num2str(size(sampleFeatures,1))]);

set(gca,'TickDir','out');
feature_names = cell(size(sampleFeatures.Properties.VariableNames));
feature_names(2:end) = strrep(strrep(strrep(strrep(sampleFeatures.Properties.VariableNames(2:end),'_',' '),'ch 1',currentSample.channelNames(1)),'ch 2',currentSample.channelNames(2)),'ch 3',currentSample.channelNames(3));
if size(currentSample.channelNames,2) > 3
    feature_names(2:end) = strrep(feature_names(2:end),'ch 4',currentSample.channelNames(4));
end
if size(currentSample.channelNames,2) > 4
    feature_names(2:end) = strrep(feature_names(2:end),'ch 5',currentSample.channelNames(5));
end

% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectTopIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',feature_names(2:end),...
            'Position',[0.39 0.675 0.6 0.015],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',topFeatureIndex1,...
            'Callback',{@popupFeatureTopIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectTopIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',feature_names(2:end),...
            'Position',[-0.01 0.975 0.6 0.015],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',topFeatureIndex2,...
            'Callback',{@popupFeatureTopIndex2_Callback});
        % Create push button
GuiSampleHandle.gateScatter1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','normalized','String', 'Gate','Position', [0.255 0.663 0.15 0.03],'Callback', @(handle,event,plotnr)gate_scatter(handle,event,1)); 
GuiSampleHandle.clearScatter = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','normalized','String', 'Clear Selection','Position', [0.67 0.9635 0.3 0.03],'Callback', @clear_selection); 
GuiSampleHandle.selectSingleScatter1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','normalized','String', 'Select Event','Position', [0.01 0.663 0.25 0.03],'Callback', @(handle,event,plotnr)select_event(handle,event,1));         


%----
% create data for scatter plot in the middle
GuiSampleHandle.axesMiddle = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','normalized','Position',[0.17 0.39 0.75 0.23]); %[left bottom width height]
middleFeatureIndex1 = 9; middleFeatureIndex2 = 17;
gca; GuiSampleHandle.axesScatterMiddle = scatter(sampleFeatures.(middleFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                         sampleFeatures.(middleFeatureIndex2+1),marker_size,'filled','CData',rgbTriple);
xlim([0,max(ceil(1.1*max(sampleFeatures.(middleFeatureIndex1+1))),1)]); ylim([0,max(ceil(1.1*max(sampleFeatures.(middleFeatureIndex2+1))),1)]);
set(gca,'TickDir','out');
% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectMiddleIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',feature_names(2:end),...
            'Position',[0.39 0.345 0.6 0.015],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',middleFeatureIndex1,...
            'Callback',{@popupFeatureMiddleIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectMiddleIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',feature_names(2:end),...
            'Position',[-0.01 0.645 0.6 0.015],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',middleFeatureIndex2,...
            'Callback',{@popupFeatureMiddleIndex2_Callback});
% create push button
GuiSampleHandle.gateScatter2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','normalized','String', 'Gate','Position', [0.255 0.333 0.15 0.03],'Callback', @(handle,event,plotnr)gate_scatter(handle,event,2)); 
GuiSampleHandle.selectSingleScatter2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','normalized','String', 'Select Event','Position', [0.01 0.333 0.25 0.03],'Callback', @(handle,event,plotnr)select_event(handle,event,2));         

%----
% create scatter plot at the bottom
GuiSampleHandle.axesBottom = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','normalized','Position',[0.17 0.06 0.75 0.23]); %[left bottom width height]
bottomFeatureIndex1 = 9; bottomFeatureIndex2 = 17;
gca; GuiSampleHandle.axesScatterBottom = scatter(sampleFeatures.(bottomFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                         sampleFeatures.(bottomFeatureIndex2+1),marker_size,'filled','CData',rgbTriple);
xlim([0,max(ceil(1.1*max(sampleFeatures.(bottomFeatureIndex1+1))),1)]); ylim([0,max(ceil(1.1*max(sampleFeatures.(bottomFeatureIndex2+1))),1)]);
set(gca,'TickDir','out');
% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectBottomIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',feature_names(2:end),...
            'Position',[0.39 0.015 0.6 0.015],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',bottomFeatureIndex1,...
            'Callback',{@popupFeatureBottomIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectBottomIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','normalized',...
            'String',feature_names(2:end),...
            'Position',[-0.01 0.315 0.6 0.015],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',bottomFeatureIndex2,...
            'Callback',{@popupFeatureBottomIndex2_Callback});
% create push button
GuiSampleHandle.gateScatter3 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','normalized','String', 'Gate','Position', [0.255 0.003 0.15 0.03],'Callback', @(handle,event,plotnr)gate_scatter(handle,event,3)); 
GuiSampleHandle.selectSingleScatter3 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','normalized','String', 'Select Event','Position', [0.01 0.003 0.25 0.03],'Callback', @(handle,event,plotnr)select_event(handle,event,3));         
        

%% Create export button----
% export gates as manual classification
GuiSampleHandle.export_button = uicontrol('Style', 'pushbutton', 'Units','normalized','String', 'Export Gates','FontUnits', 'normalized',...
            'FontSize',.32,'Position', [0.023 0.925 0.1 0.06],'Callback', {@export_gates}); 
                                
%% Callback and helper functions

% --- Executes on selection in popupChannel.
function popupChannel_callback(hObject,~,~)
    selectedChannel = get(hObject,'Value');
    high=prctile(reshape(currentSample.overviewImage(:,:,selectedChannel),[1,size(currentSample.overviewImage,1)*size(currentSample.overviewImage,2)]),99);
    plotImInAxis(currentSample.overviewImage(:,:,selectedChannel).*(4095/high),[],GuiSampleHandle.axesOverview,GuiSampleHandle.imageOverview);
end

% --- Executes on selection in topFeatureIndex1 (x-axis)
function popupFeatureTopIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterTop,'XData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    xlim(GuiSampleHandle.axesTop,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in topFeatureIndex2 (y-axis)
function popupFeatureTopIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterTop,'YData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    ylim(GuiSampleHandle.axesTop,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in middleFeatureIndex1 (x-axis)
function popupFeatureMiddleIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterMiddle,'XData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    xlim(GuiSampleHandle.axesMiddle,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in middleFeatureIndex2 (y-axis)
function popupFeatureMiddleIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterMiddle,'YData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    ylim(GuiSampleHandle.axesMiddle,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in bottomFeatureIndex1 (x-axis)
function popupFeatureBottomIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterBottom,'XData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    xlim(GuiSampleHandle.axesBottom,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on selection in bottomFeatureIndex2 (y-axis)
function popupFeatureBottomIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterBottom,'YData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
    ylim(GuiSampleHandle.axesBottom,[0,max(ceil(1.1*max(sampleFeatures.(selectedFeature+1))),1)]);
end

% --- Executes on slider movement.
function slider_callback(hObject,~)
    val = round(get(hObject,'Value'));
    plot_thumbnails(-val);
end

% --- Plot thumbnails around index i
function plot_thumbnails(val)
    %numberOfThumbs=size(currentSample.priorLocations,1);
    numberOfThumbs=size(currentSample.results.thumbnails,1);
    thumbIndex=[val-2:1:val+2];
    thumbIndex(thumbIndex<1)=[];
    thumbIndex(thumbIndex>numberOfThumbs)=[];
    if ~isempty(thumbIndex)
        for j=1:numel(thumbIndex)
            thumbInd=thumbIndex(j);
            % obtain dataFrame from io
%             dataFrame = base.io.load_thumbnail_frame(currentSample,thumbInd,'prior');
%             dataFrame = base.io.load_thumbnail_frame(currentSample,thumbInd);
            rawImage = currentSample.results.thumbnail_images{thumbInd};
            segmentedImage = currentSample.results.segmentation{thumbInd};
            k = (j-1)*maxNumCols + 1; % k indicates indices 1,6,11,...
            % plot overlay image in first column
%             plotImInAxis(dataFrame.rawImage,[],hAxes(k),hImages(k));
            plotImInAxis(rawImage,[],hAxes(k),hImages(k));
            
            % update visual selection dependent on selectedFrames array
            if GuiSampleHandle.selectedFrames(thumbInd) == 1
%                 set(hImages(k),'Selected','on');
                set(hAxes(k),'XTick',[]);
                set(hAxes(k),'yTick',[]);
                set(hAxes(k),'XColor',[1.0 0.5 0]);
                set(hAxes(k),'YColor',[1.0 0.5 0]);
                set(hAxes(k),'LineWidth',3);
                set(hAxes(k),'Visible','on');
            else
%                 set(hImages(k),'Selected','off');
                set(hAxes(k),'Visible','off');
            end
            % plot image for each color channel in column 2 till nbrChannels
            for chan = 1:nbrColorChannels
                l = ((j-1)*maxNumCols + chan + 1); 
%                 plotImInAxis(dataFrame.rawImage(:,:,chan),segmentedImage(:,:,chan),hAxes(l),hImages(l));
                plotImInAxis(rawImage(:,:,chan),segmentedImage(:,:,chan),hAxes(l),hImages(l));
            end
        end
    end
end

% --- Helper function used in thumbnail gallery to plot thumbnails in axes
function plotImInAxis(im,segm,hAx,hIm)
    if size(im,3) > 1
        % create overlay image here
        %plot_image(hAx,im,255,'fullscale_rgb');
        overlay(:,:,1) = im(:,:,2)/maxi; overlay(:,:,3) = im(:,:,2)/maxi; overlay(:,:,2) = im(:,:,3)/maxi;
        %can we define Callback function somewhere else??
%         imagesc(overlay,{'ButtonDownFcn'},{'openSpecificImage'},'parent',hAx);
        %imshow(overlay,'parent',hAx,'InitialMagnification','fit'); 
        set(hIm,'CData',overlay);
    else
        %plot_image(hAx,im,255,'fullscale',{'ButtonDownFcn'},{'openSpecificImage(base)'});
%         imagesc(im/maxi,'ButtonDownFcn',{'openSpecificImage'},'parent',hAx);
        %can we define Callback function somewhere else??
        %imshow(im/maxi,'parent',hAx,'InitialMagnification','fit');

        if ~isempty(segm)
            cont = bwperim(segm,4);
            im(im>maxi)= maxi;
            im(cont) = (maxi+1);
        end
        set(hIm,'CData',im/(maxi+1));
    end
    axis(hAx,'image');
end

% --- Helper function used in thumbnail gallery to react on user clicks
function openSpecificImage(handle,~,row)
    type = get(gcf,'SelectionType');
    switch type
        case 'open' % double-click
%             im = get(gcbo,'cdata');
%             figure; imagesc(im,[0,max(max(im(im<1)))]); axis equal; axis off;
        case 'normal' %left mouse button action
            if size(get(gcbo,'cdata'),3) > 1 % only allow selection for first overlay column elements
                if strcmp(get( get(gcbo,'Parent'),'Visible'),'off')
%                     set(gcbo,'Selected','on');
                    surroundingAx = get(gcbo,'Parent');
                    set(surroundingAx,'XTick',[]);
                    set(surroundingAx,'YTick',[]);
                    set(surroundingAx,'XColor',[1.0 0.5 0]);
                    set(surroundingAx,'YColor',[1.0 0.5 0]);
                    set(surroundingAx,'LineWidth',3);
                    set(surroundingAx,'Visible','on');
                    pos = -round(get(GuiSampleHandle.slider,'Value'))-3+row;
                    updateScatterPlots(pos,1);
                else
%                     set(gcbo,'Selected','off');
                    surroundingAx = get(gcbo,'Parent');
                    set(surroundingAx,'Visible','off');
                    pos = -round(get(GuiSampleHandle.slider,'Value'))-3+row;
                    updateScatterPlots(pos,0);
                end
            end
        case 'extend' % shift & left mouse button action
        case 'alt' % alt & left mouse button action
            im = get(gcbo,'cdata');
            figure; imagesc(im,[0,max(max(im(im<1)))]); axis equal; axis off;
    end
end

% --- Helper function to update scatter plots
function updateScatterPlots(pos,booleanOnOff)
    GuiSampleHandle.selectedFrames(pos) = booleanOnOff;
    GuiSampleHandle.selectedCells(sampleFeatures.ThumbNr == pos) = booleanOnOff;
    rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
    rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
    rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
    % update all scatter plots with new manual clustering
    set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
    % update title for scatter panel showing clustering summary
    set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
        num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
end


function gate_scatter(handle,~,plotnr)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    if plotnr == 1
        h = impoly(GuiSampleHandle.axesTop);
        xtest = get(GuiSampleHandle.axesScatterTop,'XData');
        ytest = get(GuiSampleHandle.axesScatterTop,'YData');
    elseif plotnr == 2
        h = impoly(GuiSampleHandle.axesMiddle);
        xtest = get(GuiSampleHandle.axesScatterMiddle,'XData');
        ytest = get(GuiSampleHandle.axesScatterMiddle,'YData');
    else
        h = impoly(GuiSampleHandle.axesBottom);
        xtest = get(GuiSampleHandle.axesScatterBottom,'XData');
        ytest = get(GuiSampleHandle.axesScatterBottom,'YData');
    end
         
    pos = getPosition(h);
    [in,~] = inpolygon(xtest,ytest,pos(:,1),pos(:,2));
    GuiSampleHandle.selectedCells(in) = 1;
    GuiSampleHandle.selectedFrames(sampleFeatures.ThumbNr(in)) = 1; 
    rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
    rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
    rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
    % update all scatter plots with new manual clustering
    set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
    delete(h);
    set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
        num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
    % update view to selected thumbnail closest to current view
    val = round(get(GuiSampleHandle.slider, 'Value'));
    [~, index] = min(abs((-find(GuiSampleHandle.selectedFrames))-val));
    selectedFrames = find(GuiSampleHandle.selectedFrames);
    closestValue = selectedFrames(index(1)); 
    plot_thumbnails(closestValue);
    set(GuiSampleHandle.slider, 'Value',-closestValue);
    set(handle,'backg',color)
end

function clear_selection(~,~)
    GuiSampleHandle.selectedCells = false(size(GuiSampleHandle.selectedCells));
    GuiSampleHandle.selectedFrames = false(size(GuiSampleHandle.selectedFrames));
    rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
    rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
    set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
    set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
    set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
    num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
    val = round(get(GuiSampleHandle.slider, 'Value'));
    plot_thumbnails(-val);
end

function select_event(handle,~,plotnr)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    if plotnr == 1
        h = impoint(GuiSampleHandle.axesTop);
        xtest = get(GuiSampleHandle.axesScatterTop,'XData');
        ytest = get(GuiSampleHandle.axesScatterTop,'YData');
    elseif plotnr == 2
        h = impoint(GuiSampleHandle.axesMiddle);
        xtest = get(GuiSampleHandle.axesScatterMiddle,'XData');
        ytest = get(GuiSampleHandle.axesScatterMiddle,'YData');
    else
        h = impoint(GuiSampleHandle.axesBottom);
        xtest = get(GuiSampleHandle.axesScatterBottom,'XData');
        ytest = get(GuiSampleHandle.axesScatterBottom,'YData');
    end
    pos = getPosition(h);
%     pos_extended = [0.95*pos(1), 0.95*pos(2); 0.95*pos(1), 1.05*pos(2); 1.05*pos(1), 1.05*pos(2); 1.05*pos(1), 0.95*pos(2)];
    pos_extended = [pos(1)-10, pos(2)-10; pos(1)-10, pos(2)+10; pos(1)+10, pos(2)+10; pos(1)+10, pos(2)-10];
    [in,~] = inpolygon(xtest,ytest,pos_extended(:,1),pos_extended(:,2));
    if sum(in) > 1
        indices = find(in);
        [~,index] = min((xtest(in) - pos(1)).^2 + (ytest(in) - pos(2)).^2);
        in(indices(indices ~= indices(index))) = 0;
    end
    if GuiSampleHandle.selectedCells(in) == 0
        GuiSampleHandle.selectedCells(in) = 1;
        GuiSampleHandle.selectedFrames(sampleFeatures.ThumbNr(in)) = 1; 
        rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
        rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
        rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
        % update all scatter plots with new manual clustering
        set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
        delete(h);
        set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
            num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
        % update view to selected thumbnail
        plot_thumbnails(sampleFeatures.ThumbNr(in));
        set(GuiSampleHandle.slider, 'Value',-sampleFeatures.ThumbNr(in));
    else
        GuiSampleHandle.selectedCells(in) = 0;
        if ~isempty(GuiSampleHandle.selectedCells(in)) && isempty(find(sampleFeatures.ThumbNr(GuiSampleHandle.selectedCells) == sampleFeatures.ThumbNr(in), 1))
            GuiSampleHandle.selectedFrames(sampleFeatures.ThumbNr(in)) = 0; 
        end
        rgbTriple(GuiSampleHandle.selectedCells,1) = 1;
        rgbTriple(GuiSampleHandle.selectedCells,2) = 0.5;
        rgbTriple(GuiSampleHandle.selectedCells,3) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,1) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,2) = 0;
        rgbTriple(~GuiSampleHandle.selectedCells,3) = 1;
        % update all scatter plots with new manual clustering
        set(GuiSampleHandle.axesScatterTop,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterMiddle,'CData',rgbTriple);
        set(GuiSampleHandle.axesScatterBottom,'CData',rgbTriple);
        delete(h);
        set(GuiSampleHandle.uiPanelScatter,'Title',['Marker Characterization '...
            num2str(sum(GuiSampleHandle.selectedCells)) '/' num2str(size(sampleFeatures,1))]);
        % update currentview
        val = round(get(GuiSampleHandle.slider, 'Value'));
        plot_thumbnails(-val);
    end
    set(handle,'backg',color)
end

function export_gates(~,~)
    set(0,'defaultUicontrolFontSize', 14)
    exist = true;
    name = inputdlg({''},...
        'Please enter a name for your manual selection.', [1,75],{''},'on');
    classes = currentSample.results.classification.Properties.VariableNames;
    while exist 
        [exist,loc] = ismember(name,classes);
        if exist
            choice = questdlg('There exists a classification with this name. Do you want to overwrite it?', ...
                                    'Error', 'Yes','No','No');
            switch choice
                case 'Yes'
                    currentSample.results.classification(:,loc) = [];
                    exist = false;
                case 'No'
                    name = inputdlg({''},...
                        'Please enter a new name for your manual selection.', [1,75],{''},'on');            
            end
        end
    end
    currentSample.results.classification = [currentSample.results.classification array2table(GuiSampleHandle.selectedCells,'VariableNames',{name{1}})];
    base.io.save_sample(currentSample);
    set(0,'defaultUicontrolFontSize', 12)
end
end