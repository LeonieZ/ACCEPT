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
function GuiSampleHandle = gui_sample(base,currentSample)
% profile on
% Main figure: create and set properies (relative size, color)
set(0,'units','characters');  
screensz = get(0,'screensize');

thumbContainer = ThumbContainer(currentSample);

GuiSampleHandle.fig_main = figure('Units','characters','Position',[(screensz(3)-225)/2 (screensz(4)-65)/2 225 65],'Name','ACCEPT - Automated CTC Classification Enumeration and PhenoTyping','MenuBar','none',...
    'NumberTitle','off','Color',[1 1 1],'Resize','off','CloseRequestFcn',@close_fcn);
gate = struct('gates',cell(0),'name','');
%% Set maximum intensity
if strcmp(currentSample.dataTypeOriginalImage,'uint8')
    maxi = 255;
elseif strcmp(currentSample.dataTypeOriginalImage,'uint12')
    maxi = 4095;
else
%     maxi = 65535;
%     Set maxi to 4095 until uint12 is implemented
    maxi = 4095;
end


nrUsedThumbs = thumbContainer.nrOfEvents;

%replace NaN values with zeros
sampleFeatures = currentSample.results.features;
sampleFeatures_noNaN = sampleFeatures{:,:};
sampleFeatures_noNaN(isnan(sampleFeatures_noNaN)) = 0;
sampleFeatures{:,:} = sampleFeatures_noNaN; 
%handle selections
currPos = linspace(1,nrUsedThumbs,nrUsedThumbs);
selectedCells = zeros(nrUsedThumbs,1);


zoom_factor_x(1:3) = 1.1;
zoom_factor_y(1:3) = 1.1;
%% Main title
GuiSampleHandle.title_axes = axes('Units','characters','Position',[110 61.8 39.6 2.6]); axis off;
GuiSampleHandle.title = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} Sample Visualizer','FontUnits','normalized','FontSize',0.8,'verticalAlignment','base','horizontalAlignment','center');


%% Main panels
% create panel for overview (top-left)
GuiSampleHandle.uiPanelOverview = uipanel('Parent',GuiSampleHandle.fig_main,...
                                     'Units','characters','Position',[5.1 45.6 151.6 15.5],...
                                     'Title','Overview','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.1,...
                                     'BackgroundColor',[1 1 1]);

% create panel for thumbnail gallery (bottom-left)
GuiSampleHandle.uiPanelGallery = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Units','characters','Position',[5.1 1.3 151.6 42.1],...
                                     'Title','Cell Gallery','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.033,...
                                     'BackgroundColor',[1 1 1]);

% create panel for scatter plots (right)
GuiSampleHandle.uiPanelScatter = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Units','characters','Position',[160.8 1.3 58.9 59.7],...
                                     'Title','Selected Events','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.023,...
                                     'BackgroundColor',[1 1 1]);

                                 
%% Fill uiPanelOverview
% create table with sample properties as overview
propnames = properties(currentSample);
selectedProps = [1,2,5,6,10]; % properties of data sample to be visualized
propnames = propnames(selectedProps); % row titles
dat = cell(numel(propnames),1);
entry = cell(numel(propnames),1);
rnames = {'Sample ID','Type','Nr of Frames', 'Nr of Channels', 'Pixel Size','Nr of Scored Events', 'Size Scale Bar'};
for i = 1:numel(propnames)
   dat{i} = eval(['currentSample.',propnames{i}]);
   entry{i} = [rnames{i}, ': ',num2str(dat{i})];
end

dat{6} = size(currentSample.results.features,1);
entry{6} = [rnames{6}, ': ',num2str(dat{6})];

dat{7} = 10*currentSample.pixelSize;
entry{7} = [rnames{7}, ': ',num2str(dat{7})];

GuiSampleHandle.uiPanelTable = uipanel('Parent',GuiSampleHandle.uiPanelOverview,...
                                     'Units','characters','Position',[1.5 1.4 42 12],...
                                     'Title','Sample Information','TitlePosition','CenterTop',...
                                     'BackgroundColor',[1 1 1]);
                                      
GuiSampleHandle.tableDetails = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelTable,...
                                  'Units','characters','Position',[0.2 .5 41.8 9],...
                                  'String',entry,'FontUnits','normalized', 'FontSize',0.11,'BackgroundColor',[1 1 1],'HorizontalAlignment','left','FontName','FixedWidth');

tabPosition = get(GuiSampleHandle.uiPanelTable,'Position');


if ~isempty(thumbContainer.overviewImage) 
    % % create overview image per channel
     GuiSampleHandle.axesOverview = axes('Parent',GuiSampleHandle.uiPanelOverview,...
                                    'Units','characters','Position',[tabPosition(1)+tabPosition(3)+1.5 1 151.6-(tabPosition(1)+tabPosition(3)+3) 12.7]);
    %                            
     defCh = 2; % default channel for overview when starting the sample visualizer

     blank=zeros(size(thumbContainer.overviewImage(:,:,defCh)));
     GuiSampleHandle.imageOverview = imshow(blank,'parent',GuiSampleHandle.axesOverview,'InitialMagnification','fit');
     colormap(GuiSampleHandle.axesOverview,parula(4096));
     high=prctile(reshape(thumbContainer.overviewImage(:,:,defCh),[1,size(thumbContainer.overviewImage,1)*size(thumbContainer.overviewImage,2)]),99);
     plotImInAxis(thumbContainer.overviewImage(:,:,defCh).*(4095/high),[],GuiSampleHandle.axesOverview,GuiSampleHandle.imageOverview);


    % % create choose button to switch color channel
     GuiSampleHandle.popupChannel = uicontrol('Style','popup','String',currentSample.channelNames,...
                                         'Units','characters','Position',[88 40 17.6 8.7],...
                                         'FontUnits','normalized','FontSize',0.12,...
                                         'Value',defCh,...
                                         'Callback',{@popupChannel_callback});
end

                                
%% Fill uiPanelGallery
gui_sample_color = [1 1 1];
three_channel_overlay = true;


% create column names for gallery
columnTextSize = 0.68;
                       
% create panel for thumbnails next to slider                          
GuiSampleHandle.uiPanelThumbsOuter = uipanel('Parent',GuiSampleHandle.uiPanelGallery,...
                                        'Units','characters','Position',[0 0 147 38.3],...
                                        'BackgroundColor',gui_sample_color);
                                   
% create slider for gallery
GuiSampleHandle.slider = uicontrol('Style','Slider','Parent',GuiSampleHandle.uiPanelGallery,...
                              'Units','characters','Position',[147.3 0 3 38.3],...
                              'Callback',{@slider_callback});
                                    
