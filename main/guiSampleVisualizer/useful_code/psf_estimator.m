function varargout = psf_estimator(varargin)
% PSF_ESTIMATOR This GUI and embedded algorithms provide a toolbox for
% estimating point spread functions (e.g. Gaussian) from calibration data,
% i.e. point sources respectively beads.
% To run the GUI simply call psf_estimator in the console. To visualize
% details of the computation the user can activate the DEBUG mode.
%
% This toolbox makes use of MATLAB's image processing and optimization
% toolboxes.
%
% See also: 
%
% Version: 0.1
% Copyright 2013, Christoph Brune (University of Münster, Germany) in collaboration with 
% Ozan Öktem (Mathematics, KTH) and the SciLifeLab (Stockholm)

% Last Modified by GUIDE v2.5 19-Apr-2013 17:03:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @psf_estimator_OpeningFcn, ...
                   'gui_OutputFcn',  @psf_estimator_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before psf_estimator is made visible.
function psf_estimator_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to psf_estimator (see VARARGIN)

% Choose default command line output for psf_estimator
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% set axis of image off
axis off; colormap(hot);

% UIWAIT makes psf_estimator wait for user response (see UIRESUME)
% uiwait(handles.mainFigure);


% --- Outputs from this function are returned to the command line.
function varargout = psf_estimator_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function concatenateLog(hObject,str)
currentLogCell = get(hObject,'String');
currentLogCell{size(currentLogCell,1)+1,1} = str;
set(hObject,'String',currentLogCell);
%clear listbox selection:
set(hObject,'Max',intmax); % #elements that could be selected or unselected in principle
set(hObject,'Value',[]); % deselect all three

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function inputEdit_Callback(hObject, eventdata, handles)
% hObject    handle to inputEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of inputEdit as text
%        str2double(get(hObject,'String')) returns contents of inputEdit as a double


% --- Executes during object creation, after setting all properties.
function inputEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inputEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chooseButton.
function chooseButton_Callback(hObject, eventdata, handles)
% hObject    handle to chooseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% open file dialog
[FileName,PathName,FilterIndex] = uigetfile({'*.tif';'*.mat';'*.*'},'Select your input data.');
if FileName == 0;
    %warning('Please select your input data correctly.');
    return;
end;
FileName_trunc = FileName(1:findstr('.',FileName)-1);
FileExt = FileName(end-2:end);
switch FileExt
    case {'tif'} % tif/lsm file
        % load data
        f = single(imread([PathName FileName]));
        % scale data to [0,255]
        f = f-min(f(:)); f = 255*f/max(f(:));
    case 'mat' % mat file
        load([PathName FileName]);
    otherwise
        error('File type not supported.');
end
if exist('f','var')
    handles.data.f = f;
    set(handles.inputEdit,'String',FileName);
    [nx,ny]=size(f); handles.data.nx = nx; handles.data.ny = ny;
    concatenateLog(handles.logListbox,sprintf('Image loaded. Dimensions: %i x %i.',nx,ny));
    set(gcf,'CurrentAxes',handles.imageAxes);
    imagesc(f); axis image; axis off; drawnow;
    % Update handles structure
    guidata(hObject, handles);
end


function fwhmXEdit_Callback(hObject, eventdata, handles)
% hObject    handle to fwhmXEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fwhmXEdit as text
%        str2double(get(hObject,'String')) returns contents of fwhmXEdit as a double


% --- Executes during object creation, after setting all properties.
function fwhmXEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fwhmXEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function fwhmYEdit_Callback(hObject, eventdata, handles)
% hObject    handle to fwhmYEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fwhmYEdit as text
%        str2double(get(hObject,'String')) returns contents of fwhmYEdit as a double


% --- Executes during object creation, after setting all properties.
function fwhmYEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fwhmYEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function fwhmXYDiagEdit_Callback(hObject, eventdata, handles)
% hObject    handle to fwhmXYDiagEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fwhmXYDiagEdit as text
%        str2double(get(hObject,'String')) returns contents of fwhmXYDiagEdit as a double


