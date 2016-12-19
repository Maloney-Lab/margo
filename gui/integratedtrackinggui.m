function varargout = integratedtrackinggui(varargin)
% INTEGRATEDTRACKINGGUI MATLAB code for integratedtrackinggui.fig
%      INTEGRATEDTRACKINGGUI, by itself, creates a new INTEGRATEDTRACKINGGUI or raises the existing
%      singleton*.
%
%      H = INTEGRATEDTRACKINGGUI returns the handle to a new INTEGRATEDTRACKINGGUI or the handle to
%      the existing singleton*.
%
%      INTEGRATEDTRACKINGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INTEGRATEDTRACKINGGUI.M with the given input arguments.
%
%      INTEGRATEDTRACKINGGUI('Property','Value',...) creates a new INTEGRATEDTRACKINGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before integratedtrackinggui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to integratedtrackinggui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help integratedtrackinggui

% Last Modified by GUIDE v2.5 15-Dec-2016 17:55:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @integratedtrackinggui_OpeningFcn, ...
                   'gui_OutputFcn',  @integratedtrackinggui_OutputFcn, ...
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


% --- Executes just before integratedtrackinggui is made visible.
function integratedtrackinggui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to integratedtrackinggui (see VARARGIN)

% Choose default command line output for integratedtrackinggui
handles.output = hObject;
set(handles.ROI_thresh_slider,'value',40);
set(gca,'Xtick',[],'Ytick',[]);
exp = [];

% Query available camera and modes
imaqreset
c = imaqhwinfo;

if length(c.InstalledAdaptors)>0
    % Select appropriate adaptor for connected camera
    for i = 1:length(c.InstalledAdaptors)
        camInfo = imaqhwinfo(c.InstalledAdaptors{i});
        if ~isempty(camInfo.DeviceIDs)
            adaptor = i;
        end
    end
    if exist('adaptor')
        camInfo = imaqhwinfo(c.InstalledAdaptors{adaptor});
    end

    % Set the device to default format and populate pop-up menu
    if ~isempty(camInfo.DeviceInfo);
    set(handles.Cam_popupmenu,'String',camInfo.DeviceInfo.SupportedFormats);
    default_format = camInfo.DeviceInfo.DefaultFormat;

        for i = 1:length(camInfo.DeviceInfo.SupportedFormats)
            if strcmp(default_format,camInfo.DeviceInfo.SupportedFormats{i})
                set(handles.Cam_popupmenu,'Value',i);
                camInfo.ActiveMode = camInfo.DeviceInfo.SupportedFormats(i);
            end
        end

    else
    set(handles.Cam_popupmenu,'String','Camera not detected');
    end
    exp.camInfo = camInfo;
else
    exp.camInfo=[];
    set(handles.Cam_popupmenu,'String','No camera adaptors installed');
end
    


% Initialize teensy for motor and light board control

%Close and delete any open serial objects
if ~isempty(instrfindall)
fclose(instrfindall);           % Make sure that the COM port is closed
delete(instrfindall);           % Delete any serial objects in memory
end

% Attempt handshake with light panel teensy
[exp.teensy_port,ports] = identifyMicrocontrollers;

% Update GUI menus with port names
set(handles.microcontroller_popupmenu,'string',exp.teensy_port);

