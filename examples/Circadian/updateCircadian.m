function trackDat = updateCircadian(trackDat,expmt,gui_handles)

% Provides the frame by frame updates to the illumination and motors and all
% associated fields for the circadian imaging platform. Called from the
% main tracking loop of run_circadian.m

%% Pulse the vibrational motors at the specified in the interpulse interval

% check if inter-stimulus interval has been exceeded
int_exceeded = (trackDat.t-trackDat.vib.t) >...
    (1/expmt.parameters.pulse_per_hour*3600);

% if wait time is exceeded and light is OFF, pulse the motors
if  int_exceeded && trackDat.Light == 0
    gui_notify('initiating motor pulse',gui_handles.disp_note)
    trackDat.vib.stat = true;
    writeVibrationalMotors(expmt.hardware.COM.light,6,1,1,...
        expmt.parameters.pulse_num,expmt.parameters.pulse_amp);
    trackDat.vib.t=toc;
end

if trackDat.vib.stat && ...
        (trackDat.t-trackDat.vib.t) > (expmt.parameters.pulse_num*200*2)
    
    trackDat.vib.stat = false;
end
    
%% Update light/dark cycle

t=clock;            % grab current time
t=t(4:5);           % grab hrs and min only

% Turn light OFF if light's ON and t > lightsOFF time
if trackDat.light.stat && t(1)==expmt.parameters.lights_OFF(1)        
    if t(2)==expmt.parameters.lights_OFF(2)
        trackDat.light.stat=0;
        trackDat.ramp.stat = -1;
        trackDat.ramp.t = toc;
        trackDat.ramp.ct = 1;
        trackDat.ramp.int = zeros(1,expmt.hardware.light.white);
        gui_notify('lights ramping down',gui_handles.disp_note);
    end
% Turn light ON if light's OFF and t > lightsON time
elseif ~trackDat.light.stat && t(1)==expmt.parameters.lights_ON(1)             
    if t(2)==expmt.parameters.lights_ON(2) 
        trackDat.light.stat=1;
        trackDat.ramp.stat = 1;
        trackDat.ramp.t = toc;
        trackDat.ramp.ct = 1;
        trackDat.ramp.int = zeros(1,expmt.hardware.light.white);
        gui_notify('lights ramping up',gui_handles.disp_note);
    end
end
    
    %% Slowly ramp the light up or down to avoid startling the flies
    
if trackDat.ramp.stat && trackDat.ramp.ct > 0 && ...
        (trackDat.t-trackDat.ramp.t) > trackDat.ramp.int(trackDat.ramp.ct)

    if trackDat.ramp.stat == 1

        trackDat.Light = uint8(trackDat.ramp.ct);
        expmt.hardware.COM.writeLightPanel(LightPanelPins.WHITE, uint8(trackDat.ramp.ct));
        trackDat.ramp.t = toc;
        trackDat.ramp.ct = trackDat.ramp.ct+1;

        if trackDat.ramp.ct > expmt.hardware.light.white || ...
                trackDat.ramp.ct > numel(trackDat.ramp.int)
            trackDat.ramp.ct = numel(trackDat.ramp.int);
            trackDat.ramp.stat = 0;
            trackDat.Light = uint8(expmt.hardware.light.white);
            gui_notify('lights finished ramping up',gui_handles.disp_note);
        end

        tstr = gui_handles.disp_note.String{1};
        msg = tstr(find(tstr==')',1)+3:end);
        if strmatch('lights ramping up',msg)
            tstr = [tstr(1:find(tstr==')',1)+2) 'lights ramping up ('...
                num2str(trackDat.Light) ')'];
            gui_handles.disp_note.String{1} = tstr;
        else
            gui_notify(...
                sprintf('lights ramping up (%i)',trackDat.Light),...
                gui_handles.disp_note);
        end


    end
    if trackDat.ramp.stat == -1

        trackDat.Light = uint8(expmt.hardware.light.white-trackDat.ramp.ct);
        expmt.hardware.COM.writeLightPanel(LightPanelPins.WHITE, trackDat.Light);
        trackDat.ramp.t = toc;
        trackDat.ramp.ct = trackDat.ramp.ct+1;

        if trackDat.ramp.ct > expmt.hardware.light.white ||...
                trackDat.ramp.ct > numel(trackDat.ramp.int)
            trackDat.ramp.ct = numel(trackDat.ramp.int);
            trackDat.ramp.stat = 0;
            trackDat.Light = uint8(0);
            gui_notify('lights finished ramping up',gui_handles.disp_note);
        end

        tstr = gui_handles.disp_note.String{1};
        msg = tstr(find(tstr==')',1)+3:end);
        if strmatch('lights ramping down',msg)
            tstr = [tstr(1:find(tstr==')',1)+2) 'lights ramping down('...
                num2str(trackDat.Light) ')'];
            gui_handles.disp_note.String{1} = tstr;
        else
            gui_notify(...
                sprintf('lights ramping down (%i)',trackDat.Light),...
                gui_handles.disp_note);
        end

    end
end

trackDat.Motor = trackDat.vib.stat;