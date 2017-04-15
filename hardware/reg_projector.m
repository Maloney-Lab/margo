function reg_projector(expmt,handles)

% This function registers the projector to the camera by rastering the
% projector's space with a circle of radius (r), taking steps of size (stp_sz) in
% pixels with a pause of stp_t in between steps. The camera automatically detects the location of the spot and
% uses camera and projector coordinate pairs for the spot to create
% scattered interpolants of the space in both x (Fx) and y (Fy). The 
% function outputs these interpolants to a file that is subsequently used
% to target specific points in the camera's field of view.

%% Parameters

stp_sz = expmt.reg_params.pixel_step_size;
r = expmt.reg_params.spot_r;
screenNumber = expmt.reg_params.screen_num;

%% Estimate camera frame rate

[frameRate, expmt.camInfo] = estimateFrameRate(expmt.camInfo);

%% Initialize the camera with settings tailored to imaging the projector

if ~isfield(expmt.camInfo,'vid') || strcmp(expmt.camInfo.vid.Running,'off')
    imaqreset
    pause(0.1);
    expmt.camInfo = initializeCamera(expmt.camInfo);
    start(expmt.camInfo.vid);
    pause(0.1);
end

% Initialize the psychtoolbox window and query projector properties
bg_color=[0 0 0];
scrProp=initialize_projector(screenNumber,bg_color);
pause(2);

%% Query cam resolution and collect reference image

ref=peekdata(expmt.camInfo.vid,1);
if size(ref,3)>1
    ref=ref(:,:,2);
end

% Save the camera resolution that the registration was performed at
[reg_yPixels,reg_xPixels] = size(ref);


%% Set registration parameters

xPixels=scrProp.windowRect(3);
yPixels=scrProp.windowRect(4);
x_stp=floor(xPixels/stp_sz);        % num steps in x
y_stp=floor(yPixels/stp_sz);        % num steps in y
white=[1 1 1];                      % color of the spot
im_thresh=30;                       % image threshold
subim_sz=10;                        % Radius of the extracted image ROI
min_area = ((mean(size(ref)))*0.01)^2;
max_area = ((mean(size(ref)))*0.05)^2;

% Initialize cam/projector coord placeholders
cam_x=NaN(y_stp,x_stp);
cam_y=NaN(y_stp,x_stp);
proj_x=NaN(y_stp,x_stp);
proj_y=NaN(y_stp,x_stp);

iTime=NaN(15,1);

%% Calculate display delay

% cam midpoint                             
mid = expmt.camInfo.vid.VideoResolution./2;

% get white reference
Screen('FillRect',scrProp.window,[1 1 1], scrProp.windowRect);
Screen('Flip',scrProp.window);
pause(0.5);
im = peekdata(expmt.camInfo.vid,1);
white = double(median(median(im(mid(1)-50:mid(1)+50,mid(2)-50:mid(2)+50,1))));

% black reference
Screen('FillRect',scrProp.window,[0 0 0], scrProp.windowRect);
Screen('Flip',scrProp.window);
pause(0.5);
im = peekdata(expmt.camInfo.vid,1);
black = double(median(median(im(mid(1)-50:mid(1)+50,mid(2)-50:mid(2)+50,1))));
not_white = true;  
blank = false;

% fill screen with white
Screen('FillRect',scrProp.window,[1 1 1], scrProp.windowRect);
Screen('Flip',scrProp.window);

% initialize time stamps
t = 0;
tic;
tPrev = toc;

while not_white
    
    tCurr = toc;
    t = t + tCurr - tPrev;
    tPrev = tCurr;
    im = peekdata(expmt.camInfo.vid,1);
    lum = double(median(median(im(mid(1)-50:mid(1)+50,mid(2)-50:mid(2)+50,1))));
    not_white = abs(lum - black) < abs(lum - white);
    
end

% black reference
Screen('FillRect',scrProp.window,[0 0 0], scrProp.windowRect);
Screen('Flip',scrProp.window);

delay = t*1.5;

%% clear axes objects and initialize marker and text objects

clean_gui(handles.axes_handle);
hold on
hTitle = text(handles.axes_handle.XLim(2)*0.05,handles.axes_handle.YLim(2)*0.05,...
    'Registration in progress','fontsize',12,'Color',[1 0 0]);
hMark = plot(0,0,'ro');
hText = text(0,0,'','Color',[1 0 0],'fontsize',14);
hold off


%% Registration loop

