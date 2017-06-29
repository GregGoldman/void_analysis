classdef analysis_GUI < handle
    %
    %   class:
    %   plotters.analysis_GUI
    %
    %   Controls the GUI
    %
    %   Instructions:
    %{
    open the gui by typing:   obj = plotters.analysis_GUI;
    Type in the directory which you would like to serach and press Browse Experiments
    Select the experiment of interest
    Click Process Stream
    %}
    
    %{
    GUI Tags:
    ---------
    expt_id_text
    stream_num_text
    top_axes
    bottom_axes
    next_button
    prev_button
    comment_text
    details_listbox

    next_stream_button
    browse_button
    next_expt_button
    file_path_edit_text
    reset_view_button
    save_close_button
    stream_select_edit_text
    process_stream_button
    
    event_selection_listbox
    times_listbox
    
    certainty_listbox
    filter_menu
    
    nudge_right
    nudge_left
    
    
    TODO:
    --------
    add a place to update info about the processing: minimum volume
                                                     maximum slope
                                                     ??
    everything in code that is about certainty should be changed to
    linearity. certainty is not an accurate representation of what is being
    measured.
    
    BREAK THIS UP INTO SMALLER CLASSES!!!!!!!!!
    %}
    properties
        h
        fig_handle
        
        void_finder2
        expt_name_list
        expt_path_list
        selected_expt_idx
        selected_expt_path
        cur_stream_number
        stream_has_been_processed
        
        top_plot_handle

        marker_objs
        
        start_marker_times
        end_marker_times
        
        vv
        vt
        
        cur_marker_idx_in_times_listbox = 0;
        cur_marker_idx_in_marker_array = 0;
        
        zoom_lines
        
        looking_at_voids_flag
        % boolean. If true, then times displayed in times_list listbox are
        % from void markers. If false, then times displayed are those which
        % don't have markers and were flagged as a certain type of error
        void_just_deleted
        % if a void was just deleted, we want next/previous buttons to not
        % skip what becomes the current void when there is an index shift
        % from the deletion
        
        % for times that are not void markers
        times_of_interest
        time_index
        
        
        deleted_starts
        deleted_ends
        
        certainty_level
        certainty_array
        
        marker_idxs_shown_in_times_listbox
        
        data_to_plot
        data_plot_handle
        
        comments

    end
    methods
        function obj = analysis_GUI()
            
            % find the gui
            BASE_PATH = sl.stack.getMyBasePath;
            fig_name = 'analysis_GUI.fig';
            gui_path = fullfile(BASE_PATH, fig_name);
            
            % initialize the figure
            obj.fig_handle = openfig(gui_path);
            obj.h = guihandles(obj.fig_handle);
            setappdata(obj.fig_handle,'obj',obj);
            set(obj.fig_handle, 'toolbar', 'none');
            
            
            
            % instantiate the callbacks
            set(obj.h.browse_button, 'callback', {@obj.cb_browseClicked})
            set(obj.h.next_button, 'callback',{@obj.cb_nextPressed});
            set(obj.h.prev_button, 'callback',{@obj.cb_prevPressed});
            set(obj.h.next_stream_button, 'callback',{@obj.cb_nextStream});
            set(obj.h.next_expt_button, 'callback', {@obj.cb_nextExpt});
            set(obj.h.reset_view_button, 'callback', {@obj.cb_resetView});
            set(obj.h.save_close_button, 'callback',{@obj.cb_saveAndClose});
            set(obj.h.stream_select_edit_text, 'callback', {@obj.cb_chooseStream});
            set(obj.h.process_stream_button, 'callback', {@obj.cb_processStream});
            set(obj.h.comment_text, 'callback', {@obj.cb_commentMade});
            set(obj.h.times_listbox, 'callback', {@obj.cb_newTimeSelected});
            set(obj.h.event_selection_listbox, 'callback', {@obj.cb_eventTypeChanged});
            set(obj.h.certainty_listbox, 'callback', {@obj.cb_certaintySortChanged});
            set(obj.h.filter_menu, 'callback', {@obj.cb_filterChanged});
            set(obj.h.nudge_right, 'callback', {@obj.cb_nudge});
            set(obj.h.nudge_left, 'callback', {@obj.cb_nudge});
            
            
            a = obj.h.top_axes;
             
            % annoying matlab default
            set(a,'NextPlot', 'replacechildren');
            b = obj.h.bottom_axes;
            set(b,'NextPlot', 'replacechildren');
                  
            axes(a)
            grid on
            axes(b)
            grid on
            
            set(a,'buttondownfcn', {@obj.cb_addVoid});
            obj.showScale(a);

            % show the lists we can at this point
            obj.initEventTypes;
            obj.initCertaintyList;
            
            % set defaults
            obj.void_finder2 = analysis.void_finder2;
            obj.zoom_lines.a = [];
            obj.zoom_lines.b = [];
            obj.looking_at_voids_flag = true;
            obj.void_just_deleted = false;
            obj.deleted_starts = [];
            obj.deleted_ends = [];
            % file search related stuff
            RAW_DATA_ROOT = dba.getOption('raw_data_root');
            set(obj.h.file_path_edit_text, 'string', RAW_DATA_ROOT);
            
            %{
            % TODO: update this so that if accidentally closed, data still
            % gets saved
            set(obj.fig_handle, 'closerequestfcn', {@obj.cb_closeRequested})
            %}
        end
        function browseExpts(obj)
            %
            %   obj.browseExpts()
            %
            %   Gets the value of the filepath in the edittext area. Then
            %   opens the expt_browser. The expt_browser selects the
            %   current experiment (see plotters.expt_browser) and calls
            %   initExptAndStream
            
            file_path = get(obj.h.file_path_edit_text, 'String');
            obj.void_finder2.data.findExptFiles(file_path);
            list_result = obj.void_finder2.data.expt_file_list_result;
            obj.expt_name_list = list_result.file_names;
            obj.expt_path_list = list_result.file_paths;
            
            plotters.expt_browser(obj);
            % updates obj.selected_expt_idx
            % calls obj.initExptAndStream once an experiment is selected
        end
        function initExptAndStream(obj)
            %
            %   obj.initExptAndStream()
            %
            %   For the current experiment, load it and update the stream
            
            obj.cur_stream_number = 1;
            obj.selected_expt_path = obj.expt_path_list{obj.selected_expt_idx};
            set(obj.h.expt_id_text, 'String', obj.selected_expt_path);
            obj.void_finder2.data.loadExpt(obj.selected_expt_path);
            
            obj.h__streamUpdated();
            %   Loads the current stream and corresponding derivatives,
            %   etc. Then plots the raw stream data on both sets of axes in
            %   the GUI. Also initialized the cur_marker_idx to be 0. Also
            %   updates the labels at the top of the GUI
            disp('done');
            obj.showScale(obj.h.top_axes);
        end
        function processStream(obj)
            %
            %   obj.processStream()
            %
            %   Finds the possible voids in the data and updates the lists
            %   on the GUI. Then plots all of the markers
            
            if isempty(obj.void_finder2.data.cur_stream)
                return
            end
            if obj.stream_has_been_processed
                response = questdlg('Are you sure you want to reprocess this stream? All data will be overwritten.','', 'Yes', 'No', 'No');
                switch response
                    case 'No'
                        return
                    case 'Yes'
                        
                    otherwise %empty case (user hit (X))
                        return                   
                end
            end
            obj.void_finder2.findPossibleVoids();
            obj.looking_at_voids_flag = true; %should already be true, just a backup
            
            obj.plotMarkers();
            
            obj.certainty_level = 'all';
            obj.showEventType('Voids Found');
            set(obj.h.times_listbox, 'Value',1)
            obj.jumpToMarker(1);
            
            obj.stream_has_been_processed = true;
            obj.showScale(obj.h.top_axes);
        end
        function plotMarkers(obj)
            %
            %   obj.plotMarkers()
            %
            %   plots the markers found by obj.processStream();
            %   Creates them as line objects which can be dragged. Also
            %   creates the marker objects which hold the handles to the
            %   lines as well as the marker type and index of the marker
            
            % delete the old markers
            
            for k = 1:length(obj.marker_objs)
                if ~isempty(obj.marker_objs{k})
                    obj.marker_objs{k}.clearLineObjs();
                    delete(obj.marker_objs{k});
                end
            end

            a = obj.h.top_axes;
            
            obj.start_marker_times = obj.void_finder2.void_data.updated_start_times;
            obj.end_marker_times = obj.void_finder2.void_data.updated_end_times;
            
            obj.marker_objs = cell(1,length(obj.start_marker_times));
            
            hold on
            for k = 1:length(obj.start_marker_times)
                xval1 = obj.start_marker_times(k);
                yval1 = obj.void_finder2.data.getDataFromTimePoints('raw', xval1);
                temp1 = line(a,xval1,yval1, 'color', 'black', 'marker', 'o', 'markersize', 12, 'hittest', 'on');
                
                xval2 = obj.end_marker_times(k);
                yval2 = obj.void_finder2.data.getDataFromTimePoints('raw',xval2);
                temp2 = line(a,xval2,yval2, 'color', 'black','marker', 's', 'markersize', 12, 'hittest', 'on');
                
                obj.marker_objs{k} = plotters.marker_pair(obj,k,temp1, temp2);
                set(temp1,'buttondownfcn', {@obj.cb_clickmarker,obj.marker_objs{k}})
                set(temp2,'buttondownfcn', {@obj.cb_clickmarker,obj.marker_objs{k}})    
            end

            % sometimes the buttondownfcn gets overwritten. It is unclear
            % when, easier to just do this after each plot:
            set(a,'buttondownfcn', {@obj.cb_addVoid});
            set(a,'NextPlot', 'replacechildren');
        end
        function commentProximityIssues(obj)
            %
            %   obj.commentProximityIssues
            %
            %   Puts a comment in those makers which have proximity issues
            %
            
            obj.getDataFromAllMarkers();
            starts = obj.void_finder2.void_data.proximity_issue_starts;
            % only have to compare the starts because both starts and ends
            % are tagged if either side is close to another void
            
            for k = 1:length(starts)
                temp = obj.start_marker_times == starts(k);
                if sum(temp) == 1
                    cur_marker = obj.marker_objs{temp};
                    cur_marker.comment = 'Potential Proximity Issue';
                end
            end
        end
        function showEventType(obj, event_type)
            %
            %    obj.showEventType(event_type)
            %
            %    Populates the list of times to show void markers which were
            %    removed based on different circumstances. Good way to
            %    review areas that may have faulty data
            %    Inputs:
            %    -----------
            %    - event_type: string
            
            
            
            % get time periods of 60 seconds each
            obj.looking_at_voids_flag = false;
            switch event_type
                case 'Voids Found'
                    obj.looking_at_voids_flag = true;
                case 'Possible Solids'
                    a = obj.void_finder2.void_data.possible_solid_start_times;
                    b = obj.void_finder2.void_data.possible_solid_end_times;
                case 'Calibration'
                    a = obj.void_finder2.void_data.calibration_start_times;
                    b = obj.void_finder2.void_data.calibration_end_times;
                case 'Spikes'
                    a =  obj.void_finder2.void_data.spike_start_times;
                    b =  obj.void_finder2.void_data.spike_end_times;
                case 'Evaporations'
                    a =  obj.void_finder2.void_data.evap_end_times;
                    b =  obj.void_finder2.void_data.evap_start_times;
                case 'Glitches'
                    a =  obj.void_finder2.void_data.glitch_start_times';
                    b =  obj.void_finder2.void_data.glitch_end_times';
                case 'Bad Resets'
                    % too close to glitches, evaporations, etc
                    a = obj.void_finder2.void_data.removed_reset_start_times;
                    b = obj.void_finder2.void_data.removed_reset_end_times;
                case 'Unpaired'
                    a =  obj.void_finder2.void_data.unpaired_start_times;
                    b =  obj.void_finder2.void_data.unpaired_end_times;
                case 'Too Small'
                    a = obj.void_finder2.void_data.too_small_start_times;
                    b = obj.void_finder2.void_data.too_small_end_times;
                case 'Slope/Solids'
                    a = obj.void_finder2.void_data.solid_void_start_times;
                    b = obj.void_finder2.void_data.solid_void_end_times;
                case 'User-Deleted'
                    a = obj.deleted_starts;
                    b = obj.deleted_ends;
                otherwise
                    error('there''s a bug here')
            end
            if (~obj.looking_at_voids_flag)
                c = union(a,b);
                d = sort(c);
                
                obj.times_of_interest = [];
                
                tolerance = 15;
                stop_idx = length(d);
                k = 1;
                while(k < stop_idx)
                    temp = d - d(k) < tolerance;
                    % temp is mask of indices within tolerance of time of
                    % d(k)
                    idxs_in_range = find(temp);

                    mid_point = (d(k)+ d(idxs_in_range(end)))/2; %middle of all the points in the range of the data
                    obj.times_of_interest(end+1) = mid_point;
           
                    temp2 = find(~temp);
                    % temp 2 is all the times not within the tolerance (all
                    % times greater than d(k) + tolerance)
                    
                    if isempty(temp2)
                        break
                    else
                        k = temp2(1); %skip over the times we have already seen
                    end
                end
                % times_of_interest is now an array that will have start
                % times that skip over any other points within 1 minute
            end
            obj.refreshTimesList();
            % if obj.looking_at_voids_flag is true, then the call of this
            % function will take care of selecting those times instead of
            % whatever is in times_of_interest
        end
        function refreshTimesList(obj)
            %
            %   obj.refreshTimesList()
            %
            %   updates the list of times to view (upper right of GUi)
            obj.getDataFromAllMarkers();
                % now have start/end times, vv, vt, and certainty for each marker pair
            if obj.looking_at_voids_flag

                certainty = obj.certainty_level;
                temp = obj.h__certaintyToNum(certainty);
                
                if temp ~= 0
                  mask = obj.certainty_array == temp;
                else
                  mask = ones(1,length(obj.start_marker_times));
                end
                
                mask = logical(mask);
                displayed_times = obj.start_marker_times(mask);
                displayed_vv = obj.vv(mask);
                displayed_vt = obj.vt(mask);
                
                obj.marker_idxs_shown_in_times_listbox = find(mask);
                
                data_to_show = cell(length(displayed_times),1);
                for k = 1: length(data_to_show)
                    row_string = sprintf('T: %5.0f  |   VV: %2.1f   |   VT: %2.1f', displayed_times(k), displayed_vv(k), displayed_vt(k));
                    data_to_show{k} = row_string;
                end
            else
                data_to_show = cell(length(obj.times_of_interest));
                for k = 1:length(obj.times_of_interest)
                    data_to_show{k} = sprintf('T: %5.0f',obj.times_of_interest(k));
                end
            end
            times_list = obj.h.times_listbox;
            set(times_list, 'string', data_to_show);
        end
        function getDataFromAllMarkers(obj)
            %
            %
            %   obj.getDataFromAllMarkers()
            %
            %   gets start times, end times, voided volume, voiding time,
            %   and certainty from each of the marker objects.
            
            
            n = length(obj.marker_objs);
            
            obj.start_marker_times = zeros(1,n);
            obj.end_marker_times = zeros(1,n);
            obj.vv = zeros(1,n);
            obj.vt = zeros(1,n);
            obj.certainty_array = zeros(1,n);
            obj.comments = cell(1,n);
            for k = 1:n
                % Q: should this be a method of the marker object?
                cm = obj.marker_objs{k};
                obj.start_marker_times(k) = cm.start_time;
                obj.end_marker_times(k) = cm.end_time;
                obj.vv(k) = cm.vv;
                obj.vt(k) = cm.vt;
                obj.certainty_array(k) = cm.certainty;
                obj.comments{k} = cm.comment;
            end
        end
        function jumpToMarker(obj, index)
            %
            %    obj.jumpToMarker(index)
            %
            %    Switches the view to that of the marker indicated by index
            %    **the index references the number in the list of updated
            %    times, not in the list of overall markers!
            %
            %    Inputs:
            %    -------
            %    index

            k = obj.marker_idxs_shown_in_times_listbox;
            
            if index < 1
                return
            elseif index > length(k)
                return
            end
            
            obj.cur_marker_idx_in_times_listbox = index;
            obj.cur_marker_idx_in_marker_array = k(index);
            
            cur_start_time = obj.start_marker_times(obj.cur_marker_idx_in_marker_array);
            cur_end_time = obj.end_marker_times(obj.cur_marker_idx_in_marker_array);
            
            mid_length = (cur_start_time + cur_end_time)/2;
            right = mid_length + 5;
            left = mid_length - 5;
            
            data_in_range = obj.void_finder2.data.getDataFromTimeRange('raw',[left, right]);
            miny = min(data_in_range);
            maxy = max(data_in_range);
            
            % try to get the start/end window to be 10 seconds long
            while right < cur_end_time
                right = right + 0.5;
            end
            while left > cur_start_time
                left = left - 0.5;
            end

            % try to get the vertical window to be 2 units tall
            mid_height = (miny + maxy)/2;
            top = mid_height + 1;
            bottom = mid_height - 1;
            while top < maxy
                top = top + 0.1;
            end
            while bottom > miny
                bottom = bottom - 0.1;
            end
            
            a = obj.h.top_axes;
            axes(a);
            axis([left, right, bottom, top])
            obj.syncViewLines();
            obj.updateMarkerDetailsBox();
            obj.updateCommentBox();
            set(obj.h.times_listbox,'Value',obj.cur_marker_idx_in_times_listbox);
            obj.showScale(obj.h.top_axes);
        end
        function syncViewLines(obj,~,~)
            %
            %   obj.syncViewLines(src, ev)
            %
            %   **This is used both as a callback function and is regularly
            %   used by other functions
            %       (not good, need to update)
            %
            %   When the zoom is changed on the top plot, the lines on the
            %   bottom plot adjust to show where in the data you are
            %   looking closely
            
            a = obj.h.top_axes;
            xa = a.XLim(1);
            xb = a.XLim(2);
            
            b = obj.h.bottom_axes;
            axes(b);
            
            hold on;
            
            %   if after some sort of reset we lose the lines, need to
            %   bring them back
            if isempty(obj.zoom_lines.a) || ~obj.zoom_lines.a.isvalid
                axes(b)
                axis auto
                ylow = b.YLim(1);
                yhigh = b.YLim(2);
                obj.zoom_lines.a = plot([xa, xa], [ylow, yhigh], 'r-', 'LineWidth', 2, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickLine});
                obj.zoom_lines.b = plot([xb, xb], [ylow, yhigh],'r-', 'LineWidth', 2,'hittest', 'on', 'buttondownfcn', {@obj.cb_clickLine});
                axes(a)
            end
            
            set(obj.zoom_lines.a, 'xdata',[xa, xa]);
            set(obj.zoom_lines.b, 'xdata', [xb, xb]);
        end
        function updateCommentBox(obj)
            %
            %   obj.updateCommentBox()
            %
            %   If there is a comment for a marker, that comment is
            %   displayed in the box.
            
            cur_idx = obj.cur_marker_idx_in_marker_array;
            cur_marker = obj.marker_objs{cur_idx};
            
            to_show = cur_marker.comment;          
            
            if isempty(to_show)
                to_show = 'Enter a comment';                
            end
            
            set(obj.h.comment_text, 'String', to_show)
        end
        function updateMarkerDetailsBox(obj)
            %
            %   obj.updateMarkerDetailsBox()
            %
            %   updates the list of details including start time, end time,
            %   voided volume, voiding time, and certainty
                        
            cur_idx = obj.cur_marker_idx_in_marker_array;
            cur_marker = obj.marker_objs{cur_idx};

            data = cell(5,1);
            a = cur_marker.start_handle.XData;
            b = cur_marker.end_handle.XData;
            c = cur_marker.vv;
            d = cur_marker.vt;
            e = cur_marker.certainty;
            
            data{1} = ['Start Time: ', num2str(a)];
            data{2} = ['End Time: ', num2str(b)];
            data{3} = ['Void Volume: ', num2str(c)];
            data{4} = ['Void Time: ', num2str(d)];
            data{5} = ['Linearity: ', num2str(e)];
            
            set(obj.h.details_listbox, 'String', data)
        end
        function scrollRight(obj)
            %
            %   obj.scrollRight
            %
            %   Moves the viewing window one void to the right
            
            obj.h__scroll(1);
        end
        function scrollLeft(obj)
            %
            %   obj.scrollLeft
            %
            %   Moves the viewing window one void to the left
            
            obj.h__scroll(-1);
        end
        function resetView(obj)
            %
            %   obj.resetView()
            %
            %   Resets the viewing window to show the full dataset
            %   Sometimes the axis command gets the view stuck in a small
            %   area
            
            axes(obj.h.bottom_axes)
            axis auto
            axes(obj.h.top_axes);
            axis auto;
            axis normal
            obj.syncViewLines();
            obj.showScale(obj.h.top_axes);
        end
        function saveCurrentData(obj)
            %
            %   obj.saveCurrentData(obj)
            %
            %   Saves the start/end times, voided volume, and voiding time
            %   found for the given stream to the directory which the user
            %   specifies (TODO: save default!!)
            
            obj.getDataFromAllMarkers();
            
            PACKAGE_ROOT = sl.stack.getPackageRoot;
            
            filepath = fullfile(PACKAGE_ROOT,'saved_data');
            
            prompt = {'Please type where you would like files to be saved'};
            dlg_title = 'Input';
            num_lines = 1;
            defaultans = {filepath};
            save_loc = inputdlg(prompt, dlg_title, num_lines, defaultans);
            
            if isempty(save_loc)
                disp('user cancelled save')
                return
            end

            current_loc = cd(save_loc{1});
            
            file_path = obj.expt_path_list{obj.selected_expt_idx};
            
            start_times = obj.start_marker_times;
            end_times = obj.end_marker_times;
            vv = obj.vv;
            vt = obj.vt;
            comments = obj.comments;
            
            [~, name, ~] = fileparts(file_path);
            file_name = sprintf('%s_%s',name,'reviewed');
            save(file_name,'start_times', 'end_times', 'vv', 'vt', 'comments');
            disp('file saved to:');
            disp(save_loc);
            disp(file_name);
            disp('\n');
            cd(current_loc);
        end
        function clearPlots(obj)
            %
            %   obj.clearPlots()
            %
            %   Clears everything on both plots to start fresh. Mostly a
            %   function for debugging purposes
            
            a = obj.h.top_axes;
            b = obj.h.bottom_axes;
            cla(a);
            cla(b);
            a = obj.h.top_axes;
            set(a,'buttondownfcn', {@obj.cb_addVoid});
            set(a,'NextPlot', 'replacechildren');
        end
        function updateComment(obj, comment)
            %
            %   obj.updateComment(comment)
            %
            %   Stores the message to the 'comment' property of the start
            %   marker. End markers do not carry comments.
            %
            %   TODO: have comments be displayed in the box if they have
            %   been previously saved.
            
            cur_marker = obj.marker_objs{obj.cur_marker_idx_in_marker_array};
            cur_marker.comment = comment;
        end
        function jumpToTime(obj, index)
            %
            %   obj.jumpToTime
            %
            %   When looking at times of interest (not markers), jumps to a
            %   new time window of 10 seconds from the time point of
            %   interest. Plots any markers in the window with * 
            
            if ~isempty(obj.times_of_interest)
                obj.time_index = index;
                start = obj.times_of_interest(index);
                
                left = start - 10;
                right = start + 10;
                
                if left < 0
                    left = 0;
                end
                end_time = obj.void_finder2.data.cur_stream_data.time.end_time;
                if right > end_time
                    right = end_time;
                end
                data_in_range = obj.void_finder2.data.getDataFromTimeRange('raw',[left, right]);
                
                
                miny = min(data_in_range);
                maxy = max(data_in_range);
                midy = (miny + maxy) /2;
                
                bottom = midy - 1.5;
                top = midy + 1.5;
                
                while bottom > miny
                    bottom = bottom - 0.1;
                end
                while(top < maxy)
                    top = top + 0.1;
                end
                
                a = obj.h.top_axes;
                axes(a);
                axis([left, right, bottom, top])
                obj.syncViewLines();
            else
                obj.resetView();
            end
            set(obj.h.times_listbox, 'value', obj.time_index);
            obj.showScale(obj.h.top_axes);
        end
        function filterChanged(obj, selection)
            %
            %   obj.filterChanged(selection)
            %
            %   Changes the level of filtering that data goes through
            %   before plotting
            %
            switch selection
                case 1
                    %plot the raw data
                    obj.data_to_plot = obj.void_finder2.data.cur_stream_data;
                case 2
                    % filter lightly and plot
                    filter = sci.time_series.filter.smoothing(0.01,'type','rect');
                    obj.data_to_plot = obj.void_finder2.data.cur_stream_data.filter(filter);
                case 3
                    % plot the strongly filtered data from void_finder2
                    obj.data_to_plot = obj.void_finder2.data.filtered_cur_stream_data;
                    msgbox('warning: strongly filtered data causes timeshifts when viewing data')
                    pause(2)
            end
            obj.h__plotTopStream();
            obj.showScale(obj.h.top_axes);
        end
        function nextStream(obj)
            %
            %   obj.nextStream()
            %
            %   Increases the stream number by one and plots it
            
            index = obj.cur_stream_number + 1;
            obj.jumpToStream(index);
        end
        function jumpToStream(obj, index)
            %
            %   obj.jumpToStream(index)
            %
            %   Go to a specific stream
            %   Inputs:
            %   --------
            %   - index: double -- which stream to go to
            
            if index > 9
                error('outside of range of streams')
            end
            obj.cur_stream_number = index;
            obj.h__streamUpdated();
        end
        function nudge(obj,duration)
            %
            %   obj.nudge(duration)
            %
            %   Shifts the viewing window over by duration
            
            ax = obj.h.top_axes;
            axes(ax)
            cur_left = ax.XLim(1);
            cur_right = ax.XLim(2);
            
            new_left = cur_left + duration;
            new_right = cur_right + duration;
            
            axis([new_left,new_right,ax.YLim(1), ax.YLim(2)])
            obj.showScale(ax); 
        end
    end
    methods % callback functions
        function cb_nextPressed(obj, ~,~)
            if obj.looking_at_voids_flag
                obj.scrollRight();
            else
                if obj.time_index + 1 <= length(obj.times_of_interest)
                    obj.time_index = obj.time_index + 1;
                    obj.jumpToTime(obj.time_index);
                end
            end
            obj.showScale(obj.h.top_axes);
        end
        function cb_prevPressed(obj,~,~)
            if obj.looking_at_voids_flag
                obj.scrollLeft();
            else
                if obj.time_index - 1 > 0
                    obj.time_index = obj.time_index - 1;
                    obj.jumpToTime(obj.time_index);
                end
            end
            obj.showScale(obj.h.top_axes);
        end
        function cb_browseClicked(obj,~,~)
            obj.browseExpts();
        end
        function cb_nextStream(obj,~,~)
            temp = questdlg('Are you sure you would like to go to the next stream?','','yes','no', 'no');

           
            switch temp
                case 'yes'
                    disp('saving files');
                otherwise
                    disp('cancelled');
                    return
            end
            obj.saveCurrentData();
            obj.nextStream();
        end
        function cb_nextExpt(obj, ~, ~)
            message = 'Are you sure you want to move on to the next experiment?';
            title = '';
            choice = questdlg(message,title,'yes', 'no', 'no');
            switch choice
                case 'yes'
                    disp('saving files');
                otherwise
                    disp('cancelled');
                    return
            end
            obj.saveCurrentData();
        end
        function cb_resetView(obj,~,~)
            obj.resetView();
            obj.showScale(obj.h.top_axes);
        end
        function cb_saveAndClose(obj,~,~)
            message = 'Are you sure you want to save and close?';
            title = '';
            choice = questdlg(message,title,'yes','no','no');
            switch choice
                case 'yes'
                    disp('saving files');
                otherwise
                    return
            end
            obj.saveCurrentData();
            close(obj.fig_handle)
        end
        function cb_chooseStream(obj,src,~)
            temp = src.String;
            index = str2double(temp);
            message = sprintf('Are you sure you want to jump to Stream %u ?',index);

            
            choice = questdlg(message, '', 'yes',',no','no');
            switch  choice
                case 'yes'
                    obj.jumpToStream(index);
                otherwise
                    return;
            end
        end
        function cb_processStream(obj,~,~)
            obj.processStream();
        end
        function cb_commentMade(obj,src,~)
            comment = src.String;
            obj.updateComment(comment);
        end
        function cb_newTimeSelected(obj,src,ev)
            if isempty(src.String)
                return
            end
           
            index = src.Value;
            if obj.looking_at_voids_flag
                obj.jumpToMarker(index);
            else
                obj.jumpToTime(index);
            end
        end
        function cb_eventTypeChanged(obj,src,ev)
            event_type = src.String{src.Value};
            set(obj.h.times_listbox,'Value',1); % to not go out of range
            obj.showEventType(event_type);
            if obj.looking_at_voids_flag
                obj.jumpToMarker(1);
            else
                obj.jumpToTime(1);
            end
        end
        function cb_certaintySortChanged(obj,src,ev)
           selection = src.String{src.Value};
           obj.certainty_level = selection;
           set(obj.h.times_listbox, 'value', 1);
           obj.looking_at_voids_flag = true;
           obj.refreshTimesList();
           
           obj.jumpToMarker(1);
        end
        function cb_filterChanged(obj,src,ev)
            selection = src.Value;
            obj.filterChanged(selection)
        end
        function cb_nudge(obj,src,ev)
            switch src.Tag
                case 'nudge_right'
                    obj.nudge(2);
                case 'nudge_left'
                    obj.nudge(-2);
            end
        end
    end
    methods % initialization of GUI
        function initCertaintyList(obj)
            to_display = {'All', 'Low', 'Medium', 'High'};
            set(obj.h.certainty_listbox, 'String', to_display)
        end
        function initEventTypes(obj)
            %
            %   obj.initEventTypes()
            %
            %   Updates the list of event types to look at.(ex spike times,
            %   evaporations, etc.)
            
            list = {'Voids Found'; 'Possible Solids'; 'Calibration' ; 'Spikes' ; 'Evaporations' ; 'Glitches'; 'Bad Resets' ; 'Unpaired'; 'Too Small'; 'Slope/Solids'; 'User-Deleted'};
            set(obj.h.event_selection_listbox, 'String', list);
        end
    end
    methods % callbacks for click and drag
        function cb_addVoid(obj,~,ev)
            if ev.Button == 2
                a = obj.h.top_axes;
                
                x1 = ev.IntersectionPoint(1) - 1;
                y1 = obj.void_finder2.data.getDataFromTimePoints('raw',x1);
                temp1 = line(a,x1,y1, 'color', 'black', 'marker', 'o', 'markersize', 12, 'hittest', 'on');
                x2 = ev.IntersectionPoint(1) + 1;
                y2 = obj.void_finder2.data.getDataFromTimePoints('raw', x2);
                temp2 = line(a,x2,y2, 'color', 'black', 'marker', 's', 'markersize', 12, 'hittest', 'on');
                
                obj.marker_objs{end+1} = plotters.marker_pair(obj,length(obj.marker_objs)+1,temp1,temp2);
                
                set(temp1, 'buttondownfcn', {@obj.cb_clickmarker,obj.marker_objs{end}});
                set(temp2, 'buttondownfcn', {@obj.cb_clickmarker,obj.marker_objs{end}});
 
                % TODO:
                % put this marker in order with the other markers (LOW
                % PRIORITY)
                
                
            obj.cur_marker_idx_in_marker_array = length(obj.marker_objs);
            cur_marker = obj.marker_objs{obj.cur_marker_idx_in_marker_array};

            certainty_as_num =  obj.h__certaintyToNum(obj.certainty_level);
            temp = (cur_marker.certainty == certainty_as_num) || certainty_as_num == 0;
            
            obj.getDataFromAllMarkers();
            if obj.looking_at_voids_flag && temp                
                obj.refreshTimesList();
                obj.cur_marker_idx_in_times_listbox = find(obj.marker_idxs_shown_in_times_listbox == cur_marker.marker_index);
                set(obj.h.times_listbox, 'Value',obj.cur_marker_idx_in_times_listbox);
            end
            obj.updateMarkerDetailsBox();
            obj.updateCommentBox();
            end
        end
        function cb_clickLine(obj,src,ev)
            %
            %
            %
            %
            if ev.Button == 1
                set(ancestor(src,'figure'), 'windowbuttonmotionfcn',{@obj.cb_dragLine,src})
                set(ancestor(src,'figure'),'windowbuttonupfcn',{@obj.cb_stopDraggingLine})
            end
        end
        function cb_dragLine(obj,fig,ev,src)
            coords=get(gca,'currentpoint');
            x=coords(1,1,1);
            
            end_time = obj.void_finder2.data.cur_stream_data.time.end_time;
            
            % prevent going out of range
            if x < 0 || x > end_time
                return
            end
            
            b = obj.h.bottom_axes;
            ylow = b.YLim(1);
            yhigh = b.YLim(2);
            
            x = [x x];
            y = [ylow yhigh];
            set(src,'xdata',x,'ydata',y);
        end
        function cb_stopDraggingLine(obj,fig,ev)
            set(fig,'windowbuttonmotionfcn','')
            set(fig,'windowbuttonupfcn','')
            
            % change the axes on the top plot now that the lines are in place
            a = obj.h.top_axes;
            axes(a);
            
            end_time = obj.void_finder2.data.cur_stream_data.time.end_time;

            a_loc = obj.zoom_lines.a.XData(1);
            b_loc =  obj.zoom_lines.b.XData(1);
            
            sorted_locs = sort([a_loc, b_loc]);
            minx = sorted_locs(1);
            maxx = sorted_locs(2);
            
            if minx > 0 && maxx < end_time
            data_in_range = obj.void_finder2.data.getDataFromTimeRange('raw', sorted_locs);
            miny = min(data_in_range);
            maxy = max(data_in_range);
            axis([minx, maxx, miny, maxy]);
            end
            obj.showScale(obj.h.top_axes);
        end
        function cb_clickmarker(obj,src,ev,marker_obj)
            %
            %   Inputs:
            %   -------
            %   src: the Line object which was clicked
            %   ev: the Hit object with details about the click
            
            %TODO: make this loop a helper function
   
            obj.cur_marker_idx_in_marker_array = marker_obj.marker_index;
            
            cur_marker = obj.marker_objs{obj.cur_marker_idx_in_marker_array};
            
            certainty_as_num =  obj.h__certaintyToNum(obj.certainty_level);
            temp = (cur_marker.certainty == certainty_as_num) || certainty_as_num == 0;
            if obj.looking_at_voids_flag && temp                
                obj.cur_marker_idx_in_times_listbox = find(obj.marker_idxs_shown_in_times_listbox == cur_marker.marker_index);
                obj.refreshTimesList();
                set(obj.h.times_listbox, 'Value',obj.cur_marker_idx_in_times_listbox);
            end
            obj.updateMarkerDetailsBox();
            obj.updateCommentBox();
            
            if ev.Button == 1
                set(ancestor(src,'figure'),'windowbuttonmotionfcn',{@obj.cb_dragmarker,src,marker_obj})
                set(ancestor(src,'figure'),'windowbuttonupfcn',{@obj.cb_stopdragging,src, marker_obj})
            elseif ev.Button == 3
                obj.h__deleteMarker(marker_obj)
            end
        end
        function cb_dragmarker(obj,fig,ev,src, marker_obj)
            coords=get(gca,'currentpoint');
            x=coords(1,1,1);
            end_time = obj.void_finder2.data.cur_stream_data.time.end_time;
            
            if x < 0 || x> end_time
                return
            end
            if src == marker_obj.start_handle
                if x >= marker_obj.end_handle.XData
                    return
                end
            elseif src == marker_obj.end_handle
                if x <= marker_obj.start_handle.XData
                    return
                end
            end

            y = obj.void_finder2.data.getDataFromTimePoints('raw',x);
            set(src,'xdata',x,'ydata',y);
        end
        function cb_stopdragging(obj,fig,ev,src, marker_obj)
            set(fig,'windowbuttonmotionfcn','')
            set(fig,'windowbuttonupfcn','')
            
            marker_obj.start_time = marker_obj.start_handle.XData;
            marker_obj.end_time = marker_obj.end_handle.XData;
            
            obj.cur_marker_idx_in_marker_array = marker_obj.marker_index;

            % TODO: give this it's own function (gets used frequently)
            cur_marker = obj.marker_objs{obj.cur_marker_idx_in_marker_array};
            
            certainty_as_num =  obj.h__certaintyToNum(obj.certainty_level);
            temp = (cur_marker.certainty == certainty_as_num) || certainty_as_num == 0;
            if obj.looking_at_voids_flag && temp                
                obj.cur_marker_idx_in_times_listbox = find(obj.marker_idxs_shown_in_times_listbox == cur_marker.marker_index);
                obj.refreshTimesList();
                set(obj.h.times_listbox, 'Value',obj.cur_marker_idx_in_times_listbox);
            end
            obj.updateMarkerDetailsBox();
            obj.updateCommentBox();
        end
    end
    methods (Hidden) % helpers
        function h__streamUpdated(obj)
            %
            %   obj.h__streamUpdated()
            %
            %   Loads the current stream and corresponding derivatives,
            %   etc. Then plots the raw stream data on both sets of axes in
            %   the GUI. Also initialized the cur_marker_idx to be 0. Also
            %   updates the labels at the top of the GUI
            
            obj.void_finder2.data.getStream(obj.cur_stream_number);
            set(obj.h.stream_num_text, 'String', obj.cur_stream_number);
           
            obj.data_to_plot = obj.void_finder2.data.cur_stream_data;
            
            
            obj.h__plotTopStream();
                
            b = obj.h.bottom_axes;
            hold off
            obj.void_finder2.data.plotData('raw',b);
            
            a = obj.h.top_axes;
            set(a,'fontsize',7);
            set(b,'fontsize',7);
            hold on
            obj.cur_marker_idx_in_marker_array = 0;
            obj.cur_marker_idx_in_times_listbox = 0;
            obj.stream_has_been_processed = false;
        end
        function h__plotTopStream(obj)
            %
            %   obj.plotStream
            %
            %   Plots the current stream using the data specified by
            %   obj.data_to_plot
            %
            %   TODO: move this method
            
            axes(obj.h.top_axes);
            set(obj.data_plot_handle,'Visible', 'off')
            hold on
            temp = obj.data_to_plot.plot('color',[0 0.4470 0.7410]);
            obj.data_plot_handle = temp.render_objs{1}.h_and_l.h_plot{1};
            uistack(obj.data_plot_handle,'bottom')
        end
        function h__scroll(obj, increment)
            %
            %   obj.h_scroll(obj, increment)
            %
            %   Used for moving one void right or left. Changes the current
            %   marker index by the magnitude of 'increment', then adjusts
            %   the viewing window and the vertical lines.
            %
            %   Inputs:
            %   ---------
            %   - increment: number of spots over to move, can be positive
            %                or negative
            
            if ~obj.void_just_deleted
                index = obj.cur_marker_idx_in_times_listbox + increment;
            else
                index = obj.cur_marker_idx_in_times_listbox;
            end
            obj.void_just_deleted = 0;
            
            obj.jumpToMarker(index);
            %   TODO: rollover
        end
        function h__deleteMarker(obj,marker_obj)
            %
            %   obj.h__deleteMarker(src)
            %
            %   Given the handle to a marker, deletes it and it partner
            %   Inputs:
            %   --------
            %   - marker_obj: the handle of the marker got from the callback
                       
            idx = marker_obj.marker_index;
            
            marker_obj.clearLineObjs();
            obj.deleted_starts(end+1) = marker_obj.start_time;
            obj.deleted_ends(end+1) = marker_obj.end_time;
            obj.start_marker_times(idx) = [];
            obj.end_marker_times(idx) = [];
            
            obj.cur_marker_idx_in_marker_array = marker_obj.marker_index;
            obj.marker_objs(idx) = [];
            
            % need to adjust all the indices
            for k = idx:length(obj.marker_objs)
                obj.marker_objs{k}.marker_index = k;
            end
            if obj.cur_marker_idx_in_marker_array > length(obj.marker_objs)
                obj.cur_marker_idx_in_marker_array = length(obj.marker_objs);
            end
            
            %this is now the marker that has shifted into the spot of
            %the old marker
            cur_marker = obj.marker_objs{obj.cur_marker_idx_in_marker_array};
            
            certainty_as_num =  obj.h__certaintyToNum(obj.certainty_level);
            temp = (cur_marker.certainty == certainty_as_num) || certainty_as_num == 0;
            
            if obj.looking_at_voids_flag && temp
                obj.refreshTimesList();
                obj.cur_marker_idx_in_times_listbox = find(obj.marker_idxs_shown_in_times_listbox == cur_marker.marker_index);
                set(obj.h.times_listbox, 'Value',obj.cur_marker_idx_in_times_listbox);
            end
            obj.updateMarkerDetailsBox();
            obj.updateCommentBox();
            obj.void_just_deleted = true;
            % TODO: sort by time (low priority)
        end
        function output = h__findMarkerTime(~,marker)
            output = marker.marker_handle.XData;
        end
        function output = h__certaintyToNum(~,certainty)
            switch lower(certainty)
                case 'all'
                    output = 0;
                case 'low'
                    output = 1;
                case 'medium'
                    output = 2;
                case 'high'
                    output = 3;
                otherwise
                    error('unknown selection. How did you do that?')
            end
        end
    end
end