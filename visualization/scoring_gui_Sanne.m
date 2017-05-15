function [GuiSampleHandle] = scoring_gui_Sanne(base,currentSample,path)
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

% profile on
% Main figure: create and set properies (relative size, color)
set(0,'units','characters');  
screensz = get(0,'screensize');

loader = ThumbnailLoader_adapted(currentSample);
loader.update_prior_infos(currentSample,path);
loader.preload_segmentation_tiffs(currentSample,path);

thumbContainer = ThumbContainer(currentSample);

GuiSampleHandle.fig_main = figure('Units','characters','Position',[(screensz(3)-230)/2 (screensz(4)-65)/2 230 65],'Name','ACCEPT - CTC Scoring Tool','MenuBar','none',...
    'NumberTitle','off','Color',[1 1 1],'Resize','off','CloseRequestFcn',@close_fcn);

%% Set maximum intensity
maxi = 4095;


nrUsedThumbs = thumbContainer.nrOfEvents;

%replace NaN values with zeros
sampleFeatures = currentSample.results.features;
sampleFeatures_noNaN = sampleFeatures{:,:};
sampleFeatures_noNaN(isnan(sampleFeatures_noNaN)) = 0;
sampleFeatures{:,:} = sampleFeatures_noNaN; 

currPos = 1;
scoredCells = 0;
scores = zeros(nrUsedThumbs,1);

zoom_factor_x(1:2) = 1.15;
zoom_factor_y(1:2) = 1.15;
zoom_factor_x(3) = 1.2;
zoom_factor_y(3) = 1.2;
%% Main title
GuiSampleHandle.title_axes = axes('Units','characters','Position',[110 61.8 39.6 2.6]); axis off;
GuiSampleHandle.title = text('Position',[0 0],'String','\color[rgb]{0.729,0.161,0.208} ACCEPT CTC Scoring','FontUnits','normalized','FontSize',0.8,'verticalAlignment','base','horizontalAlignment','center');


%% Main panels

% create panel for thumbnail gallery (bottom-left)
GuiSampleHandle.uiPanelGallery = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Units','characters','Position',[5.1 38 151.6 20.1],...
                                     'Title','Cell Thumbnail','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.09,...
                                     'BackgroundColor',[1 1 1]);

% create panel for scatter plots (right)
GuiSampleHandle.uiPanelScatter = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Units','characters','Position',[160.8 1.3 63.9 59.0],...
                                     'Title','Scatter Plots','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.023,...
                                     'BackgroundColor',[1 1 1]);
% create panel for clicking (right)
GuiSampleHandle.uiPanelButton = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Units','characters','Position',[5.1 32 151.6 5.3],...
                                     'Title','Number of Scored Cells','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.3,...
                                     'BackgroundColor',[1 1 1]);
% create panel for questions (right)
GuiSampleHandle.uiPanelDesc = uipanel('Parent',GuiSampleHandle.fig_main,...
                                    'Units','characters','Position',[5.1 1.3 151.6 30.0],...
                                     'Title','Scores','TitlePosition','CenterTop',...
                                     'FontUnits','normalized','FontSize',0.067,...
                                     'BackgroundColor',[1 1 1]);
                                 

                                
%% Fill uiPanelGallery
gui_sample_color = [1 1 1];
three_channel_overlay = true;
channelNames = {'CD45','DAPI','CK'};


% create column names for gallery
columnTextSize = 0.8;
                       
% create panel for thumbnails next to slider                          
GuiSampleHandle.uiPanelThumbsOuter = uipanel('Parent',GuiSampleHandle.uiPanelGallery,...
                                        'Units','characters','Position',[2.1 0 147 14.4],...
                                        'BackgroundColor',gui_sample_color);
                                   
% compute relative dimension of the thumbnail grid
nbrAvailableRows = 1;
nbrImages        = nbrAvailableRows * 4;                      
cols  = 4;
space = 11.9;

GuiSampleHandle.textCol(1) = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                    'Units','characters','Position',[space 14.5 15.1 1.7],...
                                    'String','Overlay','HorizontalAlignment','center',...
                                    'FontUnits', 'normalized','FontSize',columnTextSize,...
                                    'BackgroundColor',gui_sample_color);

for i = 1:cols-1
    GuiSampleHandle.textCol(i+1) = uicontrol('Style','text','Parent',GuiSampleHandle.uiPanelGallery,...
                                'Units','characters','Position',[space+i*(2.3+138/cols) 14.5 15.1 1.7],...
                                'String',channelNames{i},'HorizontalAlignment','center',...
                                'FontUnits', 'normalized','FontSize',columnTextSize,...
                                'BackgroundColor',gui_sample_color);
