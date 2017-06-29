classdef marker_pair < handle
    %
    %   Class:
    %   plotters.marker_pair
    %
    %   Stores the handles to the start and end marker points with related
    %   data
    %   
    %   Properties:
    %   -----------
    %   - marker_index: the index in the list help by the analysis_GUI
    %   - marker_type: either 'start' or 'end'
    %   - marker_handle: the handle to the line
    %
    %
    properties
        parent
        
        marker_index
        start_handle
        end_handle
        
        start_time
        end_time
        
        comment
        vv
        vt
        certainty
        
        is_initialized
    end
    
    methods
        function obj = marker_pair(parent, marker_index, start_handle, end_handle)
            obj.is_initialized = false;
            obj.parent = parent;
            obj.marker_index = marker_index;
            obj.start_handle = start_handle;
            obj.end_handle = end_handle;
            
            obj.start_time = obj.start_handle.XData;
            obj.end_time = obj.end_handle.XData;
            
            obj.is_initialized = true;
            obj.timeUpdated();
        end
    end
    methods 
        function timeUpdated(obj)
            if ~ obj.is_initialized
                return
            end
            vf = obj.parent.void_finder2;
            vd = vf.void_data;
            obj.vv = vd.getVV(obj.start_time, obj.end_time);
            obj.vt = vd.getVoidingTime(obj.start_time, obj.end_time);
            obj.certainty = vf.evaluateUncertainty('start_times', obj.start_time, 'end_times', obj.end_time);
        end
        function addComment(obj, comment)
            obj.comment = comment;
        end
        function clearLineObjs(obj)
            %
            %   deletes the line objects so that they no longer are an
            %   issue on the graph. The helper function in the analysis_GUI
            %   will take care of removing this object itself from the
            %   array of markers
            
            delete(obj.start_handle);
            delete(obj.end_handle);
        end
    end
    methods %set methods
        function set.start_time(obj, value)
            obj.start_time = value;
            obj.timeUpdated();
        end
        function set.end_time(obj,value)
            obj.end_time = value;
            obj.timeUpdated();
        end
    end
    
end

