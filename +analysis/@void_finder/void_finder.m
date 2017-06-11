classdef void_finder <handle
    %class: void_finder
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
    examples:
    obj = analysis.void_finder;
    obj.loadExpt(2);
    obj.loadAndFilterStream(1,1);
    
    %}
    properties
        expt_file_list_result
        save_location
        loaded_expts

        %   expt stuff
        cur_expt
        cur_stream_possible_voids %TODO: change name to cur_stream_possible_voids
        cur_expt_marked_voids %the new points that the user marks
        
        %   analog stream stuff
        cur_stream                  % notocord.continuous_stream
        cur_stream_idx              % scalar
        cur_stream_data             % sci.time_series.data
        
        %   markers
        cur_markers_idx     %cell: the marker indices  [start, end] (!!as in which data streams they are in the channel info!!)
        cur_markers         %the marker objects with names, comments, times, etc..
        cur_markers_times   % holds the marker times so that they match up with the data
        marker_plot_handles

        %   filtering
        filtered_cur_stream_data    % sci.time_series.data
        d1                          % first derivative of the data
        d2                          % second derivative of the data
        event_finder                        % event_calculator
        
        initial_detections          % [starts, ends]
        updated_detections          % list gets smaller and smaller as poitns are removed
        
        calibration_marks
        possible_spikes
        evaporation_times %(where there is a huge positive jump in slope)
        reset_times %occurs from voiding %(where there is a huge negative slope back down to zero
        glitch_markers %cell [start] [stop]
        
        cpt_vv
        cpt_vt
        
        u_vv
        u_vt
    end
    methods
        function obj = void_finder()
            %   a class dedicated to loading files, finding voids, and
            %   calculating voided volume and voiding time
            
            obj.save_location = 'C:\Data\nss_matlab_objs';
            obj.findExptFiles();
            obj.loaded_expts = [];
            obj.marker_plot_handles = cell(1,2);
        end
        function findExptFiles(obj)
            %TODO: see if there are files present and only load the ones
            %which are not (after prompting the user of course). If all of
            %the files are present, then this function should return and do
            %nothing
            
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
            obj.loaded_expts{end+1} = notocord.file(obj.expt_file_list_result.file_paths{index});
        end
        function loadStream(obj,index,stream_num)
            % loads the stream indicated by stream_num of the experiment
            % indicated by index
            
            obj.cur_expt = obj.loaded_expts{index};
            obj.cur_stream_idx = stream_num;
            %event markers 2 goes with channel 01
            obj.cur_markers_idx = [stream_num+1, stream_num + 9];
            
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
            obj.cur_markers{1} = obj.cur_expt.getStream(['Event markers ', sprintf('%d',obj.cur_markers_idx(1))]);
            obj.cur_markers{2} = obj.cur_expt.getStream(['Event markers ', sprintf('%d',obj.cur_markers_idx(2))]);
            obj.cur_stream = obj.cur_expt.getStream(['Analog Channel  0', sprintf('%d',obj.cur_stream_idx)]);  
            obj.cur_stream_data = obj.cur_stream.getData();
            
            start_datetime = obj.cur_stream_data.time.start_datetime;
            t = obj.cur_markers{1}.times - start_datetime;
            tt = obj.cur_markers{2}.times - start_datetime;
            % t is now the fraction of a day since the start
            % multiply by 86400 seconds in a day to convert to seconds to match up with
            % the locations of the markers in the graph.
            
            obj.cur_markers_times(:,1) = 86400 * t;
            obj.cur_markers_times(:,2) =  86400 * tt;
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
            accel_thresh = 3*10^-8;
            obj.processD2(accel_thresh);
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
        function findPairs(obj)
            %if a start or a stop occurs without a corresponding stop or start
            %within a threshold, it does not count-----------------------------

            %PROBLEM WITH PAIR FINDING: it is not always the closest one which is
            %the correct one........ :( it is more likely the farther of the
            %closest ones...

            %first, loop through the starting times
            start_points = obj.updated_detections{1};
            end_points = obj.updated_detections{2};
            
            %now, sort them (I think they are already sorted... need to
            %check
            [sorted_start_array] = sort(start_points);
            [sorted_stop_array] = sort(end_points);
            

            %   IND = NEARESTPOINT(X,Y) finds the value in Y which is the closest to
            %   each value in X, so that abs(Xi-Yk) => abs(Xi-Yj) when k is not equal to j.
            %   IND contains the indices of each of these points.
            %   Example:
            %      NEARESTPOINT([1 4 12],[0 3]) % -> [1 2 2]
            %       for each index in x, the value is the closest index in y
            %
            %   [IND,D] = ... also returns the absolute distances in D,
            %   that is D == abs(X - Y(IND))
            %   IND is for each index in sorted_start_array, the closest index
            %   in sorted_stop_array
            %    NEARESTPOINT(X, Y, M) specifies the operation mode M:
            %   'nearest' : default, same as above
            %   'previous': find the points in Y that are closest, but preceeds a point in X
            %               NEARESTPOINT([0 4 3 12],[0 3],'previous') % -> [NaN 2 1 2]
            %   'next'    : find the points in Y that are closets, but follow a point in X
            %               NEARESTPOINT([1 4 3 12],[0 3],'next') % -> [2 NaN 2 NaN]
            [IND, D] = nearestpoint(sorted_start_array,sorted_stop_array,'next');
            
            % match pairs:
            used_vals = [];
            partners = [];
            nd = length(IND);
            for i = 1:nd
                if ~isnan(IND(i))
                    cur_val = IND(i);

                    temp = ismember(IND,IND(i));  
                    % logical of where in the IND matrix the current value
                    % is found

                    % we want to keep the one which is farthest away (the
                    % first one)
                    t = find(temp); 
                    start_to_save = t(1);
                    stop_to_save = cur_val;
                    % this assumes that starts always come first... and we
                    % may have a start start stop

                    partners(end+1,1) = start_to_save;
                    partners(end,2) = stop_to_save;
                end
            end

            a = 1:length(sorted_start_array);
            b = 1:length(sorted_stop_array);
            delete_start_idxs = setdiff(a,partners(:,1));
            delete_stop_idxs = setdiff(b,partners(:,2));

            delete_start_times = sorted_start_array(delete_start_idxs);
            delete_stop_times = sorted_stop_array(delete_stop_idxs);
            
            obj.updateDetections(delete_start_times,delete_stop_times);
        end
        function processD1(obj)
            %for processing the speed
            speed_thresh = 4*10^-3;
            big_jump_pts = obj.event_finder.findLocalMaxima(obj.d1,3,speed_thresh);
            
            too_close = 10; %seconds. only care abt a sharp up or down, not one after the other
            positives = big_jump_pts.time_locs{1};
            negatives = big_jump_pts.time_locs{2};
            
            %BIG PROBLEM: this removed the wrong thing
            [pos_pres_in_neg idx_of_loc_in_neg] = ismembertol(positives,negatives,too_close, 'DataScale', 1); %{'OutputAllIndices',true %}
            % returns an array containing logical 1 (true) where the elements of A are within tolerance of the elements in B
            % also returns an array, LocB, that contains the index location in B for each element in A that is a member of B.
            %There is probably a good way to use this to get rid of some
            %more errors ---
            %   later note: trend of a positive and a negative in d1 very close
            %   together is consistently an error
            
            obj.glitch_markers = cell(1,2);
            
            glitch_peak_starts = positives(pos_pres_in_neg);
            t = find(idx_of_loc_in_neg);
            tt = idx_of_loc_in_neg(t);
            glitch_peak_ends = negatives(tt);
            %these points are values in time
            
            evap_POI = positives(~pos_pres_in_neg);
            
            ind = 1:length(negatives);
            ind = setdiff(ind,tt);
            reset_POI = negatives(ind);            

            %go outward 5 seconds
            time_thresh = 5;
           
            for i = 1:length(glitch_peak_starts)
                start_time = glitch_peak_starts(i) - time_thresh;
                end_time = glitch_peak_ends(i) + time_thresh;
                
                % mark the bad start points
                start_markers = obj.updated_detections{1};
                start_idxs = (start_markers > start_time) & (start_markers < end_time);
                obj.glitch_markers{1} = start_markers(start_idxs)';

                % mark the bad end points
                end_markers = obj.updated_detections{2};
                end_idxs = (end_markers > start_time) & (end_markers < end_time);
                obj.glitch_markers{2} = end_markers(end_idxs);
            end
            obj.updateDetections(obj.glitch_markers{1}, obj.glitch_markers{2});
            
            
            % now need to find resets and evaporation times
            %EVAPORATION:
            %for now, cut out 10 seconds on either side, although this has the
            %potential to cause problems...
            %shows up roughly in the middle of the evaporation period
            start_points = obj.updated_detections{1};
            end_points = obj.updated_detections{2};
            evap_window = 10; %
            
            start_deletions_idx = [];
            end_deletions_idx = [];
            
            for (i = 1:length(evap_POI))
                start_deletions_idx = [start_deletions_idx;find((start_points > (evap_POI(i) - evap_window)) & (start_points < (evap_POI(i) + evap_window)))'];
                end_deletions_idx = [end_deletions_idx; find((end_points > (evap_POI(i) - evap_window))&(end_points < (evap_POI(i) + evap_window)))'];
            end
            
            obj.evaporation_times = cell(1,2);
            obj.evaporation_times{1} = start_points(start_deletions_idx);
            obj.evaporation_times{2} = end_points(end_deletions_idx);
            
            obj.updateDetections(obj.evaporation_times{1}, obj.evaporation_times{2});
            
            
            % now need to deal with the RESET POINTS:
            start_points = obj.updated_detections{1};
            end_points = obj.updated_detections{2};
            
            res_window = 10;
            close_starts = [];
            close_ends = [];
            
            start_deletions_idx = [];
            end_deletions_idx = [];
            
            for (i = 1:length(reset_POI))
                
                %find the start points near the rest point
                %keep only the first one
                close_starts = find((start_points > (reset_POI(i) - res_window)) & (start_points < (reset_POI(i) + res_window)));
                start_deletions_idx = [start_deletions_idx ; close_starts(2:end)];
                
                close_ends = find((end_points > (reset_POI(i) - res_window))&(end_points < (reset_POI(i) + res_window)));
                end_deletions_idx = [end_deletions_idx; close_ends(1:end-1)];
            end
            obj.reset_times = cell(1,2);
            obj.reset_times{1} = start_points(start_deletions_idx);
            obj.reset_times{2} = end_points(end_deletions_idx);
            
            obj.updateDetections(obj.reset_times{1}, obj.reset_times{2});
        end
        function processD2(obj,accel_thresh)
            obj.initial_detections = obj.event_finder.findLocalMaxima(obj.d2,3,accel_thresh);
            obj.updated_detections = cell(1,2);
            obj.updated_detections = obj.initial_detections.time_locs;
        end
        function updateDetections(obj,start_times, end_times)
            temp1 = obj.updated_detections{1};
            temp2 = obj.updated_detections{2};
            
            obj.updated_detections{1} = setdiff(temp1,start_times);
            obj.updated_detections{2} = setdiff(temp2,end_times);
        end
        function IDCalibration(obj, calibration_period)
            start_points = obj.initial_detections.time_locs{1};
            end_points = obj.initial_detections.time_locs{2};
            
            obj.calibration_marks = cell(1,2);
            
            obj.calibration_marks{1} = start_points(find(start_points<calibration_period));
            obj.calibration_marks{2} = end_points(find(end_points<calibration_period));
            
            obj.updateDetections(obj.calibration_marks{1}, obj.calibration_marks{2});
        end
        function findSpikes2(obj)
            %   NYI~~~~
            %   finds spikes in the data based on the derivative rather than
            %   values returning back to previous.
            %   most spikes have a sharp positive value followed by a sharp
            %   negative value. markers around these points need to be
            %   removed.
            
            
            %{
            % processing on the speed to look for spikes in the data
            spike_thresh = 1*10^-4;
            spike_width = 5; %seconds from peaks
            %starts are usually within 3 seconds at the most
            %stops are usually within 5 or 6
            d1_peaks = obj.event_finder.findLocalMaxima(obj.d1,3,spike_thresh);
            [pos_pres_in_neg idx_of_loc_in_neg] = ismembertol(d1_peaks.time_locs{1},d1_peaks.time_locs{2},spike_width, 'DataScale', 1); %{'OutputAllIndices',true %}
            %}    
        end
        function findSpikes(obj)
            %   TODO: this doesn't work very well...
            % spikes tend to have start markers at roughly the same value on
            % both sides of the spike. need to find start points that are
            % close together in time and in magnitude.
            % also test whether or not the value before the spike is the
            % same as after the spike.
            
            
            start_times = obj.updated_detections{1};
            end_times = obj.updated_detections{2};
            
            starting_idxs = obj.filtered_cur_stream_data.time.getNearestIndices(start_times);
            ending_idxs = obj.filtered_cur_stream_data.time.getNearestIndices(end_times);
            
            data = obj.filtered_cur_stream_data.d;
            starting_vals = data(starting_idxs);
            ending_vals = data(ending_idxs);
            
            time_tol = 10; %seconds    
            y_tol = 0.1;
            
            spike_start_markers = [];
            spike_end_markers = [];
            
            for i = 1:length(start_times)-1
                if ((start_times(i+1) - start_times(i)) < time_tol) && (abs(starting_vals(i+1) - starting_vals(i)) < y_tol) 
                    %this is probably a spike
                    spike_start_markers = [spike_start_markers; start_times(i); start_times(i+1)];
                    
                    %need to find the nearby end markers
                    
                    a = ismembertol(end_times,spike_start_markers, time_tol, 'DataScale', 1);
                    
                    spike_end_markers = [spike_end_markers; end_times(a)'];  
                    obj.possible_spikes = cell(1,2);
                    obj.possible_spikes = {spike_start_markers, spike_end_markers}
                end
            end
            obj.updateDetections(spike_start_markers, spike_end_markers); 
        end
        function plotUserMarks(obj)
            % TODO: combine this with the other plot method and have
            % options
            data = obj.cur_stream_data.d;
            start_times = obj.cur_markers_times(:,1);
            end_times = obj.cur_markers_times(:,2);
            start_indices = obj.filtered_cur_stream_data.time.getNearestIndices(start_times);
            end_indices = obj.filtered_cur_stream_data.time.getNearestIndices(end_times);
            
            start_y = data(start_indices);
            end_y = data(end_indices);
            hold on
            
            obj.marker_plot_handles{end+1,1} =   plot(start_times,start_y,'ko')
            obj.marker_plot_handles{end,2} =   plot(end_times,end_y, 'ks')
        end
        function plotCurrentMarks(obj)
            raw_data = obj.filtered_cur_stream_data.d;
            start_times = obj.updated_detections{1};
            end_times = obj.updated_detections{2};
            start_indices = obj.filtered_cur_stream_data.time.getNearestIndices(start_times);
            end_indices = obj.filtered_cur_stream_data.time.getNearestIndices(end_times);
            
            start_y = raw_data(start_indices);
            end_y = raw_data(end_indices);
            hold on
            
            obj.marker_plot_handles{end+1,1} =   plot(start_times,start_y,'k*')
            obj.marker_plot_handles{end,2} =   plot(end_times,end_y, 'k+')  
        end
        function plotFilteredData(obj)
            figure
            plot(obj.filtered_cur_stream_data)
        end
        function processHumanMarkedPts(obj)
            %get all of the markers
            starts = obj.cur_markers_times(:,1);
            ends = obj.cur_markers_times(:,2);
            
            obj.u_vv = obj.getVoidedVolume(starts,ends);
            obj.u_vt = obj.getVoidingTime(starts,ends);   
        end
        function processCptMarkedPts(obj)
            obj.cpt_vv = obj.getVoidedVolume(obj.updated_detections{1}, obj.updated_detections{2});
            obj.cpt_vt = obj.getVoidingTime(obj.updated_detections{1}, obj.updated{2});
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
            
            if (length(start_marker) ~= length(end_markers))
                error('input vectors are different sizes')
            end
            data = obj.filtered_cur_stream_data.d;
            
            start_idxs = obj.filtered_cur_stream_data.time.getNearestIndices(start_markers);
            end_idxs = obj.filtered_cur_stream_data.time.getNearestIndices(end_markers);
            
            start_vals = data(start_idxs);
            end_vals = data(end_idxs);
            
            vv = start_vals - end_vals;
        end
        function vt = getVoidingTime(start_markers, end_markers)
            %   given start and end markers, returns the time difference
            %   between the start and stop of the void as an array
            %   inputs:
            %   -obj
            %   -start_markers: double array (units: time)
            %   -end_markers: double array (units: time)
            
            if (length(start_marker) ~= length(end_markers))
                error('input vectors are different sizes')
            end
            vt = end_markers - start_markers;
        end
    end
    methods (Hidden) %methods which don't work yet
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

