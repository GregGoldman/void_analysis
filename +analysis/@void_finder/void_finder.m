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

        %   filtering
        filtered_cur_stream_data    % sci.time_series.data
        d1                          % first derivative of the data
        d2                          % second derivative of the data
        event_finder                        % event_calculator
        
        initial_detections          % [starts, ends]
        updated_detections          % list gets smaller and smaller as poitns are removed
        calibration_marks
        
        evaporation_times %(where there is a huge positive jump in slope)
        reset_times %occurs from voiding %(where there is a huge negative slope back down to zero
        
        glitch_markers %cell [start] [stop]
    end
    methods
        function obj = void_finder()
            %   a class dedicated to loading files, finding voids, and
            %   calculating voided volume and voiding time
            
            obj.save_location = 'C:\Data\nss_matlab_objs';
            obj.findExptFiles();
            obj.loaded_expts = [];
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
            [B I J] = unique(temp);
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
        function d2 = findPossibleVoids(obj)
            obj.d1 = obj.filtered_cur_stream_data.dif2;
            obj.d2 = obj.d1.dif2;
            obj.event_finder = obj.d2.calculators.eventz;
            
            %-------------------------------------------------------------
            %   for the acceleration to find all the possible start and stop
            %   points (comes in obj.initial_detections)
            accel_thresh = 3*10^-8;
            obj.processD2(accel_thresh);
            %------------------------------------------------------------
            obj.removeCalibration(90); %input is 90 seconds, calibration period
            %------------------------------------------------------------
            % processing on the speed to look for spikes in the data
            spike_thresh = 1*10^-4;
            spike_width = 10; %roughly 10 seconds across in width
            possible_spikes = event_finder.findLocalMaxima(d1,3,spike_thresh);
            [pos_pres_in_neg idx_of_loc_in_neg] = ismembertol(start_positives,start_negatives,spike_width/2, 'DataScale', 1); %{'OutputAllIndices',true %}
            
            
            %for processing the speed
            % it may be much faster to look at magnitude changes rather
            % than finding peaks in the slope
            speed_thresh = 4*10^-3;
            event_finder = d1.calculators.eventz;
            cur_reset_pts = event_finder.findLocalMaxima(d1,3,speed_thresh);
            
            too_close = 10; %seconds. only care abt a sharp up or down...
            start_positives = cur_reset_pts.time_locs{1};
            start_negatives = cur_reset_pts.time_locs{2};
            
            %BIG PROBLEM: this removed the wrong thing
            [pos_pres_in_neg idx_of_loc_in_neg] = ismembertol(start_positives,start_negatives,too_close, 'DataScale', 1); %{'OutputAllIndices',true %}
            % returns an array containing logical 1 (true) where the elements of A are within tolerance of the elements in B
            % also returns an array, LocB, that contains the index location in B for each element in A that is a member of B.
            %There is probably a good way to use this to get rid of some
            %more errors ---
            %   later note: trend of a positive and a negative in d1 very close
            %   together is consistently an error
            obj.glitch_markers = [];
            obj.glitch_markers{1} = start_positives(pos_pres_in_neg);
            obj.glitch_markers{2} = start_negatives(idx_of_loc_in_neg(idx_of_loc_in_neg~=0));
            
            f_start_positives = start_positives(~pos_pres_in_neg);
            temp = start_negatives;
            temp(idx_of_loc_in_neg(idx_of_loc_in_neg~=0)) = [];
            f_start_negatives = temp;
            clear temp;
            
            %now have indices of all the resets
            
            obj.evaporation_times = f_start_positives;
            obj.reset_times = f_start_negatives;
            %now need to discount these from the list of markers and treat
            %them differently
        end
    end
    methods %mostly helpers
        function processD2(obj,accel_thresh)
            obj.initial_detections = obj.event_finder.findLocalMaxima(obj.d2,3,accel_thresh);
        end
        function removeMarkers(obj,start_times, end_times)
            
        end
        function removeCalibration(obj, calibration_period)
            start_points = obj.initial_detections.time_locs{1};
            end_points = obj.initial_detections.time_locs{2};
            
            obj.calibration_marks = cell(1,2);
            
            obj.calibration_marks{1} = find(start_points<calibration_period);
            obj.calibration_marks{2} = find(end_points<calibration_period);
        end
        function handles = plotCurrentMarks(obj)
            handles = cell(1,2);
         %   handles{1} =
        end
    end
    methods (Hidden) %methods which don't work yet
                function plotCurFilteredData(obj,plot_markers)
            % THIS METHOD IS OUT OF DATE
            
            %plots the data from the experiment in the index of
            %obj.loaded_expts using the stream listed in stream_num
            disp('OUT OF DATE');
            
            h = figure();
            plot(obj.filtered_cur_stream_data);
            
            if(plot_markers)
                y = obj.cur_start_markers_times.*0 -0.5;
                yy = obj.cur_end_markers_times.*0 - 0.5;
                hold on
                plot(obj.cur_start_markers_times,y,'k*',obj.cur_end_markers_times,yy,'k^');
            end
        end
        function saveExptObjs(obj)
            % NYI!!!
            %TODO: make this easy to change/make it update automatically
            old_location = cd(save_location);
            
            %do the save work here
            
            %return to the old folder
            cd old_location;
        end
        function processHumanMarkedPts(obj)
            %get all of the markers
            
            
        end
        function processCptMarkedPts(obj)
            
        end
        function vv = getVoidedVolume(obj,start_markers,end_markers)
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
            %   -start_markers: double array
            %   -start_markers: double array
            
            if (length(start_marker) ~= length(end_markers))
                error('input vectors are different sizes')
            end
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