% compute relative dimension of the thumbnail grid
nbrAvailableRows = 5;
nbrColorChannels = currentSample.nrOfChannels; 
nbrImages        = nbrAvailableRows * (nbrColorChannels+1);
maxNumCols       = 7; % design decision, % maxNumCols = 1 (overlay) + nbrChannels                            
cols  = min(maxNumCols,nbrColorChannels+1);
rows  = nbrAvailableRows;
space = (144.1 - cols *15.1)/(2*cols);
for i = 1:cols
    if i == 1
        GuiSampleHandle.textCol(i) = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                    'Units','characters','Position',[space 38.5 15.1 1.7],...
                                    'String','Overlay','HorizontalAlignment','center',...
                                    'FontUnits', 'normalized','FontSize',columnTextSize,...
                                    'BackgroundColor',gui_sample_color);
    else
        GuiSampleHandle.textCol(i) = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                    'Units','characters','Position',[(2*(i-1)+1)*space+(i-1)*15.1 38.5 15.1 1.7],...
                                    'String',currentSample.channelNames{i-1},'HorizontalAlignment','center',...
                                    'FontUnits', 'normalized','FontSize',columnTextSize,...
                                    'BackgroundColor',gui_sample_color);
    end
end

% pitch (box for axis) height and width
rPitch  = 37/rows;
cPitch  = 144.1/cols;
% axis height and width
axHeight = 34.4/rows;
axWidth = 132.3/cols;

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
    y = 37.8-i*rPitch;
    % plot overlay image in first column
    x = 0;
    ind = (i-1)*(cols) + 1; % 5,10,15... index for first column element
    hAxes(ind) = axes(axesProp,axesVal,'Units','characters','Position',[x y axWidth axHeight]);
    hImages(ind)= imshow([],'parent',hAxes(ind),'InitialMagnification','fit');
    set(hImages(ind),'ButtonDownFcn',{@openSpecificImage,i});
    % plot image for each color channel in column 2 till nbrChannels
    for ch = 1:cols-1
        x = (ch)*cPitch;
        ind = ((i-1)*cols + ch +1); % 1-4,6-9,... index for four color channels
        hAxes(ind) = axes(axesProp,axesVal,'Units','characters','Position',[x y axWidth axHeight]);
        hImages(ind)= imshow([],'parent',hAxes(ind),'InitialMagnification','fit');
        set(hImages(ind),'ButtonDownFcn',{@openSpecificImage,i});
        colormap(hAxes(ind),map);
    end
end
% check if slider is needed     
if  nrUsedThumbs>5
    set(GuiSampleHandle.slider,'Max',-3,'Min',-nrUsedThumbs+2,...
        'Value',-3,'SliderStep', [1, 1] / (nrUsedThumbs - 5));
else
    set(GuiSampleHandle.slider,'Max',-3,'Min',-3,'enable','off','Value',-3);
end

GuiSampleHandle.sortButton = uicontrol('Parent',GuiSampleHandle.fig_main, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.55,'String', 'Selected cells to top.','Position', [130.7 43.45 26 1.65],'Callback', @sort_cells); 
GuiSampleHandle.resortButton = uicontrol('Parent',GuiSampleHandle.fig_main, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.55,'String', 'Original sorting.','Position', [108 43.45 22 1.65],'Callback', @resort_cells); 
 
GuiSampleHandle.OverlayButtonTxT = uicontrol('Parent',GuiSampleHandle.fig_main,'Style','text','Units','characters','FontUnits', 'normalized',...
            'FontSize',0.55,'Position',[5.1 43.35 22 1.65],'BackgroundColor',[ 1 1 1],'String','3 Channel Overlay');
GuiSampleHandle.changeOverlayButton = uicontrol('Parent',GuiSampleHandle.fig_main, 'Style', 'checkbox', 'Units','characters',...
            'Value',1,'Position', [27.4 43.35 5 1.65],'BackgroundColor',[ 1 1 1],'Callback', @change_overlay); 

% go through all thumbnails (resp. dataframes)
plot_thumbnails(3);



%% Fill uiPanelScatter

marker_size = 10;
GuiSampleHandle.marker_size_control = uicontrol('Style','edit','Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[52 53.7 5 2],'String',num2str(marker_size),'HorizontalAlignment','center',...
                            'FontUnits', 'normalized','FontSize',0.55,'BackgroundColor',[ 1 1 1],'Callback',@change_marker_size);

% create data for scatter plot at the top
GuiSampleHandle.axesTop = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[11.2 42.2 40.4 13.1]); %[left bottom width height]
GuiSampleHandle.axesTop.YAxis.Exponent = 0;
GuiSampleHandle.axesTop.XAxis.Exponent = 0;

topFeatureIndex1 = find(cellfun(@(s) ~isempty(strfind('ch_3_MeanIntensity', s)), sampleFeatures.Properties.VariableNames));
topFeatureIndex2 = find(cellfun(@(s) ~isempty(strfind('ch_2_MeanIntensity', s)), sampleFeatures.Properties.VariableNames));

XData = sampleFeatures.(topFeatureIndex1);
YData = sampleFeatures.(topFeatureIndex2);    
    
index = find(~isnan(XData+YData+selectedCells));
if mod(length(index),2) == 1
    index(end+1) = index(end);
end
if length(index) == 2
    index(end+1:end+2) = index(1:2);
end
index = reshape(index,2,[]);

GuiSampleHandle.axesScatterTop = mesh(GuiSampleHandle.axesTop,XData(index),YData(index),zeros(size(index)),'CData',selectedCells(index),'Marker','.','EdgeColor','none','MarkerEdgeColor','flat','FaceColor','none','MarkerSize', marker_size);
view(2); colormap([0.65 0.65 0.65]);
% xlim([0,max(ceil(zoom_factor_x(1)*max(sampleFeatures.(topFeatureIndex1))),1)]); ylim([0,max(ceil(zoom_factor_y(1)*max(sampleFeatures.(topFeatureIndex2))),1)]);
xlim([0,max(zoom_factor_x(1)*max(sampleFeatures.(topFeatureIndex1)),1)]); ylim([0,max(zoom_factor_y(1)*max(sampleFeatures.(topFeatureIndex2)),1)]);
                                  
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
GuiSampleHandle.popupFeatureSelectTopIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[25 39.5 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',topFeatureIndex1-1,...
            'Callback',{@popupFeatureTopIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectTopIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[1.5 56.9 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',topFeatureIndex2-1,...
            'Callback',{@popupFeatureTopIndex2_Callback});
        % Create push button
GuiSampleHandle.gateScatter1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Gate','Position', [15.5 38.6 8.1 1.8],'Callback', @(handle,event,plotnr)gate_scatter(handle,event,1)); 
GuiSampleHandle.clearScatter = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Clear Selection','Position', [41.1 56 16.2 1.8],'Callback', @clear_selection); 
GuiSampleHandle.selectSingleScatter1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Select Event','Position', [1.5 38.6 13.5 1.8],'Callback', @(handle,event,plotnr)select_event(handle,event,1));  
GuiSampleHandle.zoomIn1_x = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '+','Position', [53 43.5 3 1],'Callback', @(handle,event,plotnr,axis)zoom_in(handle,event,1,'x')); 
GuiSampleHandle.zoomOut1_x = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '-','Position', [53 42.2 3 1],'Callback', @(handle,event,plotnr,axis)zoom_out(handle,event,1,'x')); 
GuiSampleHandle.zoomIn1_y = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '+','Position', [0.25 54.3 3 1],'Callback', @(handle,event,plotnr,axis)zoom_in(handle,event,1,'y')); 
GuiSampleHandle.zoomOut1_y = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '-','Position', [0.25 53 3 1],'Callback', @(handle,event,plotnr,axis)zoom_out(handle,event,1,'y'));