end

% axis height and width
axHeight = 14;
axWidth = 138/cols;

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

% specify row location for all columns
y = 0.2;
% plot overlay image in first column
x = 0.8;
ind = 1;
hAxes(ind) = axes(axesProp,axesVal,'Units','characters','Position',[x y axWidth axHeight]);
hImages(ind)= imshow([],'parent',hAxes(ind),'InitialMagnification','fit');
set(hImages(ind),'ButtonDownFcn',@openSpecificImage);
% plot image for each color channel in column 2 till nbrChannels
for ch = 1:cols-1
    x = (ch)*(axWidth+2.3);
    ind = (ch +1); % 1-4,6-9,... index for four color channels
    hAxes(ind) = axes(axesProp,axesVal,'Units','characters','Position',[x y axWidth axHeight]);
    hImages(ind)= imshow([],'parent',hAxes(ind),'InitialMagnification','fit');
    set(hImages(ind),'ButtonDownFcn',@openSpecificImage);
    colormap(hAxes(ind),map);
end

GuiSampleHandle.OverlayButtonTxT = uicontrol('Parent',GuiSampleHandle.fig_main,'Style','text','Units','characters','FontUnits', 'normalized',...
            'FontSize',0.8,'Position',[7.1 58.35 29 1.5],'BackgroundColor',[ 1 1 1],'String','3 Channel Overlay');
GuiSampleHandle.changeOverlayButton = uicontrol('Parent',GuiSampleHandle.fig_main, 'Style', 'checkbox', 'Units','characters',...
            'Value',1,'Position', [36.4 58.35 5 1.5],'BackgroundColor',[ 1 1 1],'Callback', @change_overlay); 

% go through all thumbnails (resp. dataframes)
plot_thumbnails(currPos);



%% Fill uiPanelScatter

marker_size = 500;

% create data for scatter plot at the top
GuiSampleHandle.axesTop = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[11.2 42.2 40.4 13.1]); %[left bottom width height]
GuiSampleHandle.axesTop.YAxis.Exponent = 0;
GuiSampleHandle.axesTop.XAxis.Exponent = 0;

topFeatureIndex1 = find(cellfun(@(s) ~isempty(strfind('ch_3_MeanIntensity', s)), sampleFeatures.Properties.VariableNames));
topFeatureIndex2 = find(cellfun(@(s) ~isempty(strfind('ch_1_MeanIntensity', s)), sampleFeatures.Properties.VariableNames));

XData = sampleFeatures.(topFeatureIndex1)(currPos);
YData = sampleFeatures.(topFeatureIndex2)(currPos);    

GuiSampleHandle.axesScatterTop = scatter(GuiSampleHandle.axesTop,XData,YData, marker_size,'Marker','.');
colormap([0.65 0.65 0.65]);

x_max_top = max(zoom_factor_x(2)*max(sampleFeatures.(topFeatureIndex1)),1);
y_max_top = max(zoom_factor_y(2)*max(sampleFeatures.(topFeatureIndex2)),1);
xlim([0,x_max_top]); ylim([0,y_max_top]);
label_top = text(max(XData+0.05*x_max_top,0.1*x_max_top), max(YData+0.05*y_max_top,0.1*y_max_top),['(' num2str(round(XData)) ' | ' num2str(round(YData)) ')'],'FontSize',10);  

set(gca,'TickDir','out');
set(gca,'XGrid','on','YGrid','on');
feature_names = cell(size(sampleFeatures.Properties.VariableNames));
feature_names(2:end) = strrep(strrep(strrep(strrep(sampleFeatures.Properties.VariableNames(2:end),'_',' '),'ch 1','CD45'),'ch 2','DAPI'),'ch 3','CK');
if size(currentSample.channelNames,2) > 3
    feature_names(2:end) = strrep(feature_names(2:end),'ch 4',currentSample.channelNames(4));
end
if size(currentSample.channelNames,2) > 4
    feature_names(2:end) = strrep(feature_names(2:end),'ch 5',currentSample.channelNames(5));
end

% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectTopIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','text','Units','characters',...
            'String',feature_names(topFeatureIndex1),...
            'Position',[25 39.0 32.3 1.5],'BackgroundColor',gui_sample_color,...
            'FontUnits', 'normalized',...
            'FontSize',0.75,'HorizontalAlignment','right');
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectTopIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','text','Units','characters',...
            'String',feature_names(topFeatureIndex2),'BackgroundColor',gui_sample_color,...
            'Position',[1.5 55.8 32.3 1.5],...
            'FontUnits', 'normalized',...
            'FontSize',0.75,'HorizontalAlignment','left');

