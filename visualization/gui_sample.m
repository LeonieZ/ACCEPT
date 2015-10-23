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
                                     'Position',[0.01 0.2 0.22 0.7],...
                                     'Title','Sample Information','TitlePosition','CenterTop',...
                                     'Units','normalized','BackgroundColor',[1 1 1]);

GuiSampleHandle.tableDetails = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelTable,...
                                  'Units','normalized','Position',[0 0 1 1],...
                                  'String',entry,'FontUnits','normalized', 'FontSize',0.8*(1/size(entry,1)),'BackgroundColor',[1 1 1],'HorizontalAlignment','left','FontName','FixedWidth');
                              
tabExtend = get(GuiSampleHandle.tableDetails,'Extent');
tabPosition = get(GuiSampleHandle.uiPanelTable,'Position');
panelPosition = get(GuiSampleHandle.uiPanelOverview,'Position');
tabPosition(3) = tabExtend(3)./panelPosition(3);
set(GuiSampleHandle.uiPanelTable,'Position',tabPosition);

% create overview image per channel
GuiSampleHandle.axesOverview = axes('Parent',GuiSampleHandle.uiPanelOverview,...
                               'Units','normalized','Position',[tabPosition(1)+tabPosition(3)+0.01 0.07 1-(tabPosition(1)+tabPosition(3)+0.02) 0.82]);
                           
defCh = 2; % default channel for overview when starting the sample visualizer
GuiSampleHandle.imageOverview = imagesc(currentSample.overviewImage(:,:,defCh));
axis image; axis off;

% create choose button to switch color channel
GuiSampleHandle.popupChannel = uicontrol('Style','popup','String',currentSample.channelNames,...
                                    'Units','normalized','Position',[0.4 -0.09 0.08 0.85],...
                                    'FontUnits','normalized','FontSize',0.02,...
                                    'Value',defCh,...
                                    'Callback',{@popupChannel_callback});

                                
%% Fill uiPanelGallery
gui_sample_color = [1 1 1];
if strcmp(currentSample.dataTypeOriginalImage,'uint8')
    maxi = 255;
elseif strcmp(currentSample.dataTypeOriginalImage,'uint12')
    maxi = 4095;
else
    maxi = 65535;
end

% if sc_gui.maxi == 65535 && max(cellfun(@(x)max(max(max(x))),sc_gui.thumbs(1,:))) <= 4095
%     sc_gui.maxi = 4095;
% end

% create column names for gallery
columnTextSize = 0.55;
GuiSampleHandle.textCol1 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.04 0.94 0.1 0.05],...
                                'String','Overlay','HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);
                            
GuiSampleHandle.textCol2 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.25 0.94 0.1 0.05],...
                                'String',currentSample.channelNames{1},'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);

GuiSampleHandle.textCol3 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.45 0.94 0.1 0.05],...
                                'String',currentSample.channelNames{2},'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);

GuiSampleHandle.textCol4 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.64 0.94 0.1 0.05],...
                                'String',currentSample.channelNames{3},'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);
                            
GuiSampleHandle.textCol5 = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','normalized','Position',[0.83 0.94 0.1 0.05],...
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
    end
end
% check if slider is needed     
if  size(currentSample.priorLocations,1)>5
    set(GuiSampleHandle.slider,'Max',-3,'Min',-size(currentSample.priorLocations,1)+2,...
        'Value',-3,'SliderStep', [1, 1] / (size(currentSample.priorLocations,1) - 1));
else
    set(GuiSampleHandle.slider,'enable','off');
end
% only first overlay image per thumbnail can be selected
% hence total number of selectable resp. table rows is 
numberOfThumbs = size(currentSample.priorLocations,1);
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