%----
% create data for scatter plot in the middle
GuiSampleHandle.axesMiddle = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[11.2 23 40.4 13.1]); %[left bottom width height]
GuiSampleHandle.axesMiddle.YAxis.Exponent = 0;
GuiSampleHandle.axesMiddle.XAxis.Exponent = 0;
middleFeatureIndex1 = find(cellfun(@(s) ~isempty(strfind('ch_3_MeanIntensity', s)), sampleFeatures.Properties.VariableNames));
middleFeatureIndex2 = find(cellfun(@(s) ~isempty(strfind('ch_1_MeanIntensity', s)), sampleFeatures.Properties.VariableNames));

XData = sampleFeatures.(middleFeatureIndex1);
YData = sampleFeatures.(middleFeatureIndex2);    
    
index = find(~isnan(XData+YData+selectedCells));
if mod(length(index),2) == 1
    index(end+1) = index(end);
end
if length(index) == 2
    index(end+1:end+2) = index(1:2);
end
index = reshape(index,2,[]);

GuiSampleHandle.axesScatterMiddle = mesh(GuiSampleHandle.axesMiddle,XData(index),YData(index),zeros(size(index)),'CData',selectedCells(index),'Marker','.','EdgeColor','none','MarkerEdgeColor','flat','FaceColor','none','MarkerSize', marker_size);
view(2); colormap([0.65 0.65 0.65]);
% xlim([0,max(ceil(zoom_factor_x(2)*max(sampleFeatures.(middleFeatureIndex1))),1)]); ylim([0,max(ceil(zoom_factor_y(2)*max(sampleFeatures.(middleFeatureIndex2))),1)]);
xlim([0,max(zoom_factor_x(2)*max(sampleFeatures.(middleFeatureIndex1)),1)]); ylim([0,max(zoom_factor_y(2)*max(sampleFeatures.(middleFeatureIndex2)),1)]);

set(gca,'TickDir','out');
% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectMiddleIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[25 20.2 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',middleFeatureIndex1-1,...
            'Callback',{@popupFeatureMiddleIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectMiddleIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[1.5 37.7 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',middleFeatureIndex2-1,...
            'Callback',{@popupFeatureMiddleIndex2_Callback});
% create push button
GuiSampleHandle.gateScatter2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Gate','Position', [15.5 19.3 8.1 1.8],'Callback', @(handle,event,plotnr)gate_scatter(handle,event,2)); 
GuiSampleHandle.selectSingleScatter2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Select Event','Position', [1.5 19.3 13.5 1.8],'Callback', @(handle,event,plotnr)select_event(handle,event,2)); 
GuiSampleHandle.zoomIn2_x = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '+','Position', [53 24.3 3 1],'Callback', @(handle,event,plotnr,axis)zoom_in(handle,event,2,'x')); 
GuiSampleHandle.zoomOut2_x = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '-','Position', [53 23 3 1],'Callback', @(handle,event,plotnr,axis)zoom_out(handle,event,2,'x')); 
GuiSampleHandle.zoomIn2_y = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '+','Position', [0.25 35.1 3 1],'Callback', @(handle,event,plotnr,axis)zoom_in(handle,event,2,'y')); 
GuiSampleHandle.zoomOut2_y = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '-','Position', [0.25 33.8 3 1],'Callback', @(handle,event,plotnr,axis)zoom_out(handle,event,2,'y'));

%----
% create scatter plot at the bottom
GuiSampleHandle.axesBottom = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[11.2 3.7 40.4 13.1]); %[left bottom width height]
GuiSampleHandle.axesBottom.YAxis.Exponent = 0;
GuiSampleHandle.axesBottom.XAxis.Exponent = 0;
bottomFeatureIndex1 = find(cellfun(@(s) ~isempty(strfind('ch_3_MeanIntensity', s)), sampleFeatures.Properties.VariableNames));
bottomFeatureIndex2 = find(cellfun(@(s) ~isempty(strfind('ch_4_MeanIntensity', s)), sampleFeatures.Properties.VariableNames));
if isempty(bottomFeatureIndex2)
    bottomFeatureIndex2 = find(cellfun(@(s) ~isempty(strfind('ch_3_Size', s)), sampleFeatures.Properties.VariableNames));
end

XData = sampleFeatures.(bottomFeatureIndex1);
YData = sampleFeatures.(bottomFeatureIndex2);    
    
index = find(~isnan(XData+YData+selectedCells));
if mod(length(index),2) == 1
    index(end+1) = index(end);
end
if length(index) == 2
    index(end+1:end+2) = index(1:2);
end
index = reshape(index,2,[]);

GuiSampleHandle.axesScatterBottom = mesh(GuiSampleHandle.axesBottom,XData(index),YData(index),zeros(size(index)),'CData',selectedCells(index),'Marker','.','EdgeColor','none','MarkerEdgeColor','flat','FaceColor','none','MarkerSize', marker_size);
view(2); colormap([0.65 0.65 0.65]); %colormap([0 0 1]); 
% xlim([0,max(ceil(zoom_factor_x(3)*max(sampleFeatures.(bottomFeatureIndex1))),1)]); ylim([0,max(ceil(zoom_factor_y(3)*max(sampleFeatures.(bottomFeatureIndex2))),1)]);
xlim([0,max(zoom_factor_x(3)*max(sampleFeatures.(bottomFeatureIndex1)),1)]); ylim([0,max(zoom_factor_y(3)*max(sampleFeatures.(bottomFeatureIndex2)),1)]);

set(gca,'TickDir','out');
% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectBottomIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[25 1.0 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',bottomFeatureIndex1-1,...
            'Callback',{@popupFeatureBottomIndex1_Callback});
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectBottomIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','popup','Units','characters',...
            'String',feature_names(2:end),...
            'Position',[1.5 18.4 32.3 0.9],...
            'FontUnits', 'normalized',...
            'FontSize',1,...
            'Value',bottomFeatureIndex2-1,...
            'Callback',{@popupFeatureBottomIndex2_Callback});
% create push button
GuiSampleHandle.gateScatter3 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4, 'String', 'Gate','Position', [15.5 0.1 8.1 1.8],'Callback', @(handle,event,plotnr)gate_scatter(handle,event,3)); 
GuiSampleHandle.selectSingleScatter3 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.4,'String', 'Select Event','Position', [1.5 0.1 13.5 1.8],'Callback', @(handle,event,plotnr)select_event(handle,event,3));   
GuiSampleHandle.zoomIn3_x = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '+','Position', [53 5 3 1],'Callback', @(handle,event,plotnr,axis)zoom_in(handle,event,3,'x')); 
GuiSampleHandle.zoomOut3_x = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '-','Position', [53 3.7 3 1],'Callback', @(handle,event,plotnr,axis)zoom_out(handle,event,3,'x')); 
GuiSampleHandle.zoomIn3_y = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '+','Position', [0.25 15.8 3 1],'Callback', @(handle,event,plotnr,axis)zoom_in(handle,event,3,'y')); 
GuiSampleHandle.zoomOut3_y = uicontrol('Parent',GuiSampleHandle.uiPanelScatter, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8, 'String', '-','Position', [0.25 14.5 3 1],'Callback', @(handle,event,plotnr,axis)zoom_out(handle,event,3,'y'));
        