% --- Executes during object creation, after setting all properties.
function fwhmXYDiagEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fwhmXYDiagEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calculateButton.
function calculateButton_Callback(hObject, eventdata, handles)
% hObject    handle to calculateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Run bead detection
if isfield(handles.data','f')
    f = handles.data.f;
else
    helpdlg('Please select a 2D input image via the Choose file button.');
    return;
end

concatenateLog(handles.logListbox,sprintf('Run bead detection...'));

% gcf resp. get(0,'CurrentFigure') is root figure here
set(gcf,'CurrentAxes',handles.imageAxes);
imagesc(f); axis image; axis off; drawnow;


% Gaussian imfilter, use TV instead ?
f_fil = imfilter(f,fspecial('gaussian',[6 6],2));
if get(handles.debugCheckbox,'value')
    debugPlotHandle = figure; subplot(2,3,1); imagesc(f_fil); axis image; axis off;
    title('1.) Gaussian filtering'); drawnow;
    contents = cellstr(get(handles.colormapPopup,'String'));
    colormap(contents{get(handles.colormapPopup,'Value')});
end

% contrast improvement via adaptive histequalization
if get(handles.debugCheckbox,'value')
    subplot(2,3,2); hist(f_fil(:),1000);
    title('2.) Histogram'); drawnow;
end
% f_equ = adapthisteq(f_fil,'NumTiles',[8 8]);
% f_equ = imadjust(f_equ,[.2;1],[]);
% imagesc(f_equ); axis image; axis off; drawnow;
%save_figure([FileName(1:end-4) '_preprocessing'],gcf,{'png'});

f_equ = f_fil;

% scale to [0,1]
f_equ = f_equ - min(f_equ(:));
f_equ = f_equ/max(f_equ(:));
% simple graythresh and convert to bw
level = graythresh(f_equ);
f_bw = im2bw(f_equ,level);
if get(handles.debugCheckbox,'value')
    subplot(2,3,3); imagesc(f_bw); axis image; axis off;
    title('3.) Thresholding'); drawnow;
end

% additional erosion (make smaller)
% seD = strel('diamond',1);
% f_bw = imerode(f_bw,seD);
% %f_bw = imerode(f_bw,seD);
% figure; imagesc(f_bw); colormap(gray); title('Segmentation after dilation');
% %save_figure([FileName(1:end-4) '_segmentation'],gcf,{'png'});

% dilatation (make larger with disc)
neighb = 5;
f_bw = imdilate(f_bw,strel('disk',neighb));
if get(handles.debugCheckbox,'value')
    subplot(2,3,4); imagesc(f_bw); axis image; axis off;
    title('4.) Dilatation'); drawnow;
end

% bead filtering via image analysis
regions_dots = regionprops(f_bw,'Centroid','Area','Eccentricity');
% number of elements
numObj = numel(regions_dots);
% create histogram of area, eccentricity and diameter
area = zeros(1,numObj); eccen = zeros(1,numObj); 
for k = 1 : numObj
    area(k)  = regions_dots(k).Area;
    eccen(k) = regions_dots(k).Eccentricity;
end

% remove beads with area values far away from median area of dilated beads
%figure; hist(area(:),1000); drawnow;
median_area = median(area(:));
areaTol = .25;
areaFilter = area < (1-areaTol)*median_area | area > (1+areaTol)*median_area;
area(areaFilter)=NaN; eccen(areaFilter)=NaN;
%figure; hist(area(~isnan(area(:))),1000); drawnow;

% remove beads with eccentricity larger than median+eccenTol
%figure; hist(eccen,1000); drawnow;
eccenTol = .4;
eccenFilter = eccen > (1+eccenTol)*median(eccen(~isnan(eccen)));
area(eccenFilter)=NaN; eccen(eccenFilter)=NaN;

% compute box area via median of area
avgEquivDiam = sqrt(4*median_area/pi); % assuming a cirular bead of segmentation
apertureBoxRadius = round(0.5*1.2*avgEquivDiam);

% remove beads too close to the boundary
[nx,ny] = size(f);
for k = 1 : numObj
    if ~isnan(area(k))
        if (round(regions_dots(k).Centroid(1)) - apertureBoxRadius <= 0  ||...
            round(regions_dots(k).Centroid(1)) + apertureBoxRadius >= ny ||...
            round(regions_dots(k).Centroid(2)) - apertureBoxRadius <= 0  ||...
            round(regions_dots(k).Centroid(2)) + apertureBoxRadius >= nx)
            area(k) = NaN;
        end
    end
end

figure(psf_estimator);
imagesc(f); axis equal; axis off; drawnow;
hold on;
for k = 1 : numObj
    if ~isnan(area(k))
        plot(regions_dots(k).Centroid(1), regions_dots(k).Centroid(2),'go','MarkerSize',14);
    end
end
hold off;
detectedBeads = ~isnan(area(:));
concatenateLog(handles.logListbox,sprintf('%d beads detected.',sum(detectedBeads)));

% extract beads from points of interest
beads = zeros(2*apertureBoxRadius+1,2*apertureBoxRadius+1,sum(detectedBeads),'single');
m = 1;
for k = 1 : numObj
    if ~isnan(area(k))
        beads(:,:,m) = f(round(regions_dots(k).Centroid(2))-apertureBoxRadius:round(regions_dots(k).Centroid(2))+apertureBoxRadius,...
                         round(regions_dots(k).Centroid(1))-apertureBoxRadius:round(regions_dots(k).Centroid(1))+apertureBoxRadius);
        m = m+1;
    end
end
%scrollData({beads}); axis image; colormap(jet);

% visualize average bead in result axis
set(handles.mainFigure,'CurrentAxes',handles.psfAxes);
psfEstimation = double(sum(beads,3));
% normalize psfEstimation
psfEstimation = psfEstimation - min(psfEstimation(:));
psfEstimation = psfEstimation/max(psfEstimation(:));

imagesc(psfEstimation); axis image; axis off; drawnow;
set(handles.psfPanel,'Title',['PSF estimation [' num2str(size(beads,1)) 'x' num2str(size(beads,2)) ' pixels]']);

% fit to 2D Gaussian/Laplacian
switch get(handles.psfPopupmenu,'Value')
    case 1 % Gaussian
        gaussian2D = @(x,xdata) x(1)*exp(-((xdata(:,:,1)-x(2)).^2/(2*x(3)^2) + (xdata(:,:,2)-x(4)).^2/(2*x(5)^2)));
    case 2 % Lorentzian
        % TODO
end
[X,Y] = meshgrid(linspace(-1,1,size(beads,1)));
xdata = zeros(size(X,1),size(Y,2),2); xdata(:,:,1) = X; xdata(:,:,2) = Y;
x0 = [1,0,1,0,1]; % Inital guess parameters
lb = [0,0,0,0,0]; ub = [1,1,1,1,1]; % bounds
[x,resnorm,residual,exitflag] = lsqcurvefit(gaussian2D,x0,xdata,psfEstimation,lb,ub,optimset('Display','off'));
if get(handles.debugCheckbox,'value')
    %set(handles.mainFigure,'CurrentAxes',handles.imageAxes);
    set(0,'CurrentFigure',debugPlotHandle);
    subplot(2,3,5); mesh(X,Y,psfEstimation); title('Collected PSF average');
    subplot(2,3,6); mesh(X,Y,gaussian2D(x,xdata));
    title(['Fitted PSF, ',sprintf('scal=%4.2f, EVx=%4.2f, Stdx=%4.2f, EVy=%4.2f, Stdy=%4.2f',x(1),x(2),x(3),x(4),x(5))]);
end
fwhmX = x(3)*2*sqrt(2*log(2)); % does not take into account scaling, resp. prefix
fwhmY = x(5)*2*sqrt(2*log(2)); % does not take into account scaling, resp. prefix
set(handles.fwhmXEdit,'String',num2str(fwhmX));
set(handles.fwhmYEdit,'String',num2str(fwhmY));

% backup results
handles.results.beads = beads; handles.results.psfEstimation = psfEstimation;
handles.results.fwhmX = fwhmX; handles.results.fwhmY = fwhmY;

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
results = handles.results;
save('results.mat','-struct','results');


% --- Executes on button press in exitButton.
function exitButton_Callback(hObject, eventdata, handles)
% hObject    handle to exitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.mainFigure);


function logText_Callback(hObject, eventdata, handles)
% hObject    handle to logText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of logText as text
%        str2double(get(hObject,'String')) returns contents of logText as a double


% --- Executes during object creation, after setting all properties.
function logText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to logText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in logListbox.
function logListbox_Callback(hObject, eventdata, handles)
% hObject    handle to logListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns logListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from logListbox


% --- Executes during object creation, after setting all properties.
function logListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to logListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in colormapPopup.
function colormapPopup_Callback(hObject, eventdata, handles)
% hObject    handle to colormapPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns colormapPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from colormapPopup
contents = cellstr(get(hObject,'String'));
colormap(contents{get(hObject,'Value')});


% --- Executes during object creation, after setting all properties.
function colormapPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to colormapPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in clearButton.
function clearButton_Callback(hObject, eventdata, handles)
% hObject    handle to clearButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.logListbox,'String',[]);


% --- Executes on button press in debugCheckbox.
function debugCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to debugCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of debugCheckbox


% --- Executes on selection change in psfPopupmenu.
function psfPopupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to psfPopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns psfPopupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from psfPopupmenu


% --- Executes during object creation, after setting all properties.
function psfPopupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to psfPopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