marker_size = 30;
% create data for scatter plot at the top
axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','normalized','Position',[0.17 0.72 0.75 0.23]); %[left bottom width height]
topFeatureIndex1 = 1; topFeatureIndex2 = 1;
gca; GuiSampleHandle.axesScatterTop = scatter(sampleFeatures.(topFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                      sampleFeatures.(topFeatureIndex2+1),marker_size,'filled');
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
%----
% create data for scatter plot in the middle
axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','normalized','Position',[0.17 0.39 0.75 0.23]); %[left bottom width height]
middleFeatureIndex1 = 2; middleFeatureIndex2 = 2;
gca; GuiSampleHandle.axesScatterMiddle = scatter(sampleFeatures.(middleFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                         sampleFeatures.(middleFeatureIndex2+1),marker_size,'filled');
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
%----
% create scatter plot at the bottom
axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','normalized','Position',[0.17 0.06 0.75 0.23]); %[left bottom width height]
bottomFeatureIndex1 = 3; bottomFeatureIndex2 = 3;
gca; GuiSampleHandle.axesScatterBottom = scatter(sampleFeatures.(bottomFeatureIndex1+1),...    % +1 because first column in feature table is index (thumbNumber)
                                         sampleFeatures.(bottomFeatureIndex2+1),marker_size,'filled');
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


                                
%% Callback and helper functions

% --- Executes on selection in popupChannel.
function popupChannel_callback(hObject,~,~)
    selectedChannel = get(hObject,'Value');
    set(GuiSampleHandle.imageOverview,'CData',currentSample.overviewImage(:,:,selectedChannel));
end

% --- Executes on selection in topFeatureIndex1 (x-axis)
function popupFeatureTopIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterTop,'XData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in topFeatureIndex2 (y-axis)
function popupFeatureTopIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterTop,'YData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in middleFeatureIndex1 (x-axis)
function popupFeatureMiddleIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterMiddle,'XData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in middleFeatureIndex2 (y-axis)
function popupFeatureMiddleIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterMiddle,'YData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in bottomFeatureIndex1 (x-axis)
function popupFeatureBottomIndex1_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterBottom,'XData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on selection in bottomFeatureIndex2 (y-axis)
function popupFeatureBottomIndex2_Callback(hObject,~,~)
    selectedFeature = get(hObject,'Value');
    set(GuiSampleHandle.axesScatterBottom,'YData',sampleFeatures.(selectedFeature+1)); % +1 because first column in feature table is index (thumbNumber)
end

% --- Executes on slider movement.
function slider_callback(hObject,~)
    val = round(get(hObject,'Value'));
    plot_thumbnails(-val);
end

% --- Plot thumbnails around index i
function plot_thumbnails(val)
    numberOfThumbs=size(currentSample.priorLocations,1);
    thumbIndex=[val-2:1:val+2];
    thumbIndex(thumbIndex<1)=[];
    thumbIndex(thumbIndex>numberOfThumbs)=[];
    if ~isempty(thumbIndex)
        for j=1:numel(thumbIndex)
            thumbInd=thumbIndex(j);
            % obtain dataFrame from io
            dataFrame = base.io.load_thumbnail_frame(currentSample,thumbInd,'prior');
            segmentedImage = currentSample.results.segmentation{thumbInd};
            k = (j-1)*maxNumCols + 1; % k indicates indices 1,6,11,...
            % plot overlay image in first column
            plotImInAxis(dataFrame.rawImage,[],hAxes(k),hImages(k), maxi);
            
            % update visual selection dependent on selectedFrames array
            if GuiSampleHandle.selectedFrames(thumbInd) == 1
                set(hImages(k),'Selected','on');
            else
                set(hImages(k),'Selected','off');
            end
            % plot image for each color channel in column 2 till nbrChannels
            for chan = 1:nbrColorChannels
                l = ((j-1)*maxNumCols + chan + 1); 
                plotImInAxis(dataFrame.rawImage(:,:,chan),segmentedImage(:,:,chan),hAxes(l),hImages(l),maxi);
            end
        end
    end
end

% --- Helper function used in thumbnail gallery to plot thumbnails in axes
function plotImInAxis(im,segm,hAx,hIm,maxi)
    maxi = 4095;
    warning('off','MATLAB:contour:ConstantData');
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
        set(hIm,'CData',im/maxi);
        % TODO GUUS
        %if ~isempty(segm)
        %   hold(hAx,'on')
        %   [~,h] = contour(segm,[0.5 0.5],'r-','parent',hAx); set(h,'LineWidth',2);
        %   hold(hAx,'off')
        %end
    end
    axis(hAx,'image');
    % TODO GUUS
    colormap(parula(maxi));
end

% --- Helper function used in thumbnail gallery to react on user clicks
function openSpecificImage(handle,event,row)
    type = get(gcf,'SelectionType');
    switch type
        case 'open' % double-click
            im = get(gcbo,'cdata');
            figure; imagesc(im); colorbar; colormap(gray); axis equal; axis off;
        case 'normal' %left mouse button action
            if size(get(gcbo,'cdata'),3) > 1 % only allow selection for first overlay column elements
                set(gcbo,'Selected','on');
                pos = -round(get(GuiSampleHandle.slider,'Value'))-3+row;
                GuiSampleHandle.selectedFrames(pos) = 1;
                %GuiSampleHandle.selectedFrames
                % TODO CHRISTOPH
                disp(['Scatter plot should be marked with row/thumb ' num2str(pos) ' here'])
            end
        case 'extend' % shift & left mouse button action
        case 'alt' % alt & left mouse button action
    end
end

end