%% Create export/load buttons----
% export gates as manual classification
GuiSampleHandle.export_button = uicontrol('Style', 'pushbutton', 'Units','characters','String', 'Export Selection','FontUnits', 'normalized',...
            'FontSize',.5,'Position', [5.1 61.2 27.5 2.6],'Callback', {@export_selection}); 
        
% design manual classification
GuiSampleHandle.multiplegates_button = uicontrol('Style', 'pushbutton', 'Units','characters','String', 'Multiple Gates','FontUnits', 'normalized',...
            'FontSize',.5,'Position', [158.8 61.2 27.5 2.6],'Callback', {@design_manual_classifier}); 
        
% load gates as manual classification
GuiSampleHandle.load_button = uicontrol('Style', 'pushbutton', 'Units','characters','String', 'Load Selection','FontUnits', 'normalized',...
            'FontSize',.5,'Position', [33 61.2 26.4 2.6],'Callback', {@load_selection}); 
        
% export thumbnails
GuiSampleHandle.export_thumbs = uicontrol('Style', 'pushbutton', 'Units','characters','String', 'Export Thumbnails','FontUnits', 'normalized',...
            'FontSize',.5,'Position', [186.7 61.2 33 2.6],'Callback', {@export_thumbs}); 
        
% set keyboard scrolling function
set(GuiSampleHandle.fig_main, 'KeyPressFcn', @key_Pressed_Callback);
        
%% Callback and helper functions

% --- Executes on selection in popupChannel.
function popupChannel_callback(hObject,~,~)
    selectedChannel = get(hObject,'Value');
    high=prctile(reshape(thumbContainer.overviewImage(:,:,selectedChannel),[1,size(thumbContainer.overviewImage,1)*size(thumbContainer.overviewImage,2)]),99);
    plotImInAxis(thumbContainer.overviewImage(:,:,selectedChannel).*(4095/high),[],GuiSampleHandle.axesOverview,GuiSampleHandle.imageOverview);
end

% --- Executes on selection in topFeatureIndex1 (x-axis)
function popupFeatureTopIndex1_Callback(hObject,~,~)
    topFeatureIndex1 = get(hObject,'Value') + 1; % +1 because first column in feature table is index (thumbNumber)
    newXData = sampleFeatures.(topFeatureIndex1);
    index = find(~isnan(newXData));
    if mod(length(index),2) == 1
        index(end+1) = index(end);
    end
    if length(index) == 2
        index(end+1:end+2) = index(1:2);
    end
    index = reshape(index,2,[]);
    zoom_factor_x(1) = 1.1;
    set(GuiSampleHandle.axesScatterTop,'XData',newXData(index)); 
%     xlim(GuiSampleHandle.axesTop,[0,max(ceil(zoom_factor_x(1)*max(sampleFeatures.(topFeatureIndex1))),1)]);  
    xlim(GuiSampleHandle.axesTop,[0,max(zoom_factor_x(1)*max(sampleFeatures.(topFeatureIndex1)),1)]);
    GuiSampleHandle.axesTop.XAxis.Exponent = 0;
end

% --- Executes on selection in topFeatureIndex2 (y-axis)
function popupFeatureTopIndex2_Callback(hObject,~,~)
    topFeatureIndex2 = get(hObject,'Value') + 1; % +1 because first column in feature table is index (thumbNumber)
    newYData = sampleFeatures.(topFeatureIndex2);
    index = find(~isnan(newYData));
    if mod(length(index),2) == 1
        index(end+1) = index(end);
    end
    if length(index) == 2
        index(end+1:end+2) = index(1:2);
    end
    index = reshape(index,2,[]);
    zoom_factor_y(1) = 1.1;
    set(GuiSampleHandle.axesScatterTop,'YData',newYData(index)); 
%     ylim(GuiSampleHandle.axesTop,[0,max(ceil(zoom_factor_y(1)*max(sampleFeatures.(topFeatureIndex2))),1)]);  
    ylim(GuiSampleHandle.axesTop,[0,max(zoom_factor_y(1)*max(sampleFeatures.(topFeatureIndex2)),1)]);
    GuiSampleHandle.axesTop.YAxis.Exponent = 0;
end

% --- Executes on selection in middleFeatureIndex1 (x-axis)
function popupFeatureMiddleIndex1_Callback(hObject,~,~)
    middleFeatureIndex1 = get(hObject,'Value') + 1; % +1 because first column in feature table is index (thumbNumber)
    newXData = sampleFeatures.(middleFeatureIndex1);
    index = find(~isnan(newXData));
    if mod(length(index),2) == 1
        index(end+1) = index(end);
    end
    if length(index) == 2
        index(end+1:end+2) = index(1:2);
    end
    index = reshape(index,2,[]);
    zoom_factor_x(2) = 1.1;
    set(GuiSampleHandle.axesScatterMiddle,'XData',newXData(index)); 
%     xlim(GuiSampleHandle.axesMiddle,[0,max(ceil(zoom_factor_x(2)*max(sampleFeatures.(middleFeatureIndex1))),1)]); 
    xlim(GuiSampleHandle.axesMiddle,[0,max(zoom_factor_x(2)*max(sampleFeatures.(middleFeatureIndex1)),1)]);
    GuiSampleHandle.axesMiddle.XAxis.Exponent = 0;
end

% --- Executes on selection in middleFeatureIndex2 (y-axis)
function popupFeatureMiddleIndex2_Callback(hObject,~,~)
    middleFeatureIndex2 = get(hObject,'Value') + 1; % +1 because first column in feature table is index (thumbNumber)
    newYData = sampleFeatures.(middleFeatureIndex2); 
    index = find(~isnan(newYData));
    if mod(length(index),2) == 1
        index(end+1) = index(end);
    end
    if length(index) == 2
        index(end+1:end+2) = index(1:2);
    end
    index = reshape(index,2,[]);
    zoom_factor_y(2) = 1.1;
    set(GuiSampleHandle.axesScatterMiddle,'YData',newYData(index)); 
%     ylim(GuiSampleHandle.axesMiddle,[0,max(ceil(zoom_factor_y(2)*max(sampleFeatures.(middleFeatureIndex2))),1)]);  
    ylim(GuiSampleHandle.axesMiddle,[0,max(zoom_factor_y(2)*max(sampleFeatures.(middleFeatureIndex2)),1)]); 
    GuiSampleHandle.axesMiddle.YAxis.Exponent = 0;
end