%----
% create data for scatter plot in the middle
GuiSampleHandle.axesMiddle = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[11.2 23 40.4 13.1]); %[left bottom width height]
GuiSampleHandle.axesMiddle.YAxis.Exponent = 0;
GuiSampleHandle.axesMiddle.XAxis.Exponent = 0;
middleFeatureIndex1 = find(cellfun(@(s) ~isempty(strfind('ch_2_MeanIntensity', s)), sampleFeatures.Properties.VariableNames));
middleFeatureIndex2 = find(cellfun(@(s) ~isempty(strfind('ch_3_Size', s)), sampleFeatures.Properties.VariableNames));

XData = sampleFeatures.(middleFeatureIndex1)(currPos);
YData = sampleFeatures.(middleFeatureIndex2)(currPos);    

GuiSampleHandle.axesScatterMiddle = scatter(GuiSampleHandle.axesMiddle,XData,YData, marker_size,'Marker','.');
colormap([0.65 0.65 0.65]);

x_max_middle = max(zoom_factor_x(2)*max(sampleFeatures.(middleFeatureIndex1)),1);
y_max_middle = max(zoom_factor_y(2)*max(sampleFeatures.(middleFeatureIndex2)),1);
xlim([0,x_max_middle]); ylim([0,y_max_middle]);
label_middle = text(max(XData+0.05*x_max_middle,0.1*x_max_middle), max(YData+0.05*y_max_middle,0.1*y_max_middle),['(' num2str(round(XData)) ' | ' num2str(round(YData)) ')'],'FontSize',10);  

set(gca,'TickDir','out');
set(gca,'XGrid','on','YGrid','on');
% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectMiddleIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','text','Units','characters',...
            'String',feature_names(middleFeatureIndex1),'BackgroundColor',gui_sample_color,...
            'Position',[25 19.7 32.3 1.5],...
            'FontUnits', 'normalized',...
            'FontSize',0.75,'HorizontalAlignment','right');
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectMiddleIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','text','Units','characters',...
            'String',feature_names(middleFeatureIndex2),'BackgroundColor',gui_sample_color,...
            'Position',[1.5 36.6 32.3 1.5],...
            'FontUnits', 'normalized',...
            'FontSize',0.75,'HorizontalAlignment','left');

%----
% create scatter plot at the bottom
GuiSampleHandle.axesBottom = axes('Parent',GuiSampleHandle.uiPanelScatter,'Units','characters','Position',[11.2 3.7 40.4 13.1]); %[left bottom width height]
GuiSampleHandle.axesBottom.YAxis.Exponent = 0;
GuiSampleHandle.axesBottom.XAxis.Exponent = 0;
bottomFeatureIndex1 = find(cellfun(@(s) ~isempty(strfind('ch_3_Eccentricity', s)), sampleFeatures.Properties.VariableNames));
bottomFeatureIndex2 = find(cellfun(@(s) ~isempty(strfind('ch_2_Overlay_ch_3', s)), sampleFeatures.Properties.VariableNames));
if isempty(bottomFeatureIndex2)
    bottomFeatureIndex2 = find(cellfun(@(s) ~isempty(strfind('ch_3_Size', s)), sampleFeatures.Properties.VariableNames));
end

XData = sampleFeatures.(bottomFeatureIndex1)(currPos);
YData = sampleFeatures.(bottomFeatureIndex2)(currPos);    
    

GuiSampleHandle.axesScatterBottom = scatter(GuiSampleHandle.axesBottom,XData,YData, marker_size,'Marker','.');
colormap([0.65 0.65 0.65]); %colormap([0 0 1]); 
x_max_bottom = max(zoom_factor_x(3)*max(sampleFeatures.(bottomFeatureIndex1)),1);
y_max_bottom = max(zoom_factor_y(3)*max(sampleFeatures.(bottomFeatureIndex2)),1);
xlim([0,x_max_bottom]); ylim([0,y_max_bottom]);
label_bottom = text(max(XData+0.05*x_max_bottom,0.1*x_max_bottom), max(YData+0.05*y_max_bottom,0.1*y_max_bottom),['(' num2str(round(XData,2)) ' | ' num2str(round(YData,2)) ')'],'FontSize',10);  

set(gca,'TickDir','out');
set(gca,'XGrid','on','YGrid','on');

% create choose button to switch feature index1 (x-axis)
GuiSampleHandle.popupFeatureSelectBottomIndex1 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','text','Units','characters',...
            'String',feature_names(bottomFeatureIndex1),'BackgroundColor',gui_sample_color,...
            'Position',[25 0.5 32.3 1.5],...
            'FontUnits', 'normalized',...
            'FontSize',0.75,'HorizontalAlignment','right');
