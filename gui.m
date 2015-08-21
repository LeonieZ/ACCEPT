function varargout = ACCEPT_GUI(varargin)
% ACCEPT_GUI MATLAB code for ACCEPT_GUI.fig
%      ACCEPT_GUI, by itself, creates a new ACCEPT_GUI or raises the existing
%      singleton*.
%
%      H = ACCEPT_GUI returns the handle to a new ACCEPT_GUI or the handle to
%      the existing singleton*.
%
%      ACCEPT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ACCEPT_GUI.M with the given input arguments.
%
%      ACCEPT_GUI('Property','Value',...) creates a new ACCEPT_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ACCEPT_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ACCEPT_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ACCEPT_GUI

% Last Modified by GUIDE v2.5 20-Aug-2015 16:23:52

%-------------------------------------------------------------------------

% Begin initialization code

% clc;
% % Add subdirectories to path
% file = which('ACCEPT_GUI.m');
% installDir = fileparts(file);
% addpath(genpath_exclude(installDir));
               
% create a base object as the main program controller, such that the
% batchmode or GUI can work with this
%base = Base();
%varargin{end+1} = base;

% initialize gui or batchmode
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ACCEPT_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ACCEPT_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);

% check arguments, e.g. to run in batchmode
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
% use the graphical interface for this session
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code

%-------------------------------------------------------------------------

% --- Executes if the batchmode of ACCEPT is activated.
%function batchmode(varargin)
%    display('batchmode started')

%-------------------------------------------------------------------------

% --- Executes just before ACCEPT_GUI is made visible.
function ACCEPT_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ACCEPT_GUI (see VARARGIN)

handles.base = varargin{1};
handles.base.show_logo;

% Choose default command line output for ACCEPT_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ACCEPT_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ACCEPT_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in chooseTask.
function chooseTask_Callback(hObject, eventdata, handles)
% hObject    handle to chooseTask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = cellstr(get(hObject,'String')); %returns chooseTask contents as cell array
contents{get(hObject,'Value')} %returns selected item from chooseTask


% --- Executes during object creation, after setting all properties.
function chooseTask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chooseTask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% initialize choose button for tasks
tasks = {'Feature extraction';'Dummy task 1'; 'Dummy task 2'};
set(hObject,'String',tasks);


% --- Executes on button press in processButton.
function processButton_Callback(hObject, eventdata, handles)
% hObject    handle to processButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
display('Process samples')


% --- Executes on button press in visualizeButton.
function visualizeButton_Callback(hObject, eventdata, handles)
% hObject    handle to visualizeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
display('Visualize samples')


% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
display('Load samples via base')
display(['The current program version is ', handles.base.programVersion])



%-------------------------------------------------------------------------

% Helper function
% function p = genpath_exclude(d)
%     % extension of the genpath function of matlab, inspired by the
%     % genpath_exclude.m written by jhopkin posted on matlab central.  We use
%     % a regexp to also exclude .git directories from our path.
%     
%     files = dir(d);
% 	if isempty(files)
% 	  return
% 	end
% 
% 	% Add d to the path even if it is empty.
% 	p = [d pathsep];
% 
% 	% set logical vector for subdirectory entries in d
% 	isdir = logical(cat(1,files.isdir));
% 	%
% 	% Recursively descend through directories which are neither
% 	% private nor "class" directories.
% 	%
% 	dirs = files(isdir); % select only directory entries from the current listing
% 
% 	for i=1:length(dirs)
% 		dirname = dirs(i).name;
% 		%NOTE: regexp ignores '.', '..', '@.*', and 'private' directories by default. 
% 		if ~any(regexp(dirname,'^\.$|^\.\.$|^\@*|^\+*|^\.git|^private$|','start'))
% 		  p = [p genpath_exclude(fullfile(d,dirname))]; % recursive calling of this function.
% 		end
% 	end
