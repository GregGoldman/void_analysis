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
        
        %filtering
        evaporation_times %(where there is a huge positive jump in slope)
        reset_times %occurs from voiding %(where there is a huge negative slope back down to zero       
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
            % TODO: pass in filter arguments as input arguments to this
            % method
            
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
            % THIS METHOD IS OUT OF DATE
            
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
        function d2 = findPossibleVoids(obj)
            data = obj.filtered_cur_stream_data;
            d1 = data.dif2;
            d2 = d1.dif2;
            
            %for processing the acceleration
            threshold = 3*10^-8;
            event_finder = d2.calculators.eventz;
            
            obj.cur_starts_and_stops = event_finder.findPeaks(d2,3,'MinPeakHeight',threshold);
        
         
            %for processing the speed
            % it may be much faster to look at magnitude changes rather
            % than finding peaks in the slope
            speed_thresh = 4*10^-3;
            event_finder = d1.calculators.eventz;
            cur_reset_pts = event_finder.findPeaks(d1,3,'MinPeakHeight',speed_thresh);
            
            too_close = 10; %seconds. only care abt a sharp up or down... 
            start_positives = cur_reset_pts.time_locs{1}; 
            start_negatives = cur_reset_pts.time_locs{2};
            
            %BIG PROBLEM: this removed the wrong thing
            [pos_pres_in_neg idx_of_loc_in_neg] = ismembertol(start_positives,start_negatives,too_close, 'DataScale', 1); %{'OutputAllIndices',true %}
            % returns an array containing logical 1 (true) where the elements of A are within tolerance of the elements in B
            % also returns an array, LocB, that contains the index location in B for each element in A that is a member of B.
            %There is probably a good way to use this to get rid of some
            %more errors
            
            f_start_positives = start_positives(~pos_pres_in_neg);
            temp = start_negatives;
            temp(find(idx_of_loc_in_neg~=0)) = [];
            f_start_negatives = temp;
            clear temp;
            
            %now have indices of all the resets
            
            obj.evaporation_times = f_start_positives;
            obj.reset_times = f_start_negatives;
            %now need to discount these from the list of markers and treat
            %them differently
        end
        function processHumanMarkedPts(obj)
            %get all of the markers
            
            
        end
        function processCptMarkedPts(obj)
            
        end
        function vv = getVoidedVolume(obj)
            %NYI
        end
        function vt = getVoidingTime(obj)
            %NYI
        end
    end
    
end