% --- Executes on selection in bottomFeatureIndex1 (x-axis)
function popupFeatureBottomIndex1_Callback(hObject,~,~)
    bottomFeatureIndex1 = get(hObject,'Value') + 1; % +1 because first column in feature table is index (thumbNumber)
    newXData = sampleFeatures.(bottomFeatureIndex1); 
    index = find(~isnan(newXData));
    if mod(length(index),2) == 1
        index(end+1) = index(end);
    end
    if length(index) == 2
        index(end+1:end+2) = index(1:2);
    end
    index = reshape(index,2,[]);
    zoom_factor_x(3) = 1.1;
    set(GuiSampleHandle.axesScatterBottom,'XData',newXData(index)); 
%     xlim(GuiSampleHandle.axesBottom,[0,max(ceil(zoom_factor_x(3)*max(sampleFeatures.(bottomFeatureIndex1))),1)]);
    xlim(GuiSampleHandle.axesBottom,[0,max(zoom_factor_x(3)*max(sampleFeatures.(bottomFeatureIndex1)),1)]);
    GuiSampleHandle.axesBottom.XAxis.Exponent = 0;
end

% --- Executes on selection in bottomFeatureIndex2 (y-axis)
function popupFeatureBottomIndex2_Callback(hObject,~,~)
    bottomFeatureIndex2 = get(hObject,'Value') + 1; % +1 because first column in feature table is index (thumbNumber)
    newYData = sampleFeatures.(bottomFeatureIndex2); 
    index = find(~isnan(newYData));
    if mod(length(index),2) == 1
        index(end+1) = index(end);
    end
    if length(index) == 2
        index(end+1:end+2) = index(1:2);
    end
    index = reshape(index,2,[]);
    zoom_factor_y(3) = 1.1;
    set(GuiSampleHandle.axesScatterBottom,'YData',newYData(index)); 
%     ylim(GuiSampleHandle.axesBottom,[0,max(ceil(zoom_factor_y(3)*max(sampleFeatures.(bottomFeatureIndex2))),1)]); 
    ylim(GuiSampleHandle.axesBottom,[0,max(zoom_factor_y(3)*max(sampleFeatures.(bottomFeatureIndex2)),1)]); 
    GuiSampleHandle.axesBottom.YAxis.Exponent = 0;
end

% --- Executes on slider movement.
function slider_callback(hObject,~)
    val = round(get(hObject,'Value'));
    plot_thumbnails(-val);
end

% --- Plot thumbnails around index i
function plot_thumbnails(val)
    %numberOfThumbs=size(currentSample.priorLocations,1);
    thumbIndex=[val-2:1:val+2];
    thumbIndex(thumbIndex<1)=[];
    thumbIndex(thumbIndex>nrUsedThumbs)=[];
    if ~isempty(thumbIndex)
        for j=1:numel(thumbIndex)
            thumbInd=thumbIndex(j);
            rawImage = thumbContainer.thumbnails{(currPos(thumbInd))};
            label = currentSample.results.thumbnails.label((currPos(thumbInd)));
            if ~isa(base.sampleProcessor,'Marker_Characterization')
                segmentedImage = thumbContainer.labelFullImage{(currPos(thumbInd))} == label;
            else 
                segmentedImage = thumbContainer.labelThumbImage{(currPos(thumbInd))} == label;
            end
            k = (j-1)*cols + 1; % k indicates indices 1,6,11,...
            % plot overlay image in first column
            plotImInAxis(rawImage,segmentedImage,hAxes(k),hImages(k));
            
            % update visual selection dependent on selectedFrames array
%             if selectedFrames(thumbInd) == 1
            if selectedCells(currPos(thumbInd)) == 1
%                 set(hImages(k),'Selected','on');
                set(hAxes(k),'XTick',[]);
                set(hAxes(k),'yTick',[]);
                set(hAxes(k),'XColor',[0 0 1]);
                set(hAxes(k),'YColor',[0 0 1]);
                set(hAxes(k),'LineWidth',3);
                set(hAxes(k),'Visible','on');
            else
%                 set(hImages(k),'Selected','off');
                set(hAxes(k),'Visible','off');
            end
            % plot image for each color channel in column 2 till nbrChannels
            for chan = 1:cols-1
                l = ((j-1)*cols + chan + 1);
                plotImInAxis(rawImage(:,:,chan),segmentedImage(:,:,chan),hAxes(l),hImages(l));
            end
        end
    end
end

% --- Helper function used in thumbnail gallery to plot thumbnails in axes
function plotImInAxis(im,segm,hAx,hIm)
    if size(im,3) > 1
        if sum(sum(segm(:,:,2))) > 1
            max_ch2 = max(max(im(:,:,2)));
        else 
            max_ch2 = maxi;
        end

        if sum(sum(segm(:,:,3))) > 1
            max_ch3 = max(max(im(:,:,3)));
        else 
            max_ch3 = maxi;
        end
        
        if sum(sum(segm(:,:,1))) > 1
            max_ch1 = max(max(im(:,:,1)));
        else 
            max_ch1 = maxi;
        end
        % create overlay image here
        if three_channel_overlay == false
            overlay(:,:,1) = im(:,:,2)/max_ch2; overlay(:,:,3) = im(:,:,2)/max_ch2; overlay(:,:,2) = im(:,:,3)/max_ch3;
            overlay(end-1,2:min(11,end),:) = 1;
        else
            overlay(:,:,1) = im(:,:,1)/max_ch1; overlay(:,:,3) = im(:,:,2)/max_ch2; overlay(:,:,2) = im(:,:,3)/max_ch3;
            overlay(end-1,2:min(11,end),:) = 1;
        end            
        set(hIm,'CData',overlay);
    else
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
function openSpecificImage(~,~,row)
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
                    set(surroundingAx,'XColor',[0 0 1]);
                    set(surroundingAx,'YColor',[0 0 1]);
                    set(surroundingAx,'LineWidth',3);
                    set(surroundingAx,'Visible','on');
                    pos = max(1,-round(get(GuiSampleHandle.slider,'Value'))-3+row);
                    updateScatterPlots(currPos(pos),1);
                else
%                     set(gcbo,'Selected','off');
                    surroundingAx = get(gcbo,'Parent');
                    set(surroundingAx,'Visible','off');
                    pos = max(-round(get(GuiSampleHandle.slider,'Value'))-3+row,1);
                    updateScatterPlots(currPos(pos),0);
                end
            end
        case 'alt' % right mouse button action
            im = get(gcbo,'cdata');
            true_max_int = max(im(im~=1));
            im_new = (im / true_max_int) .* double(im~=1) + 1.002 * double(im==1);
            figure; imagesc(im_new,[0,1.002]); axis equal; axis off;
            colormap(gca,map);
    end
end

function key_Pressed_Callback(handle,event,~)
    if(strcmp(event.Key, 'space'))
        plot_thumbnails(-round(GuiSampleHandle.slider.Value)+5);
        GuiSampleHandle.slider.Value=round(GuiSampleHandle.slider.Value)-5;
    end
 end