% create choose button to switch feature index2 (y-axis)
GuiSampleHandle.popupFeatureSelectBottomIndex2 = uicontrol('Parent',GuiSampleHandle.uiPanelScatter,'Style','text','Units','characters',...
            'String',feature_names(bottomFeatureIndex2),'BackgroundColor',gui_sample_color,...
            'Position',[1.5 17.3 32.3 1.5],...
            'FontUnits', 'normalized',...
            'FontSize',0.75,'HorizontalAlignment','left');

%create push button for information
GuiSampleHandle.infoButton = uicontrol('Parent',GuiSampleHandle.fig_main, 'Style', 'pushbutton', 'Units','characters','FontUnits', 'normalized',...
            'FontSize',0.9,'String', 'i','Position', [214.5 61 10 2],'Callback', @open_info,'BackgroundColor',gui_sample_color);

% --- Plot thumbnails around index i
function plot_thumbnails(val)
    %numberOfThumbs=size(currentSample.priorLocations,1);
    thumbIndex = val;
    thumbIndex(thumbIndex<1)=[];
    thumbIndex(thumbIndex>nrUsedThumbs)=[];
    if ~isempty(thumbIndex)
            rawImage = thumbContainer.thumbnails{(thumbIndex)};
            label = currentSample.results.thumbnails.label((thumbIndex));
            if ~isa(base.sampleProcessor,'Marker_Characterization')
                segmentedImage = thumbContainer.labelFullImage{(thumbIndex)} == label;
            else 
                segmentedImage = thumbContainer.labelThumbImage{(thumbIndex)} == label;
            end
            % plot overlay image in first column
            plotImInAxis(rawImage,segmentedImage,hAxes(1),hImages(1));
            
            % plot image for each color channel in column 2 till nbrChannels
            for chan = 1:cols-1
                l = chan + 1;
                plotImInAxis(rawImage(:,:,chan),segmentedImage(:,:,chan),hAxes(l),hImages(l));
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
function openSpecificImage(~,~)
    type = get(gcf,'SelectionType');
    switch type
        case 'alt' % right mouse button action
            im = get(gcbo,'cdata');
            true_max_int = max(im(im~=1));
            im_new = (im / true_max_int) .* double(im~=1) + 1.002 * double(im==1);
            figure; imagesc(im_new,[0,1.002]); axis equal; axis off;
            colormap(gca,map);
    end
end

%%%%%% QUESTIONS %%%%%%
bg = uibuttongroup('Parent',GuiSampleHandle.uiPanelDesc,'Visible','off',...
                  'Units','characters','Position',[1 1 149.6 26],'BackgroundColor',[1 1 1],...
                  'SelectionChangedFcn',@bselection);
              
% Create four radio buttons in the button group.
r0 = uicontrol(bg,'Style','radiobutton',...
                  'String','0 - Dummy',...
                  'Units','characters','Position',[1 27 147.6 1],...
                  'FontUnits', 'normalized',...
                  'FontSize',0.3,'HorizontalAlignment','left','BackgroundColor',[1 1 1],'HandleVisibility','off');

r1 = uicontrol(bg,'Style','radiobutton',...
                  'String','1 - Definitely not a CTC',...
                  'Units','characters','Position',[1 19 147.6 6],...
                  'FontUnits', 'normalized',...
                  'FontSize',0.3,'HorizontalAlignment','left','BackgroundColor',[1 1 1],'HandleVisibility','off');
              
r2 = uicontrol(bg,'Style','radiobutton',...
                  'String','2 - Most likely not a CTC',...
                  'Units','characters','Position',[1 13 147.6 6],...
                  'FontUnits', 'normalized',...
                  'FontSize',0.3,'HorizontalAlignment','left','BackgroundColor',[1 1 1],'HandleVisibility','off');

r3 = uicontrol(bg,'Style','radiobutton',...
                  'String','3 - Most likely a CTC',...
                  'Units','characters','Position',[1 7 147.6 6],...
                  'FontUnits', 'normalized',...
                  'FontSize',0.3,'HorizontalAlignment','left','BackgroundColor',[1 1 1],'HandleVisibility','off');
              
r4 = uicontrol(bg,'Style','radiobutton',...
                  'String','4 - Definitely a CTC',...
                  'Units','characters','Position',[1 1 147.6 6],...
                  'FontUnits', 'normalized',...
                  'FontSize',0.3,'HorizontalAlignment','left','BackgroundColor',[1 1 1],'HandleVisibility','off');
              