% Initialize light panel at default values
IR_intensity = str2num(get(handles.edit_IR_intensity,'string'));
White_intensity = str2num(get(handles.edit_White_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
exp.IR_intensity = uint8((IR_intensity/100)*255);
exp.White_intensity = uint8((White_intensity/100)*255);

% Write values to microcontroller
writeInfraredWhitePanel(exp.teensy_port,1,exp.IR_intensity);
writeInfraredWhitePanel(exp.teensy_port,0,exp.White_intensity);

% Initialize experiment parameters from text boxes in the GUI
exp.ref_stack_size  =  str2num(get(handles.edit_ref_stack_size,'String')); %#ok<*ST2NM>
exp.ref_freq = str2num(get(handles.edit_ref_freq,'String'));
exp.duration = str2num(get(handles.edit_exp_duration,'String'));
exp.ROI_thresh = get(handles.ROI_thresh_slider,'Value');
exp.tracking_thresh = get(handles.track_thresh_slider,'Value');
exp.speed_thresh = 45;
exp.distance_thresh = 20;
exp.vignette_sigma = 0.47;
exp.vignette_weight = 0.35;

if ~isempty(exp.camInfo)
    exp.target_rate = estimateFrameRate(exp.camInfo);
    exp.camInfo.Gain = str2num(get(handles.edit_gain,'String'));
    exp.camInfo.Exposure = str2num(get(handles.edit_exposure,'String'));
    exp.camInfo.Shutter = str2num(get(handles.edit_cam_shutter,'String'));
end

setappdata(handles.figure1,'expData',exp);

% Update handles structure
guidata(hObject,handles);

% UIWAIT makes integratedtrackinggui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = integratedtrackinggui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;






%-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-* -%
%-*-*-*-*-*-*-*-*-*-*-*-CAMERA FUNCTIONS-*-*-*-*-*-*-*-*-*-*-*-*%
%-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*%




% --- Executes on selection change in Cam_popupmenu.
function Cam_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

exp = getappdata(handles.figure1,'expData');

strCell = get(handles.Cam_popupmenu,'string');
exp.camInfo.ActiveMode = strCell(get(handles.Cam_popupmenu,'Value'));
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function Cam_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Cam_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Cam_confirm_pushbutton.
function Cam_confirm_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_confirm_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

if exist(exp.camInfo.DeviceInfo)
    if ~isempty(exp.camInfo.DeviceInfo)
        cla reset
        imaqreset;
        pause(0.02);
        exp.vid = initializeCamera(exp.camInfo);
        exp.src = getselectedsource(exp.vid);
        start(exp.vid);
        pause(0.5);
        im = peekdata(exp.vid,1);
        handles.hImage = image(im);
        set(gca,'Xtick',[],'Ytick',[]);
        stop(exp.vid);
    else
        errordlg('Settings not confirmed, no camera detected');
    end
else
    errordlg('No cameras adaptors installed');
end

guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);



% --- Executes on button press in Cam_preview_pushbutton.
function Cam_preview_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_preview_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

if isfield(exp, 'vid') == 0
    errordlg('Please confirm camera settings')
else
    preview(exp.vid,handles.hImage);       
end

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes on button press in Cam_stopPreview_pushbutton.
function Cam_stopPreview_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Cam_stopPreview_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

set(handles.Cam_preview_pushbutton,'Value',0);
set(handles.Cam_stopPreview_pushbutton,'Value',0);
stoppreview(exp.vid);
rmfield(handles,'src');
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);

function edit_exposure_Callback(hObject, eventdata, handles)
% hObject    handle to edit_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');
exp.camInfo.Exposure = str2num(get(handles.edit_exposure,'String'));

% If video is in preview mode, update the camera immediately
if isfield(handles,'src')
    exp.src.Exposure = exp.camInfo.Exposure;
end

guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function edit_exposure_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_gain_Callback(hObject, eventdata, handles)
% hObject    handle to edit_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');
exp.camInfo.Gain = str2num(get(handles.edit_gain,'String'));

% If video is in preview mode, update the camera immediately
if isfield(handles,'src')
    exp.src.Gain = exp.camInfo.Gain;
end

guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function edit_gain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_cam_shutter_Callback(hObject, eventdata, handles)
% hObject    handle to edit_cam_shutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

exp.camInfo.Shutter = str2num(get(handles.edit_cam_shutter,'String'));

% If video is in preview mode, update the camera immediately
if isfield(handles,'src')
    exp.src.Shutter = exp.camInfo.Shutter;
end

guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);



% --- Executes during object creation, after setting all properties.
function edit_cam_shutter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_cam_shutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes on selection change in microcontroller_popupmenu.
function microcontroller_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to microcontroller_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns microcontroller_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from microcontroller_popupmenu


% --- Executes during object creation, after setting all properties.
function microcontroller_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to microcontroller_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_IR_intensity_Callback(hObject, eventdata, handles)
% hObject    handle to edit_IR_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Initialize light panel at default values

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