% --- Helper function to update scatter plots
function updateScatterPlots(pos,booleanOnOff)
%     selectedFrames(pos) = booleanOnOff;
    selectedCells(pos) = booleanOnOff;

    % update all scatter plots with new manual clustering
    set(GuiSampleHandle.axesScatterTop,'CData',selectedCells(index));
    set(GuiSampleHandle.axesScatterMiddle,'CData',selectedCells(index));
    set(GuiSampleHandle.axesScatterBottom,'CData',selectedCells(index));
    if sum(selectedCells) > 0
        colormap([0.65 0.65 0.65; 0 0 1]);
    else
        colormap([0.65 0.65 0.65]);
    end
    % update title for scatter panel showing clustering summary
    set(GuiSampleHandle.uiPanelScatter,'Title',['Selected Events '...
        num2str(sum(selectedCells)) '/' num2str(size(sampleFeatures,1))]);
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
    selectedCells(in) = 1;
%     selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(in))) = 1;
%     selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(unique(index(in))))) = 1;
    % update all scatter plots with new manual clustering
    set(GuiSampleHandle.axesScatterTop,'CData',selectedCells(index));
    set(GuiSampleHandle.axesScatterMiddle,'CData',selectedCells(index));
    set(GuiSampleHandle.axesScatterBottom,'CData',selectedCells(index));
    delete(h);
    
    if sum(selectedCells) > 0
        colormap([0.65 0.65 0.65; 0 0 1]);
    else
        colormap([0.65 0.65 0.65]);
    end
    
    set(GuiSampleHandle.uiPanelScatter,'Title',['Selected Events '...
        num2str(sum(selectedCells)) '/' num2str(size(sampleFeatures,1))]);
    % update view to selected thumbnail closest to current view
    val = round(get(GuiSampleHandle.slider, 'Value'));    
    if isequal(currPos,linspace(1,nrUsedThumbs,nrUsedThumbs))
        selectedCells_nr = find(selectedCells);
        [~, ii] = min(abs(-selectedCells_nr-val));       
        closestValue = max(3,min(selectedCells_nr(ii(1)),nrUsedThumbs-2)); 
        plot_thumbnails(closestValue);
        set(GuiSampleHandle.slider, 'Value',-closestValue);
    else
        selectedCells_nr = find(ismember(currPos,find(selectedCells)));
        [~, ii] = min(abs(-selectedCells_nr-val));        
        closestValue = max(3,min(selectedCells_nr(ii(1)),nrUsedThumbs-2)); 
        plot_thumbnails(closestValue);
        set(GuiSampleHandle.slider, 'Value',-closestValue);
    end
    set(handle,'backg',color)
end

function clear_selection(~,~)
    gate = struct('gates',cell(0),'name','');
    selectedCells = zeros(size(selectedCells));
%     selectedFrames = false(size(selectedFrames));
    colormap([0.65 0.65 0.65]);
    set(GuiSampleHandle.axesScatterTop,'CData',selectedCells(index));
    set(GuiSampleHandle.axesScatterMiddle,'CData',selectedCells(index));
    set(GuiSampleHandle.axesScatterBottom,'CData',selectedCells(index));
    set(GuiSampleHandle.uiPanelScatter,'Title',['Selected Events '...
    num2str(sum(selectedCells)) '/' num2str(size(sampleFeatures,1))]);
    currPos = [sort(find(selectedCells),'ascend'); sort(find(~selectedCells),'ascend')];
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
    pos_extended = [pos(1)-max(20,0.5*pos(1)), pos(2)-max(20,0.5*pos(2)); pos(1)-max(20,0.5*pos(1)), pos(2)+max(20,0.5*pos(2));...
        pos(1)+max(20,0.5*pos(1)), pos(2)+max(20,0.5*pos(2)); pos(1)+max(20,0.5*pos(1)), pos(2)-max(20,0.5*pos(2))];
    [in,~] = inpolygon(xtest,ytest,pos_extended(:,1),pos_extended(:,2));
    if sum(in(:)) > 1
        indices = find(in);
        [~,ii] = min((xtest(in) - pos(1)).^2 + (ytest(in) - pos(2)).^2);
        in(indices(indices ~= indices(ii))) = 0;
    end
    if selectedCells(in) == 0
        selectedCells(in) = 1;
%         selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(in))) = 1;
% 
        % update all scatter plots with new manual clustering
        set(GuiSampleHandle.axesScatterTop,'CData',selectedCells(index));
        set(GuiSampleHandle.axesScatterMiddle,'CData',selectedCells(index));
        set(GuiSampleHandle.axesScatterBottom,'CData',selectedCells(index));
        delete(h);
        
        if sum(selectedCells) > 0
            colormap([0.65 0.65 0.65; 0 0 1]);
        else
            colormap([0.65 0.65 0.65]);
        end
    
        set(GuiSampleHandle.uiPanelScatter,'Title',['Selected Events '...
            num2str(sum(selectedCells)) '/' num2str(size(sampleFeatures,1))]);
        % update view to selected thumbnail
%         newPos = max(3,min(find(currPos == find(usedThumbs == sampleFeatures.ThumbNr(in))),nrUsedThumbs-2));
        newPos = max(3,min(find(currPos == find(in)),nrUsedThumbs-2));
        plot_thumbnails(newPos);
        set(GuiSampleHandle.slider, 'Value',-newPos);
    else
        selectedCells(in) = 0;
%         if ~isempty(selectedCells(in)) && isempty(find(sampleFeatures.ThumbNr(logical(selectedCells)) == sampleFeatures.ThumbNr(in), 1))
%             selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(in))) = 0;
%         end
        % update all scatter plots with new manual clustering
        set(GuiSampleHandle.axesScatterTop,'CData',selectedCells(index));
        set(GuiSampleHandle.axesScatterMiddle,'CData',selectedCells(index));
        set(GuiSampleHandle.axesScatterBottom,'CData',selectedCells(index));
        delete(h);
        
        if sum(selectedCells) > 0
            colormap([0.65 0.65 0.65; 0 0 1]);
        else
            colormap([0.65 0.65 0.65]);
        end
        
        set(GuiSampleHandle.uiPanelScatter,'Title',['Selected Events '...
            num2str(sum(selectedCells)) '/' num2str(size(sampleFeatures,1))]);
        % update currentview
        val = round(get(GuiSampleHandle.slider, 'Value'));
        plot_thumbnails(-val);
    end
    set(handle,'backg',color)
end

function zoom_in(~,~,plot_nr,axis)
    if plot_nr == 1 && strcmp(axis,'x')
        zoom_factor_x(1) = 0.9 * zoom_factor_x(1);
%         xlim(GuiSampleHandle.axesTop,[0,max(ceil(zoom_factor_x(1)*max(sampleFeatures.(topFeatureIndex1))),1)]);
        xlim(GuiSampleHandle.axesTop,[0,max(zoom_factor_x(1)*max(sampleFeatures.(topFeatureIndex1)),1)]);
    elseif plot_nr == 1 && strcmp(axis,'y')
        zoom_factor_y(1) = 0.9 * zoom_factor_y(1);
%         ylim(GuiSampleHandle.axesTop,[0,max(ceil(zoom_factor_y(1)*max(sampleFeatures.(topFeatureIndex2))),1)]);
        ylim(GuiSampleHandle.axesTop,[0,max(zoom_factor_y(1)*max(sampleFeatures.(topFeatureIndex2)),1)]);
    elseif plot_nr == 2 && strcmp(axis,'x')
        zoom_factor_x(2) = 0.9 * zoom_factor_x(2);
