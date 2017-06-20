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
    
    TODO:
    --------
    add a place to update info about the processing: minimum volume
                                                     maximum slope
                                                     ??
    
    figure out how saving should work
    
    Automatically load the default location to look for expt files
    
    Speed up the processing of expts
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
        
        top_plot_handle
        
        start_markers
        end_markers
        
        start_marker_times
        end_marker_times
        
        vv
        vt
        
        cur_marker_idx = 0;
        
        zoom_lines
    end
    methods
        function obj = analysis_GUI()
            gui_path = fullfile('C:\Repos\void_analysis\+plotters\@analysis_GUI\analysis_GUI.fig');
            obj.fig_handle = openfig(gui_path);
            obj.h = guihandles(obj.fig_handle);
            setappdata(obj.fig_handle,'obj',obj);
            set(obj.fig_handle, 'toolbar', 'none');
            
            obj.void_finder2 = analysis.void_finder2;
            
            set(obj.h.browse_button, 'callback', {@obj.cb_browseClicked})
            obj.zoom_lines.left = [];
            obj.zoom_lines.right = [];
            set(obj.h.top_axes,'ButtonDownFcn',{@obj.syncViewLines});
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
            set(obj.h.event_selection_listbox, 'callback', {@cb_eventTypeChanged});
            
            a = obj.h.top_axes;
            set(a,'buttondownfcn', {@obj.cb_addVoid});
            set(a,'NextPlot', 'replacechildren');
            
            b = obj.h.bottom_axes;
            set(b,'NextPlot', 'replacechildren');
            
            obj.initEventTypes;
            
            % TODO: update this so that if accidentally closed, data still
            % gets saved
            %{
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
        end
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
            a = obj.h.top_axes;
            axes(a);
            hold off
            obj.void_finder2.data.plotData('raw',a);
            
            b = obj.h.bottom_axes;
            axes(b);
            hold off
            obj.void_finder2.data.plotData('raw',b);
            
            set(a,'fontsize',7);
            set(b,'fontsize',7);
            hold on
            obj.cur_marker_idx = 0;
        end
        function nextStream(obj)
            %
            %   obj.nextStream()
            %
            %   Increases the stream number by one and plots it
            
            index = obj.cur_stream_number + 1;
            obj.jumpToStream(index);
            obj.h__streamUpdated();
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
        function processStream(obj)
            %
            %   obj.processStream()
            %
            %   Finds the possible voids in the data and updates the lists
            %   on the GUI. Then plots all of the markers
            
            obj.void_finder2.findPossibleVoids();
            obj.plotMarkers();
        end
        function plotMarkers(obj)
            %
            %   obj.plotMarkers()
            %
            %   plots the markers found by obj.processStream();
            %   Creates them as line objects which can be dragged. Also
            %   creates the marker objects which hold the handles to the
            %   lines as well as the marker type and index of the marker
            
            a = obj.h.top_axes;
            
            obj.start_marker_times = obj.void_finder2.void_data.updated_start_times;
            obj.end_marker_times = obj.void_finder2.void_data.updated_end_times;
            
            obj.start_markers  = cell(1,length(obj.start_marker_times));
            obj.end_markers = cell(1,length(obj.end_marker_times));
            hold on
            for k = 1:length(obj.start_marker_times)
                xval = obj.start_marker_times(k);
                yval = obj.void_finder2.data.getDataFromTimePoints('raw', xval);
                temp = line(a,xval,yval, 'color', 'black', 'marker', 'o', 'markersize', 10, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickmarker});
                obj.start_markers{k} = plotters.void_marker(obj.cur_marker_idx, 'start', temp);
            end
            for k = 1:length(obj.end_marker_times)
                xval = obj.end_marker_times(k);
                yval = obj.void_finder2.data.getDataFromTimePoints('raw', xval);
                temp = line(a,xval,yval, 'color', 'black','marker', 's', 'markersize', 10, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickmarker});
                obj.end_markers{k} = plotters.void_marker(obj.cur_marker_idx, 'end', temp);
            end
            
            % sometimes the buttondownfcn gets overwritten. It is unclear
            % when, easier to just do this after each plot:
            set(a,'buttondownfcn', {@obj.cb_addVoid});
            set(a,'NextPlot', 'replacechildren');
        end
        function processMarkerData(obj)
            %
            %   obj.processMarkers()
            %
            %   Extracts the start and end times from each of the pairs of
            %   markers which have been plotted. This method is necessary
            %   because the user can move markers around, and we need a way
            %   to get the start and end times easily from the line
            %   objects.
            %
            %   updates the following properties:
            %   - start_marker_times
            %   - end_marker_times
            %   - vv
            %   - vt
            
            start_times = zeros(1,length(obj.start_markers));
            end_times = start_times;
            
            for k = 1:length(obj.start_markers)
                cur_start = obj.start_markers{k};
                start_times(k) = cur_start.marker_handle.XData;
                
                cur_end = obj.end_markers{k};
                end_times(k) = cur_end.marker_handle.XData;
            end
            
            obj.start_marker_times = start_times;
            obj.end_marker_times = end_times;
            
            obj.vv = obj.void_finder2.void_data.getVV(start_times,end_times);
            obj.vt = obj.void_finder2.void_data.getVoidingTime(start_times,end_times);
            obj.refreshTimesList();
        end
        function syncViewLines(obj,~,~)
            %
            %   obj.syncViewLines(src, ev)
            %   
            %   **This is used both as a callback function and is regularly
            %   used by other functions!!!
            %
            %   When the zoom is changed on the top plot, the lines on the
            %   bottom plot adjust to show where in the data you are
            %   looking closely
            
            a = obj.h.top_axes;
            xleft = a.XLim(1);
            xright = a.XLim(2);
            
            b = obj.h.bottom_axes;
            axes(b);
            
            hold on;
            
            %   if after some sort of reset we lose the lines, need to
            %   bring them back
            if isempty(obj.zoom_lines.left) || ~obj.zoom_lines.left.isvalid
            axes(b) 
            axis auto
            ylow = b.YLim(1);
            yhigh = b.YLim(2);
            obj.zoom_lines.left = plot([xleft, xleft], [ylow, yhigh], 'r-', 'markersize', 50, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickLine});
            obj.zoom_lines.right = plot([xright, xright], [ylow, yhigh],'r-', 'markersize', 50,'hittest', 'on', 'buttondownfcn', {@obj.cb_clickLine});           
            axes(a)
            end
            
            set(obj.zoom_lines.left, 'xdata',[xleft, xleft]);
            set(obj.zoom_lines.right, 'xdata', [xright, xright]);
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

            index = obj.cur_marker_idx + increment;
            obj.jumpToMarker(index);
            set(obj.h.times_listbox,'Value',obj.cur_marker_idx);
            %   TODO: rollover
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
        function jumpToMarker(obj, index)
            %
            %    obj.jumpToMarker(index)
            %
            %    Switches the view to that of the marker indicated by index
            %    Inputs:
            %    -------
            %    - index
            if index < 1
                return
            elseif index > length(obj.start_markers)
                return
            end
            obj.cur_marker_idx = index;
            a = obj.h.top_axes;
            
            cur_start = obj.start_markers{obj.cur_marker_idx};
            cur_end = obj.end_markers{obj.cur_marker_idx};
            
            cur_start_time = cur_start.marker_handle.XData;
            cur_end_time = cur_end.marker_handle.XData;
            
            data_in_range = obj.void_finder2.data.getDataFromTimeRange('raw',[cur_start_time, cur_end_time]);
            miny = min(data_in_range);
            maxy = max(data_in_range);
            
            axes(a);
            axis([cur_start_time - 5, cur_end_time + 5, miny - 1, maxy + 1])
            obj.syncViewLines();
            obj.updateMarkerDetails();
        end
        function updateMarkerDetails(obj)
            %
            %   obj.updateMarkerDetails()
            %
            %   updates the list of details including start time, end time,
            %   voided volume, and voiding time
            %
            %   TODO: include level of certainty!
            
            % TODO: don't run this calculation if nothing has changed
            %   --only takes about 0.02 seconds, so not a big deal though
            % tic
            obj.processMarkerData;
            % toc
            data = cell(4,1);
            a = obj.start_markers{obj.cur_marker_idx}.marker_handle.XData;
            b = obj.end_markers{obj.cur_marker_idx}.marker_handle.XData;
            c = obj.vv(obj.cur_marker_idx);
            d = obj.vt(obj.cur_marker_idx);
            
            data{1} = ['Start Time: ', num2str(a)];
            data{2} = ['End Time: ', num2str(b)];
            data{3} = ['Void Volume: ', num2str(c)];
            data{4} = ['Void Time: ', num2str(d)];
            
            set(obj.h.details_listbox, 'String', data)
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
            obj.syncViewLines();
        end
        function saveCurrentData(obj)
            %
            %   obj.saveCurrentData(obj)
            %
            %   Saves the start/end times, voided volume, and voiding time
            %   found for the given stream to the directory which the user
            %   specifies (TODO: save default!!)
            
            obj.processMarkerData();
            message = 'Please type where you would like files to be saved';
            save_loc = plotters.areYouSure(message,1);
            current_loc = cd(save_loc);
            
            name = obj.expt_name_list{obj.selected_expt_idx};
            file_path = obj.expt_path_list{obj.selected_expt_idx};
            
            start_times = obj.start_marker_times;
            end_times = obj.end_marker_times;
            vv = obj.vv;
            vt = obj.vt;
            
            [~, name, ~] = fileparts(file_path);
            file_name = sprintf('%s_%s',name,'reviewed');
            save(file_name,'start_times', 'end_times', 'vv', 'vt');
            disp('file saved to:');
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
            %   marker. End markers do not carry comments
            
            cur_marker = obj.start_markers{obj.cur_marker_idx};
            cur_marker.comment = comment;
        end
        function refreshTimesList(obj)
            %
            %   obj.refreshTimesList()
            %
            %   updates the list of times to view (upper right of GUi)
            data = obj.start_marker_times;
            times_list = obj.h.times_listbox;
            set(times_list, 'string', data);
        end
        function initEventTypes(obj)
            %
            %   obj.initEventTypes()
            %
            %   Updates the list of event types to look at. Will later 
            %   allow for selection of time windows to look at where voids
            %   may have been missed

            list = {'Calibration' ; 'Spikes' ; 'Evaporations' ; 'Glitches'; 'Bad Resets' ; 'Unpaired'};
            set(obj.h.event_selection_listbox, 'String', list);
        end
    end
    methods % callback functions
        function cb_nextPressed(obj, ~,~)
            obj.scrollRight();
        end
        function cb_prevPressed(obj,~,~)
            obj.scrollLeft();
        end
        function cb_browseClicked(obj,~,~)
            obj.browseExpts();
        end
        function cb_nextStream(obj,~,~)
            temp = plotters.areYouSure('Are you sure you would like to go to the next stream?',0);
            if isempty(temp)
                return
            end
            switch temp
                case 1
                    disp('saving files');
                otherwise
                    return
            end
            obj.saveCurrentData();
            obj.nextStream();
        end
        function cb_nextExpt(obj, ~, ~)
            message = 'Are you sure you want to move on to the next experiment?';
            choice = plotters.areYouSure(message,0);
            switch choice
                case 1
                    disp('saving files');
                otherwise
                    return
            end
            obj.saveCurrentData();
        end
        function cb_resetView(obj,~,~)
            obj.resetView();
        end
        function cb_saveAndClose(obj,~,~)
            message = 'Are you sure you want to save and close?';
            choice = plotters.areYouSure(message,0);
            switch choice
                case 1
                    disp('saving files');
                otherwise
                    return
            end
            obj.saveCurrentData();
            close obj.fig_handle
        end
        function cb_chooseStream(obj,src,~)
            temp = src.String;
            index = str2double(temp);
            message = sprintf('Are you sure you want to jump to Stream %u ?',index);
            choice = plotters.areYouSure(message,0);
            switch  choice
                case 1
                    obj.jumpToStream(index);
                case 0
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
            index = src.Value;
            obj.jumpToMarker(index);
        end
        function cb_eventTypeChanged(obj,src,ev)
            
        end
    end
    methods % callbacks for click and drag
        function cb_addVoid(obj,~,ev)
            if ev.Button == 2
                a = obj.h.top_axes;
                x1 = ev.IntersectionPoint(1) - 1;
                y1 = obj.void_finder2.data.getDataFromTimePoints('raw',x1);
                temp1 = line(a,x1,y1, 'color', 'black', 'marker', 'o', 'markersize', 10, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickmarker});
                obj.start_markers{end+1} = plotters.void_marker(length(obj.start_markers) + 1,'start',temp1);
                
                x2 = ev.IntersectionPoint(1) + 1;
                y2 = obj.void_finder2.data.getDataFromTimePoints('raw', x2);
                temp2 = line(a,x2,y2, 'color', 'black', 'marker', 's', 'markersize', 10, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickmarker});
                obj.end_markers{end+1} = plotters.void_marker(length(obj.end_markers)+1,'end', temp2);
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
            if x < 0 || x> end_time
                return
            end
            
            if src == obj.zoom_lines.left
                if src.XData >= obj.zoom_lines.right.XData - 2
                    src.XData = src.XData - 2;
                    obj.cb_stopDraggingLine(fig,ev);
                    return
                end
            else %it is the right line
                if src.XData <= obj.zoom_lines.left.XData + 2
                    src.XData = src.XData + 2;
                    obj.cb_stopDraggingLine(fig,ev);
                    return
                end
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
            temp = axis(a);
            axes(a);
            
            end_time = obj.void_finder2.data.cur_stream_data.time.end_time;
            left = obj.zoom_lines.left.XData(1);
            right =  obj.zoom_lines.right.XData(1);
            if right <= end_time           
            data_in_range = obj.void_finder2.data.getDataFromTimeRange('raw', [left, right]);
            miny = min(data_in_range);
            maxy = max(data_in_range);
            axis([left,right, miny, maxy]);   
            end
        end
        function cb_clickmarker(obj,src,ev)
            %
            %   Inputs:
            %   -------
            %   src: the Line object which was clicked
            %   ev: the Hit object with details about the click
            
            if ev.Button == 1
                set(ancestor(src,'figure'),'windowbuttonmotionfcn',{@obj.cb_dragmarker,src})
                set(ancestor(src,'figure'),'windowbuttonupfcn',{@obj.cb_stopdragging})
            elseif ev.Button == 3
                % TODO: there must be a better way to do this?!
                for k = 1:length(obj.start_markers)
                    cur_start = obj.start_markers{k};
                    cur_end = obj.end_markers{k};
                    
                    if src == cur_start.marker_handle || src == cur_end.marker_handle
                        % have to delete the handle to remove the line,
                        % then delete the cell.
                        %
                        % TODO: have a delete method for the marker
                        % object
                        delete(cur_start.marker_handle);
                        obj.start_markers(k) = [];
                        delete(cur_end.marker_handle);
                        obj.end_markers(k) = [];
                        
                        % this will move you one ahead from where you were
                        obj.jumpToMarker(k);
                        return
                    end
                end
            end
        end
        function cb_dragmarker(obj,fig,ev,src)
            coords=get(gca,'currentpoint');
            x=coords(1,1,1);
            end_time = obj.void_finder2.data.cur_stream_data.time.end_time;
            
            if x < 0 || x> end_time
                return
            end
            y = obj.void_finder2.data.getDataFromTimePoints('raw',x);
            %y=coords(1,2,1);
            % disp(x)
            % disp(y)
            set(src,'xdata',x,'ydata',y);
        end
        function cb_stopdragging(obj,fig,ev)
            set(fig,'windowbuttonmotionfcn','')
            set(fig,'windowbuttonupfcn','')
        end
    end
end

