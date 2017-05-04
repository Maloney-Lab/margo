function [varargout] = extractOptoTraces(include,expmt,speed)

% Find indices of stimulus ON/OFF transitions
[~,iOFFc]=find(diff(include)==-1);
nTrials=NaN(expmt.nTracks,1);

for i=1:expmt.nTracks
    nTrials(i)=sum(iOFFc==i);           % number of stim presentations for each animal
end

[iONr,iONc]=find(diff(include)==1);     % OFF to ON
iONr=iONr+1;
[iOFFr,~]=find(diff(include)==-1);      % ON to OFF
iOFFr=iOFFr+1;

% Stimulus triggered averaging of each stimulus bout
win_sz = expmt.parameters.stim_int;                         % Size of the window on either side of the stimulus in sec
win_start=NaN(size(iONr,1),expmt.nTracks);
win_stop=NaN(size(iOFFr,1),expmt.nTracks);
tElapsed = cumsum(expmt.Time.data);                         % time elapsed @ each frame      
search_win = round(win_sz/nanmean(expmt.Time.data)*1.5);    % window around stim Off->On index to search for best tStamp


% Start by finding tStamps win_sz on either side of stim ON->OFF index
for i=1:expmt.nTracks
    
    idx = iONr(iONc==i);                % frame indices of transitions for current fly
    tStamps=tElapsed(idx);              % tStamps of stim OFF -> ON
    tON=tStamps-win_sz;                 % tStamps of edges of the stim-centered window
    tOFF=tStamps+win_sz;
    
    % find frames with the closest matching tStamps for the window edges
    lbs = idx - search_win;             % narrow search to nearby indices to speed up search
    lbs(lbs<1) = 1;
    ubs = idx + search_win;
    ubs(ubs>length(tElapsed)) = length(tElapsed);

    for j = 1:length(lbs)
        
        [v,start] = min(abs(tElapsed(lbs(j):ubs(j)) - tON(j)));     % time diff to window start
        [v,stop] = min(abs(tElapsed(lbs(j):ubs(j)) - tOFF(j)));     % time diff to window stop
        win_start(j,i)=start + lbs(j) - 1;
        win_stop(j,i)=stop + lbs(j) - 1;
        
    end
    
    clearvars start stop tON tOFF tStamps
end

clearvars tElapsed iONc iONr iOFFc iOFFr
win_start(sum(~isnan(win_start),2)==0,:)=[];
win_stop(sum(~isnan(win_stop),2)==0,:)=[];

nPts=max(max(win_stop-win_start));                  % max number of frames out of all windows
cumang=NaN(nPts,size(win_start,1),expmt.nTracks);   % intialize cumulative change in angle placeholder

% get change in angle at each frame
turning=expmt.Orientation.data;
turning=diff(turning);
turning = [zeros(1,size(turning,2));turning];       % pad first frame with zero to equal total frame number

% shift all values to be between -180 and 180 (from 360->0 single frame
% artifacts), and adjust all values to be with respect to the stimulus such
% that all turns in the direction of the stimulus rotation are negative
turning(turning>90) = turning(turning>90) - 180;    
turning(turning<-90) = turning(turning<-90) + 180;
turning(expmt.Texture.data&include)=-turning(expmt.Texture.data&include);

tdist = turning;
tdist(~include)=NaN;
tmp_r = nansum(tdist);
tmp_tot = nansum(abs(tdist));
avg_index = tmp_r./tmp_tot;
total_dist=NaN(size(win_start,1),expmt.nTracks);
stimdir_dist=NaN(size(win_start,1),expmt.nTracks);


t0=round(nPts/2);
off_spd=NaN(expmt.nTracks,1);
on_spd=NaN(expmt.nTracks,1);


for i=1:expmt.nTracks
    
    off_spd(i)=nanmean(speed(~include(:,i),i));
    on_spd(i)=nanmean(speed(include(:,i),i));
    
    % Integrate change in heading angle over the entire stimulus bout
    for j=1:sum(~isnan(win_start(:,i)))
        
        tmpTurn=turning(win_start(j,i):win_stop(j,i),i);
        tmp_tdist=tdist(win_start(j,i):win_stop(j,i),i);
        stimdir_dist(j,i) = nansum(tmp_tdist);
        total_dist(j,i) = nansum(abs(tmp_tdist));

        if ~isempty(tmpTurn)
            tmpTurn=interp1(1:length(tmpTurn),tmpTurn,linspace(1,length(tmpTurn),nPts));
            if nanmean(speed(win_start(j,i):win_stop(j,i),i))>0.1
            cumang(1:t0,j,i)=cumsum(tmpTurn(1:t0));
            cumang(t0+1:end,j,i)=cumsum(tmpTurn(t0+1:end));
            end
        end
    end
end

for i = 1:nargout
    switch i
        case 1, varargout{i}=cumang;
        case 2, varargout{i}=avg_index;
        case 3, varargout{i}=nTrials;
        case 4, varargout{i}=stimdir_dist;
        case 5, varargout{i}=total_dist;
    end
end



%{
function [cumang,opto_index]=getOptoIndex(t,inc,wst,wsp,spd,nPts,t0)

off_spd = nanmean(spd{:}(~inc{:}));
on_spd = nanmean(spd{:}(inc{:}));

idx = num2cell([wst{:}(~isnan(wst{:})) wsp{:}(~isnan(wsp{:}))],2);
[cumang,opto_index] = arrayfun(@(k) extractSingleBout(k,t,spd,nPts,t0),...
    idx,'UniformOutput',false);
opto_index = [opto_index{:}];


% Integrate change in heading angle over the entire stimulus bout
function [cumang,opto_index] = extractSingleBout(idx,t,spd,nPts,t0)

tmp_t=t{:}(idx{:}(1):idx{:}(2));

if ~isempty(tmp_t)
    
    tmp_t=interp1(1:length(tmp_t),tmp_t,linspace(1,length(tmp_t),nPts));
    cumang = NaN(size(tmp_t));
    
    if nanmean(spd{:}(idx{:}(1):idx{:}(2)))>0.1
        cumang(1:t0)=cumsum(tmp_t(1:t0));
        cumang(t0+1:end)=cumsum(tmp_t(t0+1:end));
        tmp_r = nansum(tmp_t);
        tmp_tot = nansum(abs(tmp_t));
        opto_index = tmp_r./tmp_tot;
    else
        cumang = [];
        opto_index = NaN;
    end
end
%}