%         xlim(GuiSampleHandle.axesMiddle,[0,max(ceil(zoom_factor_x(2)*max(sampleFeatures.(middleFeatureIndex1))),1)]);
        xlim(GuiSampleHandle.axesMiddle,[0,max(zoom_factor_x(2)*max(sampleFeatures.(middleFeatureIndex1)),1)]);
    elseif plot_nr == 2 && strcmp(axis,'y')
        zoom_factor_y(2) = 0.9 * zoom_factor_y(2);
%         ylim(GuiSampleHandle.axesMiddle,[0,max(ceil(zoom_factor_y(2)*max(sampleFeatures.(middleFeatureIndex2))),1)]);
        ylim(GuiSampleHandle.axesMiddle,[0,max(zoom_factor_y(2)*max(sampleFeatures.(middleFeatureIndex2)),1)]);
    elseif plot_nr == 3 && strcmp(axis,'x')
        zoom_factor_x(3) = 0.9 * zoom_factor_x(3);
%         xlim(GuiSampleHandle.axesBottom,[0,max(ceil(zoom_factor_x(3)*max(sampleFeatures.(bottomFeatureIndex1))),1)]);
        xlim(GuiSampleHandle.axesBottom,[0,max(zoom_factor_x(3)*max(sampleFeatures.(bottomFeatureIndex1)),1)]);
    elseif plot_nr == 3 && strcmp(axis,'y')
        zoom_factor_y(3) = 0.9 * zoom_factor_y(3);
%         ylim(GuiSampleHandle.axesBottom,[0,max(ceil(zoom_factor_y(3)*max(sampleFeatures.(bottomFeatureIndex2))),1)]);
        ylim(GuiSampleHandle.axesBottom,[0,max(zoom_factor_y(3)*max(sampleFeatures.(bottomFeatureIndex2)),1)]);
    end
end

function zoom_out(~,~,plot_nr,axis)
    if plot_nr == 1 && strcmp(axis,'x')
        zoom_factor_x(1) = 1.1 * zoom_factor_x(1);
%         xlim(GuiSampleHandle.axesTop,[0,max(ceil(zoom_factor_x(1)*max(sampleFeatures.(topFeatureIndex1))),1)]);
        xlim(GuiSampleHandle.axesTop,[0,max(zoom_factor_x(1)*max(sampleFeatures.(topFeatureIndex1)),1)]);
    elseif plot_nr == 1 && strcmp(axis,'y')
        zoom_factor_y(1) = 1.1 * zoom_factor_y(1);
%         ylim(GuiSampleHandle.axesTop,[0,max(ceil(zoom_factor_y(1)*max(sampleFeatures.(topFeatureIndex2))),1)]);
        ylim(GuiSampleHandle.axesTop,[0,max(zoom_factor_y(1)*max(sampleFeatures.(topFeatureIndex2)),1)]);
    elseif plot_nr == 2 && strcmp(axis,'x')
        zoom_factor_x(2) = 1.1 * zoom_factor_x(2);
%         xlim(GuiSampleHandle.axesMiddle,[0,max(ceil(zoom_factor_x(2)*max(sampleFeatures.(middleFeatureIndex1))),1)]);
        xlim(GuiSampleHandle.axesMiddle,[0,max(zoom_factor_x(2)*max(sampleFeatures.(middleFeatureIndex1)),1)]);
    elseif plot_nr == 2 && strcmp(axis,'y')
        zoom_factor_y(2) = 1.1 * zoom_factor_y(2);
%         ylim(GuiSampleHandle.axesMiddle,[0,max(ceil(zoom_factor_y(2)*max(sampleFeatures.(middleFeatureIndex2))),1)]);
        ylim(GuiSampleHandle.axesMiddle,[0,max(zoom_factor_y(2)*max(sampleFeatures.(middleFeatureIndex2)),1)]);
    elseif plot_nr == 3 && strcmp(axis,'x')
        zoom_factor_x(3) = 1.1 * zoom_factor_x(3);
%         xlim(GuiSampleHandle.axesBottom,[0,max(ceil(zoom_factor_x(3)*max(sampleFeatures.(bottomFeatureIndex1))),1)]);
        xlim(GuiSampleHandle.axesBottom,[0,max(zoom_factor_x(3)*max(sampleFeatures.(bottomFeatureIndex1)),1)]);
    elseif plot_nr == 3 && strcmp(axis,'y')
        zoom_factor_y(3) = 1.1 * zoom_factor_y(3);
%         ylim(GuiSampleHandle.axesBottom,[0,max(ceil(zoom_factor_y(3)*max(sampleFeatures.(bottomFeatureIndex2))),1)]);
        ylim(GuiSampleHandle.axesBottom,[0,max(zoom_factor_y(3)*max(sampleFeatures.(bottomFeatureIndex2)),1)]);
    end
end

function sort_cells(~,~)
    currPos = [sort(find(selectedCells),'ascend'); sort(find(~selectedCells),'ascend')];
    plot_thumbnails(3); 
    set(GuiSampleHandle.slider, 'Value',-3);
end

function resort_cells(~,~)
    currPos = linspace(1,nrUsedThumbs,nrUsedThumbs);
    val = round(get(GuiSampleHandle.slider, 'Value'));
    plot_thumbnails(-val); 
end

function change_overlay(~,~)
    three_channel_overlay = logical(get(GuiSampleHandle.changeOverlayButton,'Value'));
    val = round(get(GuiSampleHandle.slider, 'Value'));
    plot_thumbnails(-val); 
end

function change_marker_size(~,~)
    marker_size = min(max(2,str2double(GuiSampleHandle.marker_size_control.String)),20);
    GuiSampleHandle.axesScatterTop.MarkerSize = marker_size;
    GuiSampleHandle.axesScatterMiddle.MarkerSize = marker_size;
    GuiSampleHandle.axesScatterBottom.MarkerSize = marker_size;
end

function export_selection(handle,~)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    %set(0,'defaultUicontrolFontSize', 14)
    exist = true;
    if isempty(gate)
        default_name = '';
    else
        default_name = gate.name;
    end
    sel_name = inputdlg({''},...
        'Please enter a name for your manual selection.', [1,75],{default_name},'on');
    classes = currentSample.results.classification.Properties.VariableNames;
    while exist 
        [exist,loc] = ismember(sel_name,classes);
        if exist
            choice = questdlg('There exists a classification with this name. Do you want to overwrite it?', ...
                                    'Error', 'Yes','No','No');
            switch choice
                case 'Yes'
                    currentSample.results.classification(:,loc) = [];
                    exist = false;
                case 'No'
                    sel_name = inputdlg({''},...
                        'Please enter a new name for your manual selection.', [1,75],{default_name},'on');            
            end
        end
    end
    if ~isempty(sel_name)
        currentSample.results.classification = [currentSample.results.classification array2table(selectedCells,'VariableNames',{sel_name{1}})];
        IO.save_sample(currentSample);
