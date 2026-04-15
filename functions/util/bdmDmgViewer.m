function varargout = bdmDmgViewer(varargin)

% Oldest function required for translating photos into the ready .fig
% enviroment. Created back in 2015 by Vladimir Fedorov

% DMGVIEWER MATLAB code for dmgViewer.fig
%      DMGVIEWER, by itself, creates a new DMGVIEWER or raises the existing
%      singleton*.
%
%      H = DMGVIEWER returns the handle to a new DMGVIEWER or the handle to
%      the existing singleton*.
%
%      DMGVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DMGVIEWER.M with the given input arguments.
%
%      DMGVIEWER('Property','Value',...) creates a new DMGVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before dmgViewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to dmgViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%

% Begin initialization code 
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dmgViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @dmgViewer_OutputFcn, ...
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
% End initialization code

% Executes just before dmgViewer is made visible.
function dmgViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to dmgViewer (see VARARGIN)

% Choose default command line output for dmgViewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes dmgViewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Outputs from this function are returned to the command line.
function varargout = dmgViewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, hAx)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