% Make the uibuttongroup visible after creating child objects. 
bg.Visible = 'on';

function bselection(~,event)
   scores(currPos) = str2double(event.NewValue.String(1));
   scoredCells = scoredCells + 1;
   set(GuiSampleHandle.Count,'String',[num2str(scoredCells) ' / ' num2str(nrUsedThumbs)]);
   pause(0.3)
   if scoredCells < nrUsedThumbs
    next_cell();
   end
   if scoredCells == nrUsedThumbs
       save_res();
   end
end

function open_info(~,~)
    helpdlg({'The following parameters are shown in the scatter plots:','','CD45 Mean Intensity: Medium Intensity of the exclusion marker. The evaluated signal is outlined in red.','',...
        'CK Mean Intensity: Medium Intensity of the inclusion marker. The evaluated signal is outlined in red.','',...
        'DAPI Mean Intensity: Medium Intensity of the nucleus marker. The evaluated signal is outlined in red.','',...
        'CK Size: Size of the evaluated signal in the CK channel in um^2.','',...
        'DAPI Overlay CK: Percentage of the DAPI signal that is contained in the CK signal (1 - fully contained, 0 not contained at all).','',...
        'CK Eccentricity: Roundness Measure in the CK channel between 0 and 1 (0 - perfect circle, 1 - line).'},'Feature Information')

end

function next_cell(~,~)
    set(r0,'Value',1);
    currPos = currPos + 1;
    plot_thumbnails(currPos);
    
    GuiSampleHandle.axesScatterTop.XData = sampleFeatures.(topFeatureIndex1)(currPos);
    GuiSampleHandle.axesScatterTop.YData = sampleFeatures.(topFeatureIndex2)(currPos);
    set(label_top,'Position',[max(GuiSampleHandle.axesScatterTop.XData+0.05*x_max_top,0.1*x_max_top), max(GuiSampleHandle.axesScatterTop.YData+0.05*y_max_top,0.1*y_max_top)],...
        'String',['(' num2str(round(GuiSampleHandle.axesScatterTop.XData)) ' | ' num2str(round(GuiSampleHandle.axesScatterTop.YData)) ')']); 
    
    GuiSampleHandle.axesScatterMiddle.XData = sampleFeatures.(middleFeatureIndex1)(currPos);
    GuiSampleHandle.axesScatterMiddle.YData = sampleFeatures.(middleFeatureIndex2)(currPos);
    set(label_middle,'Position',[max(GuiSampleHandle.axesScatterMiddle.XData+0.05*x_max_middle,0.1*x_max_middle), max(GuiSampleHandle.axesScatterMiddle.YData+0.05*y_max_middle,0.1*y_max_middle)],...
        'String',['(' num2str(round(GuiSampleHandle.axesScatterMiddle.XData)) ' | ' num2str(round(GuiSampleHandle.axesScatterMiddle.YData)) ')']); 
    
    GuiSampleHandle.axesScatterBottom.XData = sampleFeatures.(bottomFeatureIndex1)(currPos);
    GuiSampleHandle.axesScatterBottom.YData = sampleFeatures.(bottomFeatureIndex2)(currPos);
    set(label_bottom,'Position',[max(GuiSampleHandle.axesScatterBottom.XData+0.05*x_max_bottom,0.1*x_max_bottom), max(GuiSampleHandle.axesScatterBottom.YData+0.05*y_max_bottom,0.1*y_max_bottom)],...
        'String',['(' num2str(round(GuiSampleHandle.axesScatterBottom.XData,2)) ' | ' num2str(round(GuiSampleHandle.axesScatterBottom.YData,2)) ')']); 
end
%%%%%%%%%%%%%%%%%%%%%%%
GuiSampleHandle.Count = uicontrol('Parent',GuiSampleHandle.uiPanelButton,'Style','text','Units','characters','FontUnits', 'normalized',...
            'FontSize',0.75,'Position',[65 0.25 31.6 3],'BackgroundColor',[ 1 1 1],'String',[num2str(scoredCells) ' / ' num2str(nrUsedThumbs)]);



function change_overlay(~,~)
    three_channel_overlay = logical(get(GuiSampleHandle.changeOverlayButton,'Value'));
    plot_thumbnails(currPos); 
end

function save_res()
    username = inputdlg('Enter your name: ','Name');
    scores_save = array2table(scores,'VariableNames',{username{1}});
    writetable(scores_save,[path(1:end-4) filesep 'results' filesep username{1} '.xlsx']);
%     delete(gcf)
end

function close_fcn(~,~) 
%     profile off; profile viewer
    delete(gcf)
end

end