classdef void_marker < handle
    %
    %   Class:
    %   plotters.void_marker
    %
    %   A line object which can also keep track of which marker it is in
    %   the list
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
        marker_type
        marker_handle
    end
    methods
        function obj = void_marker(marker_index, marker_type, marker_handle)
            obj.marker_index = marker_index;
            obj.marker_type = marker_type;
            obj.marker_handle = marker_handle;
        end
    end
end