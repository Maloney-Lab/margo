function vignetteMat=filterVignetting(expmt,varargin)

% Normalize the intensity of all the mazes to the maximum intensity
% of the dimmest ROI. Using that intensity value, this function generates
% a subtraction matrix that is subtracted off of each image. This
% dramatically improves the ability to apply a single threshold value to
% the image when detecting ROIs or tracking objects

% assign default values
roi_coords = [];
ref_im = [];
if isfield(expmt.meta.ref,'im')
    ref_im = expmt.meta.ref.im;
end

% parse variable inputs
for i=1:length(varargin)
    switch i
        case 1
            roi_coords = varargin{1};
        case 2
            ref_im = varargin{2};
    end
end

if isempty(ref_im)
    error('no image input for vignette correction');
end

% find dimmest ROI if no coords are specified
if isempty(roi_coords)
    
    switch expmt.meta.roi.mode
        case 'auto'
            sub_ims = cellfun(@(x) expmt.meta.ref.im(x),...
                            expmt.meta.roi.pixIdx,'UniformOutput',false);  
            sub_masks = cellfun(@(x) expmt.meta.roi.im(x),...
                            expmt.meta.roi.pixIdx,'UniformOutput',false); 
            above_thresh = find(cellfun(@sum,sub_masks) > 50);
            med_intensities = cellfun(@(x,y) median(x(y)),sub_ims, sub_masks,...
                                'UniformOutput',false); 
            [~,i] = min(cat(1,med_intensities{above_thresh}));
            dim_roi = above_thresh(i);
        case 'grid'
            sub_ims = cellfun(@(x) expmt.meta.ref.im(x),...
                            expmt.meta.roi.pixIdx,'UniformOutput',false);          
            mean_intensities = cellfun(@mean,sub_ims); 
            [~,dim_roi] = min(mean_intensities);
    end
    
    roi_coords = expmt.meta.roi.corners(dim_roi,:);
end

if isempty(roi_coords)
    error('roi coordinates are empty');
end

% extract roi image and find luminance threshold
roi_coords = round(roi_coords);
dim = size(ref_im);
roi_coords(roi_coords < 1) = 1;
oob = roi_coords(:,3) > dim(2);
roi_coords(oob,3) = dim(2);
oob = roi_coords(:,4) > dim(1);
roi_coords(oob,4) = dim(1);
sub_im=ref_im(roi_coords(2):roi_coords(4),roi_coords(1):roi_coords(3));
switch expmt.meta.roi.mode
    
    case 'auto'
        if isfield(expmt.meta.roi,'im')
            roi_sub = expmt.meta.roi.im(roi_coords(2):roi_coords(4),...
                                    roi_coords(1):roi_coords(3));
            lumOffset = nanFilteredMedian(sub_im(roi_sub));
        else
            lumOffset = nanFilteredMedian(sub_im(:));
        end
        
    case 'grid'
        lum_mu = nanFilteredMean(sub_im(:));
        lum_std = nanFilteredStd(double(sub_im(:)));
        lumOffset = lum_mu + lum_std;
end

% Create subtraction matrix which is everything above the maximum intensity
vignetteMat=ref_im-lumOffset;      