exp.IR_intensity = str2num(get(handles.edit_IR_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
exp.IR_intensity = uint8((exp.IR_intensity/100)*255);

writeInfraredWhitePanel(exp.teensy_port,1,exp.IR_intensity);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function edit_IR_intensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_IR_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_White_intensity_Callback(hObject, eventdata, handles)
% hObject    handle to edit_White_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

White_intensity = str2num(get(handles.edit_White_intensity,'string'));

% Convert intensity percentage to uint8 PWM value 0-255
exp.White_intensity = uint8((White_intensity/100)*255);
writeInfraredWhitePanel(exp.teensy_port,0,exp.White_intensity);

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_White_intensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_White_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in save_path_button1.
function save_path_button1_Callback(hObject, eventdata, handles)
% hObject    handle to save_path_button1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

[fpath]  =  uigetdir('E:\Decathlon Raw Data','Select a save destination');
exp.fpath = fpath;
set(handles.save_path,'String',fpath);
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);



function save_path_Callback(hObject, eventdata, handles)
% hObject    handle to save_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of save_path as text
%        str2double(get(hObject,'String')) returns contents of save_path as a double


% --- Executes during object creation, after setting all properties.
function save_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to save_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function labels_uitable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to labels_uitable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

data = cell(5,8);
data(:) = {''};
set(hObject, 'Data', data);
exp.labels = data;
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes when entered data in editable cell(s) in labels_uitable.
function labels_uitable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to labels_uitable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

exp.labels{eventdata.Indices(1), eventdata.Indices(2)} = {''};
exp.labels{eventdata.Indices(1), eventdata.Indices(2)} = eventdata.NewData;
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


function edit_ref_stack_size_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ref_stack_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
exp.ref_stack_size = str2num(get(handles.edit_ref_stack_size,'String'));
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function edit_ref_stack_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ref_stack_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ref_freq_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ref_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

exp.ref_freq = str2num(get(handles.edit_ref_freq,'String'));
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function edit_ref_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ref_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_exp_duration_Callback(hObject, eventdata, handles)
% hObject    handle to edit_exp_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

exp.duration = str2num(get(handles.edit_exp_duration,'String'));
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function edit_exp_duration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_exp_duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

if isfield(handles, 'fpath') == 0 
    errordlg('Please specify Save Location')
elseif isfield(handles, 'vid') == 0
    errordlg('Please confirm camera settings')
else
    switch exp.experiment
    	case 2
            projector_escape_response;
        case 3
            projector_optomotor;
        case 4
            projector_slow_phototaxis;
    end
end

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes on slider movement.
function ROI_thresh_slider_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_thresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

exp.ROI_thresh = get(handles.ROI_thresh_slider,'Value');
set(handles.disp_ROI_thresh,'string',num2str(uint8(exp.ROI_thresh)));
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function ROI_thresh_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROI_thresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in accept_ROI_thresh_pushbutton.
function accept_ROI_thresh_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_ROI_thresh_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

set(handles.accept_ROI_thresh_pushbutton,'value',1);
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);



function edit_frame_rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frame_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_frame_rate as text
%        str2double(get(hObject,'String')) returns contents of edit_frame_rate as a double


% --- Executes during object creation, after setting all properties.
function edit_frame_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frame_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in exp_select_popupmenu.
function exp_select_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to exp_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

exp.experiment = get(handles.exp_select_popupmenu,'Value');
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);

% Hints: contents = cellstr(get(hObject,'String')) returns exp_select_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from exp_select_popupmenu


% --- Executes during object creation, after setting all properties.
function exp_select_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to exp_select_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in begin_reg_button.
function begin_reg_button_Callback(hObject, eventdata, handles)
% hObject    handle to begin_reg_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');


% Turn infrared and white background illumination off during registration
writeInfraredWhitePanel(exp.teensy_port,1,0);
writeInfraredWhitePanel(exp.teensy_port,0,0);

