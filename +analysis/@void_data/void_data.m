classdef void_data < handle
    
    %
    %   Class:
    %   analysis.void_data
    %
    %   Keeps track of user marker objects with start/stop times
    %   Keeps tack of computer-found marker times
    %   For each of these, finds/stores voided volume, voiding time, etc.
    %   
    %   Can plot the markers 
    
    This class can know how to plot itself.
    It can keep track of its starts and stops and the underlying data.
    It can hold the voided volume and voiding time data.
    whether or not a void is considered valid and why.
    %}
    
    
    properties
        h
        
        %markers
        cur_markers_idx             % array [start end]
        user_start_marker_obj       % marker object
        user_end_marker_obj         % marker object
        u_start_times               % double
        u_end_times                 % double
        
        initial_start_times
        initial_end_times
        
        updated_start_times
        updated_end_times
        
        final_start_times
        final_end_times
        
        % voided volume and voiding time
        u_vv
        u_vt
        c_vv
        c_vt
        
        % plotting
        marker_plot_start_h
        marker_plot_end_h
    end
    
    methods
        function obj = analysis.void_data()
            obj.marker_plot_start_h = cell(1,1);
            obj.marker_plot_end_h = cell(1,1);
            % should I preallocate more space for these?
        end
        function updateDetections(obj,start_times,end_times)
            %
            %   obj.updateDetections(start_times, end_times)
            %   given arrays of start and end times for markers, remove
            %   those times from the updated lists.
            %
            %   inputs:
            %   ---------------
            %   - start_times: array of start times which should be removed
            %           from the list of detections
            %   - end_times: array of end times which should be removed
            %           from the list of detections
            
            temp1 = obj.updated_start_times;
            temp2 = obj.updated_end_times;
            
            obj.updated_start_times = setdiff(temp1,start_times);
            obj.updated_end_times = setdiff(temp2,end_times);
        end
        function plotMarkers(obj, data_type, source,varargin)
            %
            %   obj.plotMarkers(data_type, source)
            %   
            %   Plots the markers specified by the inputs. Will plot to the
            %   most recent figure
            %
            %   Inputs:
            %   ---------
            %   -   data_type: 'filtered' or 'raw'
            %   -   source: 'user' or 'cpt'
            %
            switch lower(source)
                case 'user'
                    start_times = obj.u_start_times;
                    end_times = obj.u_end_times;
                case 'cpt'
                    start_times = obj.updated_start_times;
                    end_times = obj.updated_end_times;
                otherwise
                    error('unrecognized source of markers')
            end
            switch lower(data_type)
                case 'filtered'
                    
                case 'raw'
                    
                otherwise
                    error('unrecognized data_type')
            end
        end
        function plotUserMarks(obj)
            % plots the markers indicated by the user on the orignal data
            % TODO: combine this with the other plot method and have
            % options
            error('NYI')

            start_times = obj.u_start_times;
            end_times = obj.u_end_times;
      
            start_y = obj.h.getDataFromTimeRange(start_times);
            end_y = obj.h.getDataFromTimeRange(end_times);
            
            hold on
            obj.marker_plot_start_h{end+1} =   plot(start_times,start_y,'ko', 'MarkerSize', 10);
            obj.marker_plot_end_h{end+1} =   plot(end_times,end_y, 'ks',  'MarkerSize', 10);
        end
        function plotCptMarks(obj)
            
        end
        function processHumanMarkedPts(obj)
        end
        function processCptMarkedPts(obj)
        end
        function vv = getVoidedVolume(obj,start_markers,end_markers)
        end
        function vt = getVoidingTime(~,start_markers,end_markers)
        end
    end
    
end
