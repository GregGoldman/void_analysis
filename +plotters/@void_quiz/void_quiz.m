classdef void_quiz < handle
    %
    %   class:
    %   plotters.void_quiz
    %
    %   Controls the GUI
    
    %{
    GUI Tags:
    ---------
     next_button
     back_button
     plot_panel
   
 
    TODO:
    --------

    %}
    
    properties
        fig_handle
        h
        plot_handle
        
        expt_file_list_result
        expt_file_paths
        
        cur_expt
        cur_expt_possible_voids
        cur_expt_marked_voids %the new points that the user marks
        
        % [x][y][degree of certainty]
        %{
                degree of certainty = 1 means a sure void
                degree of certainty = 2 means a possible void
        %}
        
        cur_stream_idx
        cur_stream
        cur_stream_data
        filtered_cur_stream_data
        
        cur_marker_idx
        cur_marker
        
        % info about the mouse which will apply to the top plot
        hit_data
        
        cur_disp_range
        
    end
    methods
        function obj = void_quiz()
            %
            %   obj = plotters.void_quiz();
            
            gui_path = fullfile('C:\Repos\void_analysis\+plotters\@void_quiz\void_quiz_gui.fig');
            obj.fig_handle = openfig(gui_path);
            obj.h = guihandles(obj.fig_handle);
            setappdata(obj.fig_handle,'obj',obj);
            
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
            
            
            %   instantiate the callbacks
            set(obj.h.next_button, 'String', 'Next');
            set(obj.h.next_button, 'Callback', @(~,~)obj.cb_nextPressed());
            set(obj.h.back_button, 'String', 'Back');
            set(obj.h.back_button, 'Callback', @(~,~)obj.cb_backPressed());
            
            obj.initSubplot();
            
            obj.cur_stream_idx = 1; %load the first stream first (analog Channel 01);
            obj.cur_marker_idx = 2;
            obj.cur_expt_marked_voids = [];
            
            % load the first set of data
            %file_path = obj.;
            file_path = obj.expt_file_paths{1};
            obj.loadExpt(file_path);
            
            
            obj.cur_disp_range = [];
            obj.findPossibleVoids();
            
        end
        function loadExpt(obj, file_path)
            obj.cur_expt = notocord.file(file_path);
            
            chan_info = table2cell(obj.cur_expt.chan_info);
            temp = chan_info(:,3);
            
            [B I J] = unique(temp);
            for ind = 1:length(B);
                count(ind) = length(find(J==ind));
            end
            % if count == 9, then there are only event markers, not start
            % and stop markers. If it is 17(?) then it has start and stop
            % markers
            num_channels = 8;
            
            %{
              TODO
              if (count(1) == 9)
 
              else
                  
              end
            %}
            %event markers 2 goes with channel 01
            obj.updateStream();
        end
        function updateStream(obj)
            obj.cur_stream = obj.cur_expt.getStream(['Analog Channel  0', sprintf('%d',obj.cur_stream_idx)]);
            obj.cur_marker = obj.cur_expt.getStream(['Event markers ', sprintf('%d',obj.cur_marker_idx)]);
        end
        function initSubplot(obj)
            obj.plot_handle = subplot(2,1,1, 'Parent', obj.h.plot_panel);
            set(obj.plot_handle, 'ButtonDownFcn', @obj.plot_clicked);
            set(obj.plot_handle, 'NextPlot', 'replacechildren');
            set(gcf,'toolbar','figure'); %turn on the toolbar so that you can zoom...
        end
        function plot_clicked(obj,~,hit_data)
            obj.hit_data = hit_data;
            obj.cur_expt_marked_voids{end+1,1} = obj.hit_data.IntersectionPoint(1);
            obj.cur_expt_marked_voids{end,2} = obj.hit_data.IntersectionPoint(2);
            
            if (obj.hit_data.Button == 1)
                %yes void
                obj.cur_expt_marked_voids{end,3} = 1;
            elseif (obj.hit_data.Button == 2)
                
            else % (==3)
                %maybe void
                obj.cur_expt_marked_voids{end,3} = 2;
            end
        end
        function findPossibleVoids(obj)
            filter = sci.time_series.filter.butter(1,4,'low'); %order, freq, type
            obj.cur_stream_data = obj.cur_stream.getData();
            % plot(obj.cur_stream_data,'axes', obj.plot_handle);
            
            obj.filtered_cur_stream_data = obj.cur_stream_data.filter(filter);
            plot(obj.filtered_cur_stream_data,'axes', obj.plot_handle);
         
            
            start_datetime = obj.cur_stream_data.time.start_datetime;
            t = obj.cur_marker.times - start_datetime;
            % t is now the fraction of a day since the start
            % multiply by 86400 seconds in a day to convert to seconds to match up with
            % the locations of the markers in the graph.
            
            t2 = 86400 * t; %t2 is now the location since time = 0 that the marker is found at
            
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
            
            time_interval = 20;%seconds, eg the spacing of checking
            step_size = time_interval/obj.filtered_cur_stream_data.time.dt; % a number of data points
            n_steps = floor(obj.filtered_cur_stream_data.time.n_samples / step_size); %the number of steps to get thru all the data points
            dt = obj.filtered_cur_stream_data.time.dt;
            
            threshold = 0.2626;
            time_blocker = 50;
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
           
            %{
            yy = 0.*markers -0.5;
            hold on
            plot(obj.plot_handle,markers,yy, 'k*');
            %}
        end
        function forwardPlotRegion(obj)
            %
            %   picks a range of possible void points and moves the axes to
            %   view them up close
            
            
            if isempty(obj.cur_disp_range)
                obj.cur_disp_range = 1:5;
            else
            range = 5; %5 voiding points
            obj.cur_disp_range = obj.cur_disp_range(end)+1:obj.cur_disp_range(end)+range;     
            end
            %disp(obj.cur_disp_range);
            
            if obj.cur_disp_range(end) == length(obj.cur_expt_possible_voids)
                disp('congratulations! you''ve finished a whole stream!')
                return
            elseif obj.cur_disp_range(end) > length(obj.cur_expt_possible_voids)
               obj.cur_disp_range = obj.cur_disp_range(1):length(obj.cur_expt_possible_voids); 
            end
            
            
            poi = obj.cur_expt_possible_voids(obj.cur_disp_range); %points of interest
            axis([poi(1) - 100, poi(end)+100, -inf,inf]);  
            
            %{
            v = axis;
            xr = (v(2) - v(1));
            yr = (v(4) - v(3));
            axis(v+ 0.1*[-xr xr -yr yr])
            %}
        end
        function backwardPlotRegion()
             if isempty(obj.cur_disp_range)
                obj.cur_disp_range = 1:5;
             else
            range = 5; %5 voiding points
            obj.cur_disp_range = obj.cur_disp_range(1)-range:obj.cur_disp_range(1)-1;  
                 
        end
        end
    end
    methods %callback functions
        function cb_nextPressed(obj)
            obj.forwardPlotRegion();
        end
        function cb_backPressed(obj)
            obj.backwardPlotRegion();
        end
    end
end
