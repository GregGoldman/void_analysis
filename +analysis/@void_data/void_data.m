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
    %   whether a void is valid and why
    %
    
    properties
        parent                           % handle to the void_finder class
                                    % analysis.void_finder
        %markers
        cur_markers_idx             % array [start end]
        user_start_marker_obj       % marker object
        user_end_marker_obj         % marker object
        u_start_times               % double
        u_end_times                 % double
        u_reset_start_times
        u_reset_end_times
        
        initial_start_times
        initial_end_times

        updated_start_times
        updated_end_times
        
        % I don't think I use these two:
        final_start_times
        final_end_times
        
        calibration_start_times
        calibration_end_times
        
        spike_start_times
        spike_end_times
        
        evap_start_times
        evap_end_times
        
        % resets
        removed_reset_start_times % times in the middle of a proper reset (usually a start and a stop in between the correct two)
        removed_reset_end_times
        reset_start_times
        reset_end_times
        
        % glitches found around the evaporations/resets
        glitch_start_times
        glitch_end_times    
        
        % void times removed because they don't have a partner
        unpaired_start_times
        unpaired_end_times
        
        % magnitude issues
        too_small_start_times
        too_small_end_times
        
        % fecal void, food pellet, etc (slope issues)
        solid_void_start_times
        solid_void_end_times
        
        % proximity issues -- too close to other voids to have marker
        % accuracy adjusted/to ensure that voided volume is calculated
        % correctly
        proximity_issue_starts
        proximity_issue_ends

        % voided volume and voiding time
        u_vv %user
        u_vt
        c_vv %computer
        c_vt
        
        u_slopes
        c_slopes

        comparison_result          % analysis.comparison_result
    end
    methods
        function obj = void_data(parent)
            obj.parent = parent; % the parent void_finder2 class
        end
        function invalidateRanges(obj,start_times, end_times, invalid_type,varargin)
            %
            %   obj.invalidateRanges(start_times, stop_times, invalid_type, *overwrite)
            %
            %   Removes the start_times and stop_times from the list of
            %   updated times. Also places these times in the corresponding
            %   properties to mark why the were removed.
            %
            %   Inputs
            %   --------
            %   start_times
            %   stop_times
            %   invalid_type: string
            %       - 'glitches'
            %       - 'calibration'
            %       etc.
            %   varargin
            %       -'overwrite': true or false (default)
               
            
            in.overwrite = false;
            in = sl.in.processVarargin(in,varargin);
            
            
            obj.updated_start_times = setdiff(obj.updated_start_times, start_times);
            obj.updated_end_times = setdiff(obj.updated_end_times, end_times);
            
            
            if ~in.overwrite
            obj.([invalid_type '_start_times']) = start_times;
            obj.([invalid_type '_end_times']) = end_times;
            else
            temp1 = obj.([invalid_type '_start_times']);
            temp2 = obj.([invalid_type '_end_times']);
            obj.([invalid_type '_start_times']) = union(temp1, start_times);
            obj.([invalid_type '_end_times']) = union(temp2, end_times);
            end
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
        function varargout =  plotMarkers(obj, data_type, source,varargin)
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
            %   -   varargin: NYI!
            %
            %   Outputs:
            %   -----------
            %   -   varargout: if there is an output argument, it returns
            %                  the handle to the plotting of these markers
            %
            %   TODO: should we support returning different handles for
            %   both start and end markers?
            
            if nargout > 1 
               error('too many output arguments') 
            end
            
            switch lower(source)
                case 'user'
                    start_times = obj.u_start_times;
                    end_times = obj.u_end_times;
                    
                    start_marker = 'ko';
                    end_marker = 'ks';
                case 'cpt'
                    start_times = obj.updated_start_times;
                    end_times = obj.updated_end_times;
                    
                    start_marker = 'k*';
                    end_marker = 'k+';
                otherwise
                    error('unrecognized source of markers')
            end
            switch lower(data_type)
                case 'filtered'
                    start_vals = obj.parent.data.getDataFromTimePoints('filtered', start_times);
                    end_vals =  obj.parent.data.getDataFromTimePoints('filtered', end_times);
                case 'raw'
                   start_vals = obj.parent.data.getDataFromTimePoints('raw', start_times);
                   end_vals =  obj.parent.data.getDataFromTimePoints('raw', end_times);
                otherwise
                    error('unrecognized data_type')
            end
            
            hold on
            h1 = plot(start_times,start_vals,start_marker,'MarkerSize',10);
            h2 = plot(end_times,end_vals,end_marker, 'MarkerSize',10);
            if nargout == 2
                varargout{1} = h1;
                varargout{2} = h2;
            end
        end
        function processHumanMarkedPts(obj)
            %
            %   obj.processUserMarkedPts();
            %
            %   Sets the values of obj.u_vv and obj.u_vt as the voided
            %   volumes and the voiding times of all of the computer-found
            %   markers
            %
            start_markers = obj.u_start_times;
            end_markers = obj.u_end_times;
            if length(start_markers) ~= length(end_markers)
               disp('there is a dimension mismatch');
               disp('find the mismatch and remove it from the data');
               keyboard
            end
            
            % find the reset points in the user marked points
            start_vals = obj.parent.data.getDataFromTimePoints('raw',start_markers);
            end_vals = obj.parent.data.getDataFromTimePoints('raw',end_markers);
            temp = start_vals > end_vals;
            obj.u_reset_start_times = start_markers(temp);
            obj.u_reset_end_times = end_markers(temp);

            obj.u_vv = obj.getVoidedVolume(start_markers, end_markers, obj.u_reset_start_times, obj.u_reset_end_times);
            obj.u_vt = obj.getVoidingTime(start_markers, end_markers)';
            obj.u_slopes = obj.getSlopes(obj.u_vv, obj.u_vt);
        end
        function processCptMarkedPts(obj)
            %
            %   obj.processCptMarkedPts();
            %
            %   Sets the values of obj.c_vv and obj.c_vt as the voided
            %   volumes and the voiding times of all of the computer-found
            %   markers
            %
            
            start_markers = obj.updated_start_times;
            end_markers = obj.updated_end_times;
            reset_starts = obj.reset_start_times;
            reset_stops = obj.reset_end_times;
            
            obj.c_vv = obj.getVoidedVolume(start_markers, end_markers, reset_starts, reset_stops);
            obj.c_vt = obj.getVoidingTime(start_markers, end_markers);
            obj.c_slopes = obj.getSlopes(obj.c_vv,obj.c_vt);
        end
        function vv = getVoidedVolume(obj,start_markers, end_markers, reset_starts, reset_stops)
            %
            %   better method is now obj.getVV !!!!!!
            %
            %   vv = obj.getVoidedVolume(start_markers, end_markers)
            %   
            %   Given start and end marker times, use the average of the
            %   data before and after, respectively, to calculate the
            %   voided volume
            %
            %   Inputs:
            %   --------
            %   - start_markers: array of start times (double)
            %   - end_markers: array of end times (double)
            %
            %   Outputs:
            %   ---------
            %   - vv: the voided volumes for each index of markers in order
            %         that they were given
            
            if (length(start_markers) ~= length(end_markers))
                error('input vectors are different sizes')
            elseif length(reset_starts) ~= length(reset_stops)
                % deal with reset pts differently
                error('mismatched reset start and end times')
            end
            
            temp = ismember(start_markers, reset_starts);
            reset_idxs = find(temp);
            
            TIME_WINDOW = 1; % window for average data
            RESET_MAGNITUDE = 10;
            
            vv = zeros(1,length(start_markers));
            
            for k = 1:length(start_markers)
                s_left_edge = start_markers(k) - TIME_WINDOW;
                s_right_edge = start_markers(k);
                start_data = obj.parent.data.getDataFromTimeRange('raw', [s_left_edge, s_right_edge]);
                start_avg = mean(start_data);
                
                e_left_edge = end_markers(k);
                e_right_edge = end_markers(k) + TIME_WINDOW;
                end_data = obj.parent.data.getDataFromTimeRange('raw', [e_left_edge, e_right_edge]);
                end_avg = mean(end_data);
                
                if ~any(k == reset_idxs)
                   % not a reset point
                   vv(k) = end_avg - start_avg;
                else
                    vv(k) =  RESET_MAGNITUDE - start_avg + end_avg;
                end  
            end
        end
        function vv = getVV(obj, start_markers, end_markers)
            %
            %   obj.getVV(start_times, end_times)
            %
            %   does the same thing as getVoidedVolume, but does not
            %   require the input of reset times for calculations.
            
             if (length(start_markers) ~= length(end_markers))
                 error('input vectors are different sizes')
             end
             
             TIME_WINDOW = 1; % window for average data
             RESET_MAGNITUDE = 10;
             vv = zeros(1,length(start_markers));
             for k = 1:length(start_markers)
                 s_left_edge = start_markers(k) - TIME_WINDOW;
                 s_right_edge = start_markers(k);
                 start_data = obj.parent.data.getDataFromTimeRange('raw', [s_left_edge, s_right_edge]);
                 start_avg = mean(start_data);
                 
                 e_left_edge = end_markers(k);
                 e_right_edge = end_markers(k) + TIME_WINDOW;
                 end_data = obj.parent.data.getDataFromTimeRange('raw', [e_left_edge, e_right_edge]);
                 end_avg = mean(end_data);
                 
                 if end_avg > start_avg
                     % not a reset point
                     vv(k) = end_avg - start_avg;
                 else
                     vv(k) =  RESET_MAGNITUDE - start_avg + end_avg;
                 end
             end
        end
        function vt = getVoidingTime(~,start_markers,end_markers)
            %
            %   vt = obj.getVoidingTime(start_markers, end_markers)
            %
            %   Given start and end markers, returns the time difference
            %   between the start and stop of the void as an array
            %
            %   Inputs:
            %   ---------
            %   - start_markers: array of times (double)
            %   - end_markers: array of times (double)
            %
            %   Outputs:
            %   ----------
            %   - vt: array of the differences in time between the
            %         start/end pairs
            
            if (length(start_markers) ~= length(end_markers))
                error('input vectors are different sizes')
            end
            vt = end_markers - start_markers;
        end
        function slopes = getSlopes(~, vv, vt)
            %
            %   obj.getSlopes(source)
            %
            %   Finds the slopes of each of the voids
            %
            %   Outputs:
            %   ---------
            %   - slopes: an array of the slopes for each corresponding
            %             input vv/vt pair

            slopes = vv./vt;   
        end
        function [start_times, end_times] = getMarkersInTimeRange(obj, start_time, end_time)
            %
            %    [start_times end_times] =
            %    obj.getMarkersInTimeRange(start_times, end_times)
            %
            %    Returns the times of the start and end markers in between
            %    (inclusive) of start_time and end_time
            %
            %    Inputs:
            %    --------
            %    - start_time: time in the data (double)
            %    - end_time: time in the data (double)
            %
            %    Outputs:
            %    --------
            %    - start_times: array of times from obj.updated_start_times
            %                    which are within the range specified
            %    - end times: same thing for obj.updated_end_times
            %
            %   start_times and end_times vectors assuming they are the
            %   same length. In that case, start and end times will be
            %   paired together to create the ranges of time to search
            
            if length(start_time) ~= length(end_time)
                disp('mismatched dimensions')
                keyboard
            end
            
            temp = (obj.updated_start_times(:)' >= start_time(:)) & (obj.updated_start_times(:)' <=end_time(:));
            [~,J] = find(temp);
            start_times = obj.updated_start_times(unique(J));
            
            temp2 = (obj.updated_end_times(:)' >= start_time(:)) & (obj.updated_end_times(:)' <= end_time(:));
            [~,K] = find(temp2);
            end_times = obj.updated_end_times(unique(K));
        end
        function compareUserCpt(obj)
            %
            %   analysis.void_data.compareUserCpt
            %
            %   creates the comparison class which runs the comparisons
            if length(obj.updated_start_times) ~= length(obj.updated_end_times)
                error('uneven number of markers... how did you do that?')
            end
            if length(obj.reset_end_times) ~= length(obj.reset_end_times)
                error('mismatched reset start and end times')
            end
            obj.comparison_result = analysis.comparison_result(obj);
        end
        function plotDistributions(obj)
            %
            % NYI!!!!!!!! The comparison class/scripts take care of this
            %
            obj.processCptMarkedPts;
            obj.processHumanMarkedPts;
            figure
            plot(obj.u_vt, obj.u_vv, 'ko','MarkerSize',8);
            hold on
            plot(obj.c_vt, obj.c_vv, 'ro','MarkerSize',8);
            legend('user', 'cpt')
        end
    end
    
end