%         IO.save_results_as_xls(currentSample)
    end
    %set(0,'defaultUicontrolFontSize', 12)
    set(handle,'backg',color)
end

function load_selection(handle,~)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    classes = currentSample.results.classification.Properties.VariableNames;
    if isempty(classes)
        msgbox('No prior selection avaliable.')
    elseif size(classes,2)==1
        selectedCells = zeros(size(selectedCells));
%         selectedFrames = false(size(selectedFrames));
        selectedCells = double(currentSample.results.classification{:,1});
%         selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(logical(selectedCells)))) = 1; 
        set(GuiSampleHandle.axesScatterTop,'CData',selectedCells(index));
        set(GuiSampleHandle.axesScatterMiddle,'CData',selectedCells(index));
        set(GuiSampleHandle.axesScatterBottom,'CData',selectedCells(index));
        
        if sum(selectedCells) > 0
            colormap([0.65 0.65 0.65; 0 0 1]);
        else
            colormap([0.65 0.65 0.65]);
        end
        
        set(GuiSampleHandle.uiPanelScatter,'Title',['Selected Events '...
        num2str(sum(selectedCells)) '/' num2str(size(sampleFeatures,1))]);
        val = round(get(GuiSampleHandle.slider, 'Value'));
        plot_thumbnails(-val);      
    else
        [s,v] = listdlg('PromptString',[{'There are multiple prior selections available. Please select one:'} {''}],...
                'SelectionMode','single',...
                'ListString',classes,'ListSize',[250,150]);
        if v == 1
            selectedCells = zeros(size(selectedCells));
%             selectedFrames = false(size(selectedFrames));
            selectedCells = currentSample.results.classification{:,s};
%             selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(logical(selectedCells)))) = 1; 
            set(GuiSampleHandle.axesScatterTop,'CData',selectedCells(index));
            set(GuiSampleHandle.axesScatterMiddle,'CData',selectedCells(index));
            set(GuiSampleHandle.axesScatterBottom,'CData',selectedCells(index));
                    
            if sum(selectedCells) > 0
                colormap([0.65 0.65 0.65; 0 0 1]);
            else
                colormap([0.65 0.65 0.65]);
            end
            
            set(GuiSampleHandle.uiPanelScatter,'Title',['Selected Events '...
            num2str(sum(selectedCells)) '/' num2str(size(sampleFeatures,1))]);
            val = round(get(GuiSampleHandle.slider, 'Value'));
            plot_thumbnails(-val); 
        end
    end
    set(handle,'backg',color)
end

function design_manual_classifier(handle,~)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    
    pos_button = get(GuiSampleHandle.multiplegates_button,'Position');
    pos_main = get(GuiSampleHandle.fig_main,'Position');
    d = dialog('Units','characters','Position',[pos_main(1)+pos_button(1)-16 pos_main(2)+pos_button(2)-8 60 5],'Name','Multiple Gates');
    uicontrol('Parent',d,'Units','characters','Position',[4 1 25 3],'FontUnits','normalized','FontSize',0.3,'String','Specify Gates.','Callback',@btn1_callback);
    uicontrol('Parent',d,'Units','characters','Position',[31 1 25 3],'FontUnits','normalized','FontSize',0.3,'String','Load Existing Gates.','Callback',@btn2_callback);
    choice = 0;
    waitfor(d);
    function btn1_callback(~,~)
        choice = 1;
        delete(gcf)
    end
    function btn2_callback(~,~)
            choice = 2;
            delete(gcf)
    end
    
    mc = ManualClassification(cell(0),'ManualGates');
    if choice == 1
        gui_gates = gui_manual_gates();
        waitfor(gui_gates.fig_main,'UserData')
        try
            gate = get(gui_gates.fig_main,'UserData');
        catch 
            set(handle,'backg',color);
            return
        end
        mc.gates = gate.gates;
        mc.name = gate.name;
        delete(gui_gates.fig_main)
        clear('gui_gates');
    elseif choice == 2
        file = which('ACCEPT.m');
        installDir = fileparts(file);
        [file_name, folder_name] = uigetfile([installDir filesep 'misc' filesep 'saved_gates' filesep '*.mat'],'Load gate.');
        try
            gate(1).gates = importdata([folder_name filesep file_name]);
            gate(1).name = strrep(file_name,'.mat','');
        catch 
            set(handle,'backg',color);
            return
        end
        mc.gates = gate.gates;
        mc.name = gate.name;
    else
        set(handle,'backg',color);
        return
    end

    gate_result = mc.run(sampleFeatures);
    
    selectedCells = zeros(size(selectedCells));
%     selectedFrames = false(size(selectedFrames));   
    selectedCells = double(gate_result{:,1});
%     selectedFrames(ismember(usedThumbs,sampleFeatures.ThumbNr(logical(selectedCells)))) = 1;
    
    set(GuiSampleHandle.axesScatterTop,'CData',selectedCells(index));
    set(GuiSampleHandle.axesScatterMiddle,'CData',selectedCells(index));
    set(GuiSampleHandle.axesScatterBottom,'CData',selectedCells(index));

    if sum(selectedCells) > 0
        colormap([0.65 0.65 0.65; 0 0 1]);
    else
        colormap([0.65 0.65 0.65]);
    end

    set(GuiSampleHandle.uiPanelScatter,'Title',['Selected Events '...
    num2str(sum(selectedCells)) '/' num2str(size(sampleFeatures,1))]);
    val = round(get(GuiSampleHandle.slider, 'Value'));
    plot_thumbnails(-val); 
    set(handle,'backg',color)
end

function export_thumbs(handle,~)
    color = get(handle,'backg');
    set(handle,'backgroundcolor',[1 .5 .5])
    drawnow;
    choice = NaN;
    pos_button = get(GuiSampleHandle.export_thumbs,'Position');
    pos_main = get(GuiSampleHandle.fig_main,'Position');
    d = dialog('Units','characters','Position',[pos_main(1)+pos_button(1)-16 pos_main(2)+pos_button(2)-8 60 5],'Name','Export Thumbnail Images');
    uicontrol('Parent',d,'Units','characters','Position',[4 1 25 3],'FontUnits','normalized','FontSize',0.28,'String','All Thumbnails.','Callback',@btn1_callback);
    uicontrol('Parent',d,'Units','characters','Position',[31 1 25 3],'FontUnits','normalized','FontSize',0.28,'String','Selected Thumbnails.','Callback',@btn2_callback);
    waitfor(d);
    
    function btn1_callback(~,~)
        choice = 0;
        delete(gcf)
    end
    function btn2_callback(~,~)
            choice = selectedCells;
            delete(gcf)
            name = inputdlg('Enter a name for your selection:','Specify Folder Name.',1,{'selected_Thumbs'});
    end
    if ~isnan(choice)
        if exist('name','var')
            IO.save_thumbnail(currentSample,[],[],[],choice,thumbContainer,name)
        else
            IO.save_thumbnail(currentSample,[],[],[],choice,thumbContainer)
        end
    end
    set(handle,'backg',color)
end

function close_fcn(~,~) 
%     profile off; profile viewer
    delete(gcf)
end

end