msg_title = ['Projector Registration Tips'];
spc = [' '];
intro = ['Please check the following before continuing to ensure successful registration:'];
item1 = ['1.) Both the infrared and white lights for imaging illumination are set to OFF. '...
    'Make sure the projector is the only light source visible to the camera'];
item2 = ['2.) Camera is not imaging through infrared filter. '...
    'Projector display should be visible through the camera.'];
item3 = ['3.) Projector is turned on and set to desired resolution.'];
item4 = ['4.) Camera shutter speed is adjusted to match the refresh rate of the projector.'...
    ' This will appear as moving streaks in the camera if not properly adjusted.'];
item5 = ['5.) Both camera and projector are in fixed positions and will not need to be adjusted'...
    ' after registration.'];
closing = ['Click OK to continue with the registration'];
message = {intro spc item1 spc item2 spc item3 spc item4 spc item5 spc closing};

% Display registration tips
waitfor(msgbox(message,msg_title));

% Register projector
reg_projector(exp.camInfo,exp.pixel_step_size,exp.step_interval,exp.reg_spot_r,handles.edit_time_remaining);

% Reset infrared and white lights to prior values
writeInfraredWhitePanel(exp.teensy_port,1,exp.IR_intensity);
writeInfraredWhitePanel(exp.teensy_port,0,exp.White_intensity);

guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


function edit_time_remaining_Callback(hObject, eventdata, handles)
% hObject    handle to edit_time_remaining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_time_remaining as text
%        str2double(get(hObject,'String')) returns contents of edit_time_remaining as a double


% --- Executes during object creation, after setting all properties.
function edit_time_remaining_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_time_remaining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in exp_parameter_pushbutton.
function exp_parameter_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to exp_parameter_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

if exp.experiment<2
errordlg('Please select an experiment first')
else
    switch exp.experiment
        case 2

        case 3
             if isfield(exp,'parameters') && strcmp(exp.parameters.name,'Optomotor');
                tmp_param = optomotor_parameter_gui(exp.parameters);
                if ~isempty(tmp_param)
                    exp.parameters = tmp_param;
                end
            else
                tmp_param = optomotor_parameter_gui;
                if ~isempty(tmp_param)
                    exp.parameters = tmp_param;
                end
             end
             
             
        case 4                       
             if isfield(exp,'parameters') && strcmp(exp.parameters.name,'Slow Phototaxis');
                tmp_param = slowphototaxis_parameter_gui(exp.parameters);
                if ~isempty(tmp_param)
                    exp.parameters = tmp_param;
                end
            else
                tmp_param = slowphototaxis_parameter_gui;
                if ~isempty(tmp_param)
                    exp.parameters = tmp_param;
                end
             end
            
    end
end
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes on button press in refresh_COM_pushbutton.
function refresh_COM_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_COM_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Refresh items on the COM ports

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

   
% Attempt handshake with light panel teensy
[exp.teensy_port,ports] = identifyMicrocontrollers;

if ~isempty(ports)
% Update GUI menus with port names
set(handles.microcontroller_popupmenu,'string',exp.teensy_port);
else
set(handles.microcontroller_popupmenu,'string','COM not detected');
end

guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes on button press in enter_labels_pushbutton.
function enter_labels_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to enter_labels_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

if isfield(handles,'labels')
    tmp_lbl = label_subgui(handles.labels);
    if ~isempty(tmp_lbl)
        handles.labels = tmp_lbl;
    end
else
    tmp_lbl = label_subgui;
    if ~isempty(tmp_lbl)
        handles.labels = tmp_lbl;
    end
end

guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);




% --- Executes on slider movement.
function track_thresh_slider_Callback(hObject, eventdata, handles)
% hObject    handle to track_thresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

exp.tracking_thresh = get(handles.track_thresh_slider,'Value');
set(handles.disp_track_thresh,'string',num2str(round(exp.tracking_thresh*100)/100));
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function track_thresh_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to track_thresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in accept_track_thresh_pushbutton.
function accept_track_thresh_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to accept_track_thresh_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

set(handles.accept_track_thresh_pushbutton,'value',1);
guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes on button press in adv_track_param_pushbutton.
function adv_track_param_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to adv_track_param_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

tmp = advancedTrackingParam_subgui(exp);
if ~isempty(tmp)
    exp.speed_thresh = tmp.speed_thresh;
    exp.distance_thresh = tmp.distance_thresh;
    exp.target_rate = tmp.target_rate;
    exp.vignette_sigma = tmp.vignette_sigma;
    exp.vignette_weight = tmp.vignette_weight;
end
             
             % Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes on button press in set_dist_scale_pushbutton.
function set_dist_scale_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to set_dist_scale_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit_numObj_Callback(hObject, eventdata, handles)
% hObject    handle to edit_numObj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_numObj as text
%        str2double(get(hObject,'String')) returns contents of edit_numObj as a double


% --- Executes during object creation, after setting all properties.
function edit_numObj_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_numObj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_numROIs_Callback(hObject, eventdata, handles)
% hObject    handle to edit_numROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_numROIs as text
%        str2double(get(hObject,'String')) returns contents of edit_numROIs as a double


% --- Executes during object creation, after setting all properties.
function edit_numROIs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_numROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in begin_reg_pushbutton.
function begin_reg_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to begin_reg_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Turn infrared and white background illumination off during registration
writeInfraredWhitePanel(handles.teensy_port,1,0);
writeInfraredWhitePanel(handles.teensy_port,0,0);

msg_title = ['Projector Registration Tips'];
spc = [' '];
intro = ['Please check the following before continuing to ensure successful registration:'];
item1 = ['1.) Both the infrared and white lights for imaging illumination are set to OFF. '...
    'Make sure the projector is the only light source visible to the camera'];
item2 = ['2.) Camera is not imaging through infrared filter. '...
    'Projector display should be visible through the camera.'];
item3 = ['3.) Projector is turned on and set to desired resolution.'];
item4 = ['4.) Camera shutter speed is adjusted to match the refresh rate of the projector.'...
    ' This will appear as moving streaks in the camera if not properly adjusted.'];
item5 = ['5.) Both camera and projector are in fixed positions and will not need to be adjusted'...
    ' after registration.'];
closing = ['Click OK to continue with the registration'];
message = {intro spc item1 spc item2 spc item3 spc item4 spc item5 spc closing};

% Display registration tips
waitfor(msgbox(message,msg_title));

% Register projector
reg_projector(handles.camInfo,handles.pixel_step_size,handles.step_interval,handles.reg_spot_r,handles.edit_time_remaining);

% Reset infrared and white lights to prior values
writeInfraredWhitePanel(handles.teensy_port,1,handles.IR_intensity);
writeInfraredWhitePanel(handles.teensy_port,0,handles.White_intensity);

guidata(hObject, handles);


% --- Executes on button press in reg_param_pushbutton.
function reg_param_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to reg_param_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in reg_test_pushbutton.
function reg_test_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to reg_test_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in aux_COM_popupmenu.
function aux_COM_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to aux_COM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns aux_COM_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from aux_COM_popupmenu

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

% Update GUI menus with port names
set(handles.aux_COM_popupmenu,'string',ports);

guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes during object creation, after setting all properties.
function aux_COM_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aux_COM_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in refresh_aux_COM_pushbutton.
function refresh_aux_COM_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_aux_COM_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import experiment data struct
exp = getappdata(handles.figure1,'expData');

% Attempt handshake with light panel teensy
[lightBoardPort,ports] = identifyMicrocontrollers;

% Assign unidentified ports to LED ymaze menu
if ~isempty(ports)
handles.aux_COM_port = ports(1);
else
ports = 'COM not detected';
handles.aux_COM_port = {ports};
end

% Update GUI menus with port names
set(handles.aux_COM_popupmenu,'string',ports);

guidata(hObject,handles);

% Store experiment data struct
setappdata(handles.figure1,'expData',exp);


% --- Executes on selection change in param_prof_popupmenu.
function param_prof_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to param_prof_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns param_prof_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from param_prof_popupmenu


% --- Executes during object creation, after setting all properties.
function param_prof_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to param_prof_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_params_pushbutton.
function save_params_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to save_params_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)