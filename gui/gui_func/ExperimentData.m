classdef ExperimentData < handle
% class definition for the expmt master data container which contains
% experiment meta data and memmaps for raw data files
    
    properties
        data;
        meta;
        parameters;
        hardware;
    end
    methods
        function obj = ExperimentData
            
            es = struct();
            obj.data = struct('centroid',RawDataField('Parent',obj),...
                'time',RawDataField('Parent',obj));
            obj.meta = struct('name','Basic Tracking','fields',[],'path',es,...
                            'source','camera','roi',es,'ref',es,'noise',es,...
                            'date','','strain','','treatment','','sex','',...
                            'labels',[],'labels_table',table);
            obj.hardware = struct('camInfo',es,'com',es,...
                                'light',es,'projector',es);
            obj.meta.fields = fieldnames(obj.data);
            obj.parameters = initialize_parameters(obj);
            
            
            
        end
        
        
        function obj = updatepaths(obj,fpath)
            
            [dir,name,~] = fileparts(fpath);
            obj.meta.path.dir   =   [dir '\'];
            obj.meta.path.name  =   name;

            % get binary files
            rawpaths = getHiddenMatDir(dir,'ext','.bin');
            [~,rawnames] = cellfun(@fileparts, rawpaths, ...
                                        'UniformOutput',false);
            
            for i=1:length(obj.meta.fields)
                
                % match to time/date and field name
                f = obj.meta.fields{i};
                fmatch = cellfun(@(x) any(strfind(x,f)),rawnames);
                tmatch = cellfun(@(x) any(strfind(x,obj.meta.date)),rawnames);
                
                if any(fmatch & tmatch)
                    match_idx = find(fmatch & tmatch,1,'first');
                    obj.data.(f).path = rawpaths{match_idx};
                else
                    warning(sprintf('raw data file for field %s not found\n',f));
                end
                
            end
        end
        
        % initialize all raw data maps
        function obj = attach(obj) 
            fn = fieldnames(obj.data);
            for i=1:length(obj.meta.fields)
                attach(obj.data.(fn{i}));
            end
        end
        
        % de-initialize all raw data maps
        function obj = detach(obj) 
            fn = fieldnames(obj.data);
            for i=1:length(obj.meta.fields)
                obj.data.(fn{i}).map = [];
            end
        end
        
        function p = initialize_parameters(~)
            p = struct();
            p.duration          = 2;
            p.ref_depth         = 3;
            p.ref_freq          = 0.5000;
            p.roi_thresh        = 45.5000;
            p.track_thresh      = 15;
            p.speed_thresh      = 95;
            p.distance_thresh   = 60;
            p.vignette_sigma    = 0.4700;
            p.vignette_weight   = 0.3500;
            p.area_min          = 4;
            p.area_max          = 100;
            p.target_rate       = 30;
            p.mm_per_pix        = 1;
            p.units             = 'pixels';
            p.roi_mode          = 'auto';
            p.sort_mode         = 'bounds';
            p.roi_tol           = 2.5000;
            p.edit_rois         = 0;
            p.dilate_sz         = 0;
        end
            
        
        
    end
    methods(Static)
        
        function obj = loadobj(obj)
            
            % auto update path         
            if isvalid(obj)
                try
                    fpath = evalin('caller','filename');
                catch
                    fpath = evalin('caller','fileAbsolutePath');
                end
                obj = updatepaths(obj,fpath);
            else
                warning('automatic filepath update failed');
            end

            
        end
        
    end
    
    
    
    
    
end