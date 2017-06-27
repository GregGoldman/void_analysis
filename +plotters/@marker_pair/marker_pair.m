classdef marker_pair
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
        marker_index
        start_handle
        end_handle
        comment
        vv
        vt
        certainty
    end
    
    methods
        function obj = marker_pair(marker_index, start_handle, end_handle)
            
        end
    end
    methods % set methods
        
    end
    
end

