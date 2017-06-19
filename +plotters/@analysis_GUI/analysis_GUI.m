classdef analysis_GUI < handle
    %
    %   class:
    %   plotters.analysis_GUI
    %
    %   Controls the GUI
    
    %{
    GUI Tags:
    ---------
    expt_id_text
    stream_num_text
    top_axes
    bottom_axes
    next_button
    prev_button
    not_a_void
    add_void_buton
    comment_text
    details_listbox
    marker_table
    next_stream_button
    browse_button
    next_expt_button
    file_path_edit_text
    
    TODO:
    --------
    add a place to update info about the processing: minimum volume
                                                     maximum slope
                                                     ??
    adjust position of axes so info isn't overlapping
    design expt browser
    have option to plug in a stream number to load
    
    figure out how saving should work
    
    Automatically load the default location to look for expt files
    
    Speed up the processing of expts
    
    remove the 'Not A Void' button. This functionality will be replaced
    with a right click (much easier)
    
    
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
            set(obj.h.top_axes,'ButtonDownFcn',{@obj.updatePlots});
            set(obj.h.next_button, 'callback',{@obj.cb_nextPressed});
            set(obj.h.prev_button, 'callback',{@obj.cb_prevPressed});
            set(obj.h.next_stream_button, 'callback',{@obj.cb_nextStream});
            set(obj.h.next_expt_button, 'callback', {@obj.cb_nextExpt});
            %{
            set(obj.h.expt_id_text, 'callback',
            set(obj.h.stream_num_text, 'callback',
            set(obj.h.top_axes, 'callback',
            set(obj.h.bottom_axes, 'callback',
            set(obj.h.prev_button, 'callback',
            set(obj.h.not_a_void, 'callback',
            set(obj.h.add_void_buton, 'callback',
            set(obj.h.comment_text, 'callback',
            set(obj.h.comment_text, 'callback',
            set(obj.h.details_listbox, 'callback',
            set(obj.h.marker_table, 'callback',
            %}
        end
        function initExptAndStream(obj)
            obj.cur_stream_number = 1;
            obj.selected_expt_path = obj.expt_path_list{obj.selected_expt_idx};
            set(obj.h.expt_id_text, 'String', obj.selected_expt_path);
            obj.void_finder2.data.loadExpt(obj.selected_expt_path);
            obj.h__streamUpdated();
        end
        function nextStream(obj)
            % TODO: save what we got from the most recent markings
            
            obj.cur_stream_number = obj.cur_stream_number + 1;
            obj.h__streamUpdated();
        end
        function h__streamUpdated(obj)
            obj.void_finder2.data.getStream(obj.cur_stream_number);
            set(obj.h.stream_num_text, 'String', obj.cur_stream_number);
            a = obj.h.top_axes;
            axes(a);
            set(a,'NextPlot', 'replacechildren');
            hold off
            obj.void_finder2.data.plotData('raw',a);
            
            b = obj.h.bottom_axes;
            axes(b);
            hold off
            set(b,'NextPlot', 'replacechildren');
            obj.void_finder2.data.plotData('raw',b);
            obj.processStream();
            
            hold on
            obj.cur_marker_idx = 0;
            obj.updateTable();
        end
        function processStream(obj)
            %
            %   obj.processStream()
            %
            %   Finds the possible voids in the data and updates the lists
            %   on the GUI
            
            obj.void_finder2.findPossibleVoids();
            obj.plotMarkers();
        end
        function plotMarkers(obj)
            a = obj.h.top_axes;
            obj.start_marker_times = obj.void_finder2.void_data.updated_start_times;
            obj.end_marker_times = obj.void_finder2.void_data.updated_end_times;
            
            obj.start_markers  = cell(1,length(obj.start_marker_times));
            obj.end_markers = cell(1,length(obj.end_marker_times));
            hold on
            for k = 1:length(obj.start_marker_times)
                xval = obj.start_marker_times(k);
                yval = obj.void_finder2.data.getDataFromTimePoints('raw', xval);
                temp = line(a,xval,yval, 'color', 'black', 'marker', '*', 'markersize', 12, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickmarker});
                obj.start_markers{k} = plotters.void_marker(obj.cur_marker_idx, 'start', temp);
            end
            for k = 1:length(obj.end_marker_times)
                xval = obj.end_marker_times(k);
                yval = obj.void_finder2.data.getDataFromTimePoints('raw', xval);
                temp = line(a,xval,yval, 'color', 'black','marker', '+', 'markersize', 12, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickmarker});
                obj.end_markers{k} = plotters.void_marker(obj.cur_marker_idx, 'end', temp);
            end
        end      
        function browseExpts(obj)
            % 1) get the value of the filepath entered into the edit text
            %       TODO: create this edit text area first!!
            % 2) search in that area to find the list of useable files
            % 3) pull up the browser (below) and update the current expt
            
            %   TODO: move this to callback for the edit text box
            file_path = get(obj.h.file_path_edit_text, 'String');
            obj.void_finder2.data.findExptFiles(file_path);
            list_result = obj.void_finder2.data.expt_file_list_result;
            obj.expt_name_list = list_result.file_names;
            obj.expt_path_list = list_result.file_paths;
            
            plotters.expt_browser(obj);
        end
        function updateTable(obj)
            t = obj.h.marker_table;
            
            obj.processMarkerData();
            
            start_times = obj.start_marker_times;
            end_times = obj.end_marker_times;
            
            vt = obj.vt;
            vv = obj.vv;
            
            t = table(vv',vt');
            % TODO: allow various sorting
            tt = table2cell(t);
            set(obj.h.marker_table,'Data',tt);
            col_names = {'Volume', 'Duration'};
            set(obj.h.marker_table, 'ColumnName', col_names);
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
        end
        function updatePlots(obj,~,~)
            % goals of this function:
            %{
            when the zoom is changed on the top plot, the lines on the
            bottom plot adjust to show where in the data you are looking
            
            %}
            if ~isempty(obj.zoom_lines.left)
                delete(obj.zoom_lines.left);
            end
            if ~isempty(obj.zoom_lines.right)
                delete(obj.zoom_lines.right);
            end
            
            a = obj.h.top_axes;
            xleft = a.XLim(1);
            xright = a.XLim(2);
            
            b = obj.h.bottom_axes;
            ylow = b.YLim(1);
            yhigh = b.YLim(2);
            axes(b);
            hold on;
            
            obj.zoom_lines.left = plot([xleft, xleft], [ylow, yhigh], 'r-', 'markersize', 20);
            obj.zoom_lines.right = plot([xright, xright], [ylow, yhigh],'r-', 'markersize', 20);
        end
        function h__scroll(obj, increment)
            obj.cur_marker_idx = obj.cur_marker_idx + increment;
            
            %   TODO: rollover
            if obj.cur_marker_idx < 1
                obj.cur_marker_idx = 1;
                return
            elseif obj.cur_marker_idx > length(obj.start_markers);
                obj.cur_marker_idx = length(obj.start_markers);
                return
            end
            a = obj.h.top_axes;
            
            cur_start = obj.start_markers{obj.cur_marker_idx};
            cur_end = obj.end_markers{obj.cur_marker_idx};
            
            cur_start_time = cur_start.marker_handle.XData;
            cur_end_time = cur_end.marker_handle.XData;
            
            start_val = cur_start.marker_handle.YData;
            end_val = cur_end.marker_handle.YData;
            
            miny = min(start_val,end_val);
            maxy = max(start_val,end_val);
            
            axes(a);
            
            axis([cur_start_time - 15, cur_end_time + 15, miny - 1, maxy + 1])
            
            obj.updatePlots();
        end
        function scrollRight(obj)
            obj.h__scroll(1);
        end
        function scrollLeft(obj)
            obj.h__scroll(-1);
        end
        function resetView(obj)
            axes(obj.h.top_axes);
            axis auto;
        end
        function saveCurrentData(obj)
            %
            %   obj.saveCurrentData(obj)
            %
            %   Saves the start/end times, voided volume, and voiding time
            %   found for the given stream to the directory which the user
            %   specifies (TODO: save default!!)
            %
            obj.processMarkerData();
            save_loc = input('Please type where you would like files to be saved\n');
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
        function addVoid(obj)
            %
            %   obj.addVoid()
            %
            %   finds the middle of the current window and adds a new start
            %   and end marker
            %
            a = obj.h.top_axes;
            axes(a);
            cax = axis(a);
            
            mid = round((cax(1) + cax(2))/2);
            start_time = mid - 5;
            stop_time = mid + 5;

            xval = start_time;
            yval = obj.void_finder2.data.getDataFromTimePoints('raw', xval);
            obj.start_markers{end+1} = line(a,xval,yval, 'color', 'red', 'marker', '*', 'markersize', 12, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickmarker});
            
            xval = stop_time;
            yval = obj.void_finder2.data.getDataFromTimePoints('raw', xval);
            obj.end_markers{end+1} = line(a,xval,yval, 'color', 'red', 'marker', '+', 'markersize', 12, 'hittest', 'on', 'buttondownfcn', {@obj.cb_clickmarker});
        end
    end
    methods % callback functions
        function cb_nextPressed(obj, ~,~)
            obj.scrollRight();
        end
        function cb_prevPressed(obj,~,~)
            obj.scrollLeft();
        end
        function cb_nonVoid(obj)
            
        end
        function cb_addVoid(obj)
            
        end
        function cb_browseClicked(obj,~,~)
            obj.browseExpts();
        end
        function cb_nextStream(obj,~,~)
            temp = input('are you sure? (1 or 0)\n');
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
            temp = input('are you sure? (1 or 0)\n');
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
        end
        function markerTableClicked(obj)
            
        end
    end
    methods % callbacks for click and drag
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

