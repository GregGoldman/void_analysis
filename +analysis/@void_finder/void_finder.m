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
        expt_file_paths
        
        loaded_expts
        
        
        save_location
        
        %expt stuff
        %------------
        cur_expt
        cur_expt_possible_voids %TODO: change name to cur_stream_possible_voids
        cur_expt_marked_voids %the new points that the user marks
        
        
        %analog stream stuff
        cur_stream_idx
        cur_stream
        cur_stream_data
        filtered_cur_stream_data
        cur_starts_and_stops
        
        
        %marker stuff
        cur_marker_idx
        cur_marker_times % holds the marker times so that they match up with the data
        cur_marker
        cur_end_marker_idx
        cur_end_marker_times
        cur_end_marker
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
            obj.expt_file_paths = obj.expt_file_list_result.file_paths;
            %   above line output is a cell array
        end
        function saveExptObjs(obj)
            % NYI!!!
            %TODO: make this easy to change/make it update automatically
            old_location = cd(save_location);
            
            %do the save work here
            
            %return to the old folder
            cd old_location;
        end
        function runTest(obj)
            
        end
        function loadAllExpts(obj)
            %   loads all of the expt files that the user has
            %   this is a very time consuming function. need a way to
            %   block this function from running if they are already loaded
            
            for i = 1:length(obj.expt_file_paths);
                if( i~=3)
                obj.loaded_expts{i} = notocord.file(obj.expt_file_paths{i});
                %TODO: i = 3 does not work
                end
            end
        end
        function loadExpt(obj,index)
            obj.loaded_expts{end+1} = notocord.file(obj.expt_file_paths{index});
        end
        function loadAndFilterStream(obj,index,stream_num)
            % loads the stream indicated by stream_num of the experiment
            % indicated by index
            
            obj.cur_expt = obj.loaded_expts{index};
            
            %event markers 2 goes with channel 01
            obj.cur_stream_idx = stream_num;
            obj.cur_marker_idx = stream_num+1;
            obj.cur_end_marker_idx = obj.cur_marker_idx + 8;
            %	TODO: need to include a way to get end markers
            
            chan_info = table2cell(obj.cur_expt.chan_info);
            temp = chan_info(:,3);
            
            [B I J] = unique(temp);
            for ind = 1:length(B)
                count(ind) = length(find(J==ind));
            end
            % if count == 9, then there are only event markers, not start
            % and stop markers. If it is 17(?) then it has start and stop
            % markers
            % it seems that only the very first experiment file that I have
            % has only one marker per void
            num_channels = 8;
            
            if (count(1) == 9) %this is definitely not a good way to do this...
                
            else
                obj.cur_end_marker = obj.cur_expt.getStream(['Event markers ', sprintf('%d',obj.cur_end_marker_idx)]);
            end
            
            obj.cur_stream = obj.cur_expt.getStream(['Analog Channel  0', sprintf('%d',obj.cur_stream_idx)]);
            obj.cur_marker = obj.cur_expt.getStream(['Event markers ', sprintf('%d',obj.cur_marker_idx)]);
            
            %filtering
            filter = sci.time_series.filter.butter(2,0.2,'low'); %order, freq, type
            obj.cur_stream_data = obj.cur_stream.getData();
            obj.filtered_cur_stream_data = obj.cur_stream_data.filter(filter);
            
            start_datetime = obj.cur_stream_data.time.start_datetime;
            t = obj.cur_marker.times - start_datetime;
            
            start_datetime = obj.cur_stream_data.time.start_datetime;
            tt = obj.cur_end_marker.times - start_datetime;
            % t is now the fraction of a day since the start
            % multiply by 86400 seconds in a day to convert to seconds to match up with
            % the locations of the markers in the graph.
            
            obj.cur_marker_times = 86400 * t; 
            obj.cur_end_marker_times =  86400 * tt;
        end
        function plotCurFilteredData(obj,plot_markers)
            % 
            %plots the data from the experiment in the index of
            %obj.loaded_expts using the stream listed in stream_num
            disp('OUT OF DATE');
        
            h = figure();
            plot(obj.filtered_cur_stream_data);
            
            if(plot_markers)
                y = obj.cur_marker_times.*0 -0.5;
                yy = obj.cur_end_marker_times.*0 - 0.5;
                hold on
                plot(obj.cur_marker_times,y,'k*',obj.cur_end_marker_times,yy,'k^');
            end
        end
        function findPossibleVoids(obj)
            data = obj.filtered_cur_stream_data;
            d1 = data.dif2;
            d2 = d1.dif2;
            
            threshold = 3*10^-8;
            event_finder = d2.calculators.eventz;
            
            obj.cur_starts_and_stops = event_finder.findPeaks(d2,3,'MinPeakHeight',threshold);
        end
        %{
        This method is out of date!
        
        function findPossibleVoids(obj, plot_found)
            
            %{
                summary of algorithm:
                loop through at a given time interval which should be based on the average
                time of a void.

                there needs to be a limiter on how many times a void can occur over a given
                duration of time. maybe voids which occur very soon after other voids can
                be grouped into a different array
            %}
            
            % guesswork for typical void duration:
            % anywhere from 4 seconds to 30 seconds
            % step size: 20 seconds
            
            time_interval = 10;%seconds, eg the spacing of checking
            step_size = time_interval/obj.filtered_cur_stream_data.time.dt; % a number of data points
            n_steps = floor(obj.filtered_cur_stream_data.time.n_samples / step_size); %the number of steps to get thru all the data points
            dt = obj.filtered_cur_stream_data.time.dt;
            
            threshold = 0.2626;
            time_blocker = 20;
            time_since_last_void = 0;
            void_found = 0;
            raw_data = obj.filtered_cur_stream_data.d;
            
            guess = [];
            
            for i = 1:n_steps
                if ((time_since_last_void > time_blocker)&&(~void_found))
                    cur_val = raw_data(step_size*i);
                    if (cur_val >= (threshold + prev_val))
                        guess{end+1} = i*step_size*dt;
                        void_found = 1;
                        time_since_last_void = 0;
                    else
                        void_found = 0;
                    end
                else
                    void_found = 0;
                end
                prev_val = raw_data(step_size*i);
                time_since_last_void = time_since_last_void + step_size * dt;
            end

            markers = cell2mat(guess);
            obj.cur_expt_possible_voids = markers;
            
            if (plot_found)
               obj.plotCurFilteredData(0);
               y = 0.*obj.cur_expt_possible_voids - 0.25;
               hold on
               plot(obj.cur_expt_possible_voids,y,'k*')
            end
            
            %need to get snippets of the data close to my possible voids to save only those parts            
            for temp = obj.cur_expt_possible_voids;
                
                
            end
        end
        %}
        function findVolAndTime(obj)
            
            for temp = obj.cur_expt_possible_voids;
                %loop through at each area near a void
            end
            
        end
    end
    
end

