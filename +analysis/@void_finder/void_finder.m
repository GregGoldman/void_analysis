classdef void_finder <handle
    %
    %   Class: 
    %   analysis.void_finder
    %
    %   obj = analysis.void_finder
    
    %{
    %   methods:
    %   ------------
    %   findExptFiles
    %       inputs:
    %       -

    %
    example:
        obj = analysis.void_finder;
        obj.loadExpt(2);
        obj.loadStream(1,1);
        obj.filterCurStream();
        obj.findPossibleVoids();
    %}
    properties
        % file stuff
        expt_file_list_result    
        save_location             
        loaded_expts

        % expt stuff
        cur_expt                    % notocord.file
        
        % analog stream stuff
        cur_stream                  % notocord.continuous_stream
        cur_stream_idx              % scalar
        cur_stream_data             % sci.time_series.data

        % user marker stuff
        cur_markers_idx             % array [start end]
        user_start_marker_obj       % marker object
        user_end_marker_obj         % marker object
        u_start_times               % double
        u_end_times                 % double
        
        u_reset_starts
        u_reset_ends
        
        marker_plot_start_h
        marker_plot_end_h

        % computer marker stuff
        initial_start_times         % double
        initial_end_times           % double
        
        updated_start_times
        updated_end_times

        calibration_start_times
        calibration_end_times
  
        spike_start_times
        spike_end_times
  
        evap_start_times
        evap_end_times
  
        reset_start_times
        reset_end_times
  
        glitch_start_times
        glitch_end_times     %   TODO: combine with spike_..._times
        
        unpaired_start_times
        unpaired_stop_times
        
        % voided volume and voiding time
        u_vv
        u_vt
        c_vv
        c_vt
  
        % filtering
        filtered_cur_stream_data    % sci.time_series.data
        d1                          % first derivative of the data
        d2                          % second derivative of the data
        event_finder                % event_calculator   
        
        comparison_result
    end
    methods
        function obj = void_finder()
            %   a class dedicated to loading files, finding voids, and
            %   calculating voided volume and voiding time
            
            obj.save_location = 'C:\Data\nss_matlab_objs';
            obj.findExptFiles();
            obj.loaded_expts = [];
            obj.marker_plot_start_h = [];
            obj.marker_plot_end_h = [];
        end
        function findExptFiles(obj)
            %   find the list of files that we have to work with
            %   TODO: update the dba.files.raw.finder class to be able to
            %   handle this with a varargin for FILE_EXTENSION
            
            FILE_EXTENSION = '.nss';
            RAW_DATA_ROOT = dba.getOption('raw_data_root');
            if ~exist(RAW_DATA_ROOT,'dir')
                %type options = dba.getOptions for more details
                %TODO: We should make it easier to edit from here ...
                %   - might be best to tie into the options code
                %   - dba.options.errors.missingFile() <- possible name
                error_msg = sl.error.getMissingFileErrorMsg(RAW_DATA_ROOT);
                error(error_msg)
            end
            obj.expt_file_list_result = sl.dir.getList(RAW_DATA_ROOT,'recursive',-1,'extension',FILE_EXTENSION);
        end
        function loadExpt(obj,index)
            % loads experiment objects based on the index in the list of
            % file_paths of obj.expt_tile_list_result.file_paths
            %
            % populates the end+1 index in obj.loaded_expts
            
            obj.loaded_expts{end+1} = notocord.file(obj.expt_file_list_result.file_paths{index});
        end
        function loadStream(obj,index,stream_num)
            % loads the stream indicated by stream_num of the experiment
            % indicated by index
            
            obj.cur_expt = obj.loaded_expts{index};
            obj.cur_stream_idx = stream_num;
            %event markers 2 goes with channel 01
            obj.cur_markers_idx = [stream_num+1, stream_num + 9];
            
            % need to figure out if there are both start and end markers
            % ---------------------------------------------------------------
            chan_info = table2cell(obj.cur_expt.chan_info);
            temp = chan_info(:,3);
            [B, I, J] = unique(temp);
            for ind = 1:length(B)
                count(ind) = length(find(J==ind));
            end
            % if count == 9, then there are only event markers, not start
            % and stop markers. If it is 17(?) then it has start and stop
            % markers  % it seems that only the very first experiment file that I have
            % has only one marker per void
            if (count(1) == 9) %this is definitely not a good way to do this...
                error('no end markers (NYI)')
            end
            % ----------------------------------------------------------------
            
            obj.user_start_marker_obj = obj.cur_expt.getStream(['Event markers ', sprintf('%d',obj.cur_markers_idx(1))]);
            obj.user_end_marker_obj = obj.cur_expt.getStream(['Event markers ', sprintf('%d',obj.cur_markers_idx(2))]);
            obj.cur_stream = obj.cur_expt.getStream(['Analog Channel  0', sprintf('%d',obj.cur_stream_idx)]);  
            obj.cur_stream_data = obj.cur_stream.getData();
  
            start_datetime = obj.cur_stream_data.time.start_datetime;
            t = obj.user_start_marker_obj.times - start_datetime;
            tt = obj.user_end_marker_obj.times - start_datetime;
            % t is now the fraction of a day since the start
            % multiply by 86400 seconds in a day to convert to seconds to match up with
            % the locations of the markers in the graph.
            
            obj.u_start_times = 86400 * t;
            obj.u_end_times =  86400 * tt;
        end
        function filterCurStream(obj)
            % loads the stream indicated by stream_num of the experiment
            % indicated by index
            filter = sci.time_series.filter.butter(2,0.2,'low'); %order, freq, type
            obj.filtered_cur_stream_data = obj.cur_stream_data.filter(filter);
        end
        function findPossibleVoids(obj)
            obj.d1 = obj.filtered_cur_stream_data.dif2;
            obj.d2 = obj.d1.dif2;
            obj.event_finder = obj.d2.calculators.eventz;
            
            %-------------------------------------------------------------
            %   for the acceleration to find all the possible start and stop
            %   points (comes in obj.initial_detections)
            
            obj.processD2();
            %------------------------------------------------------------
            obj.IDCalibration(90); %input is 90 seconds, calibration period
            % updates obj.calibration_marks
            % also calls updateDetections (see obj.updated_detections)
            %------------------------------------------------------------
            obj.findSpikes();
            %------------------------------------------------------------
            obj.processD1();
            %------------------------------------------------------------
            obj.findPairs();
        end
    end
    methods %mostly helpers
        % processD1 (has its own file)
        function updateDetections(obj,start_times, end_times)
            %   given arrays of start and end times for markers, remove
            %   those times from the updated lists. 
            %

            temp1 = obj.updated_start_times;
            temp2 = obj.updated_end_times;
            
            obj.updated_start_times = setdiff(temp1,start_times);
            obj.updated_end_times = setdiff(temp2,end_times);
        end
        function processD2(obj)
            %   Processing on the second derivative of the data. Start
            %   points occur at peak positives in acceleration, end points
            %   occur at peak negatives in acceleration.
            
            ACCEL_THRESH = 3*10^-8;
            
            detections = obj.event_finder.findLocalMaxima(obj.d2,3,ACCEL_THRESH);
            obj.initial_start_times = detections.time_locs{1};
            obj.initial_end_times = detections.time_locs{2};
            
            obj.updated_start_times = obj.initial_start_times;
            obj.updated_end_times = obj.initial_end_times;
        end
        function IDCalibration(obj, calibration_period)
            %   Removes the start and end points which have been detected
            %   during the timeframe defined by calibration_period
            %
            
            start_times = obj.initial_start_times;
            end_times = obj.initial_end_times;
            
            obj.calibration_start_times = start_times(start_times<calibration_period);
            obj.calibration_end_times = end_times(end_times<calibration_period);
            
            obj.updateDetections(obj.calibration_start_times, obj.calibration_end_times);
        end
        function findSpikes(obj)
            % spikes tend to have start markers at roughly the same value on
            % both sides of the spike. need to find start points that are
            % close together in time and in magnitude.
            % also test whether or not the value before the spike is the
            % same as after the spike.
            
            start_times = obj.initial_start_times;
            end_times = obj.initial_end_times;
            
            data = obj.filtered_cur_stream_data.d;
            starting_idxs = obj.filtered_cur_stream_data.time.getNearestIndices(start_times);
            starting_vals = data(starting_idxs);
            
            time_window = 10; %seconds
            y_tol = 0.1;
            
            spike_start_markers = [];
            spike_end_markers = [];
            
            for i = 1:length(start_times)-1
                if ((start_times(i+1) - start_times(i)) < time_window) && (abs(starting_vals(i+1) - starting_vals(i)) < y_tol) 
                    %this is probably a spike
                    spike_start_markers = [spike_start_markers; start_times(i); start_times(i+1)];
                    
                    % need to find the nearby end markers. If there are any
                    % end markers within the time_window of the spike start
                    % markers, add them to the list
                    a = ismembertol(end_times,spike_start_markers, time_window, 'DataScale', 1);
                    spike_end_markers = [spike_end_markers; end_times(a)'];   
                end
            end
            obj.spike_start_times = spike_start_markers;
            obj.spike_end_times = spike_end_markers;
            
            obj.updateDetections(spike_start_markers, spike_end_markers);
        end
        function findPairs(obj)
            %   findPairs(obj)
            %   findPairs attempts to match start and end markers by
            %   matching a given start with the next closest stop. It also
            %   deals with cases of missing points i.e.:
            %             start start stop
            %   should leave out the middle start point
            %   these points tend to occur in areas of tiny slope
            %   changes during a void, so they can reasonably be discounted

            %first, loop through the starting times
            start_times = obj.updated_start_times;
            end_times = obj.updated_end_times;

            ind = sl.array.nearestPoint2(start_times,end_times,'next');
            %   IND = NEARESTPOINT2(X,Y) finds the value in Y which is the closest to
            %   each value in X, so that abs(Xi-Yk) => abs(Xi-Yj) when k is not equal to j.
            %   IND contains the indices of each of these points.
            %   Example:
            %      NEARESTPOINT2([1 4 12],[0 3]) % -> [1 2 2]
            %       for each index in x, the value is the closest index in y
            %   'next'    : find the points in Y that are closets, but follow a point in X
            %               NEARESTPOINT2([1 4 3 12],[0 3],'next') % -> [2 NaN 2 NaN]
             
            % match pairs:
            partners = [];
            for i = 1:length(ind)
                if ~isnan(ind(i))
                    cur_val = ind(i);

                    % we want to keep the one which is farthest away (the
                    % first one)
                    t = find(ind == ind(i)); 
                    start_to_save = t(1);
                    stop_to_save = cur_val;
                    % this assumes that starts always come first... and we
                    % may have a start start stop
                    
                    partners(end+1,1) = start_to_save;
                    partners(end,2) = stop_to_save;
                end
            end
            
            a = 1:length(start_times);
            b = 1:length(end_times);
            delete_start_idxs = setdiff(a,partners(:,1));
            delete_stop_idxs = setdiff(b,partners(:,2));
            
            obj.unpaired_start_times = start_times(delete_start_idxs);
            obj.unpaired_stop_times = end_times(delete_stop_idxs);
            
            obj.updateDetections(obj.unpaired_start_times,obj.unpaired_stop_times);
        end
        function compareUserCpt(obj)
            %   THIS FUNCTION NOT YET FINISHED/NOT YET WORKING
            % NYI
            error('greg messed this function up, please wait until fixed (by end of day 6/13)')
            %       later update:
            %       it looks like it is not appropriate to mark the reset
            %       points as correct with the time difference :(
            %           the values for voided volume and voiding time are
            %           too far off
            %
            %   look for cpt-marked points which are within one second of
            %   user-marked points
            %
            %
            %   Dealing with reset points:
            %   The start and end times with reset points tend to be father
            %   from the user markers. extend the tolerance near these
            %   points and assume they are correct
            
            
            
            if length(obj.updated_start_times) ~= length(obj.updated_end_times)
                error('uneven number of markers... how did you do that?')
            end
            if length(obj.reset_end_times) ~= length(obj.reset_end_times)
                error('mismatched reset start and end times')
            end
            
            start_times = obj.updated_start_times;
            end_times = obj.updated_end_times;
            u_start_times = obj.u_start_times;
            u_end_times = obj.u_end_times;
            
            temp = ismember(start_times,obj.reset_start_times);
            reset_idxs = find(temp);
            
            tolerance = 1;
            reset_tolerance = 4; %more lenient with points around the resets
            count = 1;
            
            %   TODO: fix the variable naming in here!!!!
            
            [a b] = ismembertol(u_start_times,start_times,tolerance,'DataScale',1);
            % a is logical mask of where the data in u_start_times is within
            % tolerance of the data in start_times
            % b contains the indices in start times for each value in
            % vector a
            
            [temp1 temp2] = ismembertol(u_start_times,obj.reset_start_times,reset_tolerance,'DataScale',1);
            
            g = or(a,temp1);
            h = reset_idxs(temp2(temp2~=0));
            
            matched_start_idxs = sort([b(b~=0); h']);
            matched_u_start_idxs = find(g);
            
            [c,d] = ismembertol(u_end_times,end_times,tolerance,'DataScale',1);
            [temp1 temp2] = ismembertol(u_end_times,obj.reset_end_times,reset_tolerance,'DataScale',1);
            
            g = or(c,temp1);
            h = reset_idxs(temp2(temp2~=0));
            
            matched_end_idxs = sort([d(d~=0); h']);
            matched_u_end_idxs = find(g);
            
            % need to find the overlap 
            e = ismember(matched_start_idxs,matched_end_idxs);
            % e is a logical mask where the data in the first is
            % found in the second array
            cpt_success_idx = matched_start_idxs(e);
            
            f = ismember(matched_u_start_idxs,matched_u_end_idxs);
            u_success_idx = matched_u_start_idxs(f);
            
            
            
            % find indices which the computer missed:
            % at the end, missed_idx is a list of the indices where are not
            % included in u_success_idx
            temp1 = 1:length(u_start_times);
            temp2 = ~ismember(temp1,u_success_idx);
            missed_idx = temp1(temp2);
            
            % wrong points (points which the computer got wrong)
            % indices on this list are included if either or both start and
            % end are wrong
            temp1 = 1:length(start_times);
            temp2 = ~ismember(temp1,cpt_success_idx);
            wrong_idx = temp1(temp2);
            
           obj.comparison_result = analysis.comparison_result(missed_idx,wrong_idx,cpt_success_idx,u_success_idx);
        end
        function plotUserMarks(obj)
            % plots the markers indicated by the user on the orignal data
            % TODO: combine this with the other plot method and have
            % options
            data = obj.cur_stream_data.d;
            start_times = obj.u_start_times;
            end_times = obj.u_end_times;
            start_indices = obj.filtered_cur_stream_data.time.getNearestIndices(start_times);
            end_indices = obj.filtered_cur_stream_data.time.getNearestIndices(end_times);
            
            start_y = data(start_indices);
            end_y = data(end_indices);
            hold on
            
            obj.marker_plot_start_h(end+1) =   plot(start_times,start_y,'ko', 'MarkerSize', 10);
            obj.marker_plot_end_h(end+1) =   plot(end_times,end_y, 'ks',  'MarkerSize', 10);
        end
        function plotCurrentMarks(obj,filtered)
            % plots the markers and returns the handles to them
            % inputs:
            %   -filtered: true (default) or false -- if true, plot on the
            %           filtered data, if false, plot on the raw data
            %   (TODO) -start_type: char array, type of marker to use on plot
            %   (TODO) -end_type: char array, type of marker to use on plot
            
            if filtered
                raw_data = obj.filtered_cur_stream_data.d;
            else
                raw_data = obj.cur_stream_data.d;
            end
            
            raw_data = obj.filtered_cur_stream_data.d;
            start_times = obj.updated_start_times;
            end_times = obj.updated_end_times;
            start_indices = obj.filtered_cur_stream_data.time.getNearestIndices(start_times);
            end_indices = obj.filtered_cur_stream_data.time.getNearestIndices(end_times);
            
            start_y = raw_data(start_indices);
            end_y = raw_data(end_indices);
            hold on
            
            obj.marker_plot_start_h(end+1) =   plot(start_times,start_y,'k*',  'MarkerSize', 10);
            obj.marker_plot_end_h(end+1) =   plot(end_times,end_y, 'k+',  'MarkerSize', 10);
        end
        function plotFilteredData(obj)
            figure
            plot(obj.filtered_cur_stream_data)
        end
        function processHumanMarkedPts(obj)
            %get all of the markers
            starts = obj.u_start_times;
            ends = obj.u_end_times;
            
            obj.u_vv = obj.getVoidedVolume(starts,ends);
            obj.u_vt = obj.getVoidingTime(starts,ends);   
        end
        function processCptMarkedPts(obj)
            obj.c_vv = obj.getVoidedVolume(obj.updated_start_times, obj.updated_end_times);
            obj.c_vt = obj.getVoidingTime(obj.updated_start_times, obj.updated_end_times);
        end
        function vv = getVoidedVolume(obj,start_markers,end_markers)
            % TODO: use the raw data for this analysis?????
            %   given start and end markers, returns the voided volume over
            %   the course of the void
            %   TODO: clarify if this calculation should be completed using
            %   the raw or the filtered data
            %   TODO: should we be using the value at the marker time or
            %   slightly after the marker time?
            %
            %   uses the data from the current loaded stream to figure out
            %   what the voided volume is
            %
            %   inputs:
            %   ---------------
            %   -start_markers: double array (times)
            %   -start_markers: double array (times)
            
            if (length(start_markers) ~= length(end_markers))
                error('input vectors are different sizes')
            end
            data = obj.cur_stream_data.d;
            
            id_window = 10;
            
            % deal with reset pts differently
            if length(obj.reset_end_times) ~= length(obj.reset_end_times)
               error('mismatched reset start and end times') 
            end

            % remove the reset markers from the data and treat them
            % differently
            temp = ismember(start_markers,obj.reset_start_times);
            reset_idxs = find(temp);
            
            start_idxs = obj.filtered_cur_stream_data.time.getNearestIndices(start_markers)';
            back_idxs = start_idxs - id_window;
            end_idxs = obj.filtered_cur_stream_data.time.getNearestIndices(end_markers);
            forawrd_idxs = end_idxs + id_window;
            
            vv = zeros(1,length(start_idxs));
            
            for i = 1:length(start_idxs)
                temp = back_idxs(i): start_idxs(i);
                vals = data(temp);
                start_avg = mean(vals);
                
                temp = end_idxs(i):forawrd_idxs(i);
                vals = data(temp);
                end_avg = mean(vals);
                
                if any(i == reset_idxs) % reset void
                    vv(i) = 10 - start_avg + end_avg;
                else % regular void 
                    vv(i) = end_avg - start_avg;
                end
            end
        end
        function vt = getVoidingTime(~,start_markers, end_markers)
            %   given start and end markers, returns the time difference
            %   between the start and stop of the void as an array
            %   inputs:
            %   -obj
            %   -start_markers: double array (units: time)
            %   -end_markers: double array (units: time)
            
            if (length(start_markers) ~= length(end_markers))
                error('input vectors are different sizes')
            end
            vt = end_markers - start_markers;
        end
    end
    methods (Hidden) %methods which don't work yet
                function compareAndPlotMarkers(obj)
            %compares the user-marked stuff to the cpt-marked stuff

            %   histogram of vv
            figure
            h = histogram(obj.u_vv,50);
            figure
            h2 = histogram(obj.u_vt,50);
 
        end
        function saveExptObjs(obj)
            % NYI!!!
            %TODO: make this easy to change/make it update automatically
            old_location = cd(save_location);
            
            %do the save work here
            
            %return to the old folder
            cd old_location;
        end
        function loadAllExpts(obj)
            %   loads all of the expt files that the user has
            %   this is a very time consuming function. need a way to
            %   block this function from running if they are already loaded
            
            for i = 1:length(obj.expt_file_list_result.expt_file_paths);
                if( i~=3)
                    obj.loaded_expts{i} = notocord.file(obj.expt_file_paths{i});
                    %TODO: i = 3 does not work
                end
            end
        end
    end
end