% Initialize both x and y to zero and raster the projector
x=0;
shg
tic
tPrev = toc;
for i=1:x_stp
    y=0;
    for j=1:y_stp
        
        tCurr = toc;
        ifi = tCurr-tPrev;
        while ifi < 1/frameRate
            tCurr = toc;
            ifi = tCurr-tPrev;
        end
        tPrev = tCurr;
        
        % Draw circle with projector at pixel coords x,y
        scrProp=drawCircles(x,y,r,white,scrProp);     
        pause(delay);
        
        % Image spot with cam
        im=peekdata(expmt.camInfo.vid,1);
        if size(im,3)>1
            im=im(:,:,2);
        end
        im=im-ref;
        
        % Extract centroid of spot
        props=regionprops(im>im_thresh,'Centroid','Area');
        props=props([props.Area]>min_area & [props.Area]<max_area);
        
        % Further process the centroid if spot detected
        if ~isempty([props.Centroid]) && length([props.Centroid])==2
            
            % Calculate center of mass using roi detected for the spot
            cenDat=round([props.Centroid]);
            yi=cenDat(2)-subim_sz:cenDat(2)+subim_sz;
            xi=cenDat(1)-subim_sz:cenDat(1)+subim_sz;
            if max(yi)<reg_yPixels+1 && min(yi)>0 && max(xi)<reg_xPixels+1 && min(xi)>1
                
                subim=im(yi,xi);
                subim=double(subim);
                subim=subim./sum(sum(subim));

                % Save camera coordinates of the spot
                cam_x(j,i)=sum(sum(subim).*xi);
                cam_y(j,i)=sum(sum(subim,2).*yi');

                % Reset axes and display tracking
                handles.hImage.CData = im>im_thresh;
                hMark.XData = cam_x(j,i);
                hMark.YData = cam_y(j,i);
                hText.Position = [cam_x(j,i),cam_y(j,i)+20];
                hText.String = ['(' num2str(round(cam_x(j,i)*10)/10) ...
                    ',' num2str(round(cam_y(j,i)*10)/10) ')'];
                
                if strcmp(hMark.Visible,'off')
                    hMark.Visible = 'on';
                    hText.Visible = 'on';
                end
                
                drawnow
            end
        else
            handles.hImage.CData = im>im_thresh;
            if strcmp(hMark.Visible,'on')
                hMark.Visible = 'off';
                hText.Visible = 'off';
            end
            drawnow
        end
        
        % Save projector coordinates of spot
        proj_x(j,i)=x;
        proj_y(j,i)=y;
        
        % Advance y by stp_sz pixels
        y = y + stp_sz;
        iCount=(i-1)*y_stp+j;
        
        iTime(mod(iCount,length(iTime))+1)=ifi;
        if iCount >= length(iTime)
            timeRemaining = round(mean(iTime)*(x_stp*y_stp-iCount));
                if timeRemaining < 60; 
                    set(handles.edit_time_remaining, 'String', ['00:00:' sprintf('%0.2d',timeRemaining)]);
                    set(handles.edit_time_remaining, 'BackgroundColor', [1 0.4 0.4]);
                elseif (3600 > timeRemaining) && (timeRemaining > 60);
                    minute = floor(timeRemaining/60);
                    sec = rem(timeRemaining, 60);
                    set(handles.edit_time_remaining, 'String', ['00:' sprintf('%0.2d',minute) ':' sprintf('%0.2d',sec)]);
                    set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
                elseif timeRemaining > 3600;
                    hr = floor(timeRemaining/3600);
                    minute = floor(rem(timeRemaining, 3600)/60);
                    sec = timeRemaining - hr*3600 - minute*60;
                    set(handles.edit_time_remaining, 'String', [sprintf('%0.2d', hr) ':' sprintf('%0.2d',minute) ':' sprintf('%0.2d',sec)]);
                    set(handles.edit_time_remaining, 'BackgroundColor', [1 1 1]);
                end
        end
        clearvars im props subim
    end
    
    % Advance x by stp_sz pixels
    x = x + stp_sz;
    
end

% Image spot with cam
hTitle.String = 'Registration complete';

% Exclude projector/camera coord pairs where spot was not detected by cam
include=~isnan(cam_x);
proj_x=proj_x(include);
proj_y=proj_y(include);
cam_x=cam_x(include);
cam_y=cam_y(include);

% Create scattered interpolant and save to HDD
Fx=scatteredInterpolant(cam_x,cam_y,proj_x);
Fy=scatteredInterpolant(cam_x,cam_y,proj_y);

reg_data.Fx = Fx;
reg_data.Fy = Fy;
reg_data.cam_xPixels = reg_xPixels;
reg_data.cam_yPixels = reg_yPixels;
reg_data.cam_xCoords = cam_x;
reg_data.cam_yCoords = cam_y;
reg_data.proj_xCoords = proj_x;
reg_data.proj_yCoords = proj_y;

if exist([handles.gui_dir 'hardware\projector_fit\'])
    save([handles.gui_dir 'hardware\projector_fit\projector_fit.mat'],'reg_data');
else
    mkdir([handles.gui_dir 'hardware\projector_fit\']);
    save([handles.gui_dir 'hardware\projector_fit\projector_fit.mat'],'reg_data');
end

% close open projector window
sca
    

