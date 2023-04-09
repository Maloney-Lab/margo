function expmt = run_circadian(expmt,gui_handles)

% Initialization: Get handles and set default preferences

gui_notify(['executing ' mfilename '.m'],gui_handles.disp_note);

% clear memory
clearvars -except gui_handles expmt trackDat

% get image handle
imh = findobj(gui_handles.axes_handle,'-depth',3,'Type','image');  


%% Experimental Setup

% Initialize tracking variables
trackDat.fields={'centroid';'area';'time';'Light';'Motor'};

% initialize labels, files, and cam/video
[trackDat,expmt] = autoInitialize(trackDat,expmt,gui_handles);

% lastFrame = false until last frame of the last video file is reached
trackDat.lastFrame = false;

%% Circadian specific parameters

%Initialize vibration parameters
trackDat.vib.stat = 0;              % is vibrating
trackDat.vib.prev = 0;              % was vibrating
trackDat.vib.ct = 0;                % current vibration trial num
trackDat.vib.t = 0;                 % interval between vibrations
trackDat.pulse.stat = 0;            % is pulsing
trackDat.pulse.ct = 0;
trackDat.pulse.prev = 0;
trackDat.ramp.stat = false;
trackDat.ramp.ct = 0;
trackDat.ramp.t = 0;


%% Determine position in light/dark cycle and initialize white light

t=clock;            % grab current time
t=t(4:5);           % grab hrs and min only

if numel(expmt.parameters.lights_ON)~=2 || numel(expmt.parameters.lights_OFF)~=2
   error('Invalid time format in Lights_ON/Lights_OFF'); 
end

if ~isfield(expmt.parameters,'lights_ON')
    expmt.parameters.lights_ON = [10 0];
end
if ~isfield(expmt.parameters,'lights_OFF')
    expmt.parameters.lights_OFF = [22 0];
end
if expmt.parameters.lights_ON(1)<=t(1) && expmt.parameters.lights_OFF(1)>=t(1)
    
    hour_match = expmt.parameters.lights_ON(1) == t(1);
    after_light_min = t(2) >= expmt.parameters.lights_ON(2);
    turn_ON = ~hour_match | (hour_match & after_light_min);
    
    if turn_ON
        trackDat.Light = uint8(expmt.hardware.light.white);
        expmt.hardware.COM.writeLightPanel(LightPanelPins.WHITE, trackDat.Light);
        trackDat.light.stat=1;
    else
        trackDat.Light = uint8(0);
        expmt.hardware.COM.writeLightPanel(LightPanelPins.WHITE, 0);
        trackDat.light.stat=0;
    end
else
        trackDat.Light = uint8(0);
        expmt.hardware.COM.writeLightPanel(LightPanelPins.WHITE, 0);
        trackDat.light.stat=0;
end

if expmt.hardware.light.white < 1
    warning('Circadian white light value is zero');
    gui_notify('WARNING: Circadian white light value = zero',gui_handles.disp_note);
end

%% Main Experimental Loop

% run experimental loop until duration is exceede d or last frame
% of the last video file is reached
while ~trackDat.lastFrame
    
    % update time stamps and frame rate
    [trackDat] = autoTime(trackDat, expmt, gui_handles);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat,expmt,gui_handles);

    % track, sort to ROIs, output optional fields set during intialization
    % and compare noise to the noise distribution measured during sampling
    trackDat = autoTrack(trackDat,expmt,gui_handles);

    % update motor and light panel
    trackDat = updateCircadian(trackDat,expmt,gui_handles);

    % output data tracked fields to binary files  
    [trackDat,expmt] = autoWriteData(trackDat, expmt, gui_handles);


    % update ref at the reference frequency or reset if noise thresh is exceeded
    [trackDat, expmt] = autoReference(trackDat, expmt, gui_handles);  

    % set image data
    trackDat = autoDisplay(trackDat, expmt, imh, gui_handles);
    
end



