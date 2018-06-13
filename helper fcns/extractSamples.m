function [obj_ims, bg_ims] = extractSamples(trackDat, expmt, extract, window)

% extract image containing object
obj_ims = arrayfun(@(x,y) ...
    trackDat.im(floor(y-window:y+window),floor(x-window:x+window)),...
    trackDat.Centroid(extract,1),trackDat.Centroid(extract,2),...
    'UniformOutput',false);
            
% extract same region containing only background            
bg_ims = arrayfun(@(x,y) ...
    expmt.ref.im(floor(y-window:y+window),floor(x-window:x+window)),...
    trackDat.Centroid(extract,1),trackDat.Centroid(extract,2),...
    'UniformOutput',false);





