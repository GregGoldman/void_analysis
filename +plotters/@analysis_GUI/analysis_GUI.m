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
    
    TODO:
    --------
    add a place to update info about the processing: minimum volume
                                                     maximum slope
                                                     ??
    adjust position of axes so info isn't overlapping
    design expt browser
    have option to plug in a stream number to load
    
    figure out how saving should work
    
    
    %}
    properties
        h
        fig_handle
        
        void_finder2
        
        top_plot_handle
        
    end
    
    methods
        function obj = analysis_GUI()
            gui_path = fullfile('C:\Repos\void_analysis\+plotters\@analysis_GUI\analysis_GUI.fig');
            obj.fig_handle = openfig(gui_path);
            obj.h = guihandles(obj.fig_handle);
            setappdata(obj.fig_handle,'obj',obj);
            %{
            set(obj.h.expt_id_text, 'callback',
            set(obj.h.stream_num_text, 'callback',
            set(obj.h.top_axes, 'callback',
            set(obj.h.bottom_axes, 'callback',
            set(obj.h.next_button, 'callback',
            set(obj.h.prev_button, 'callback',
            set(obj.h.not_a_void, 'callback',
            set(obj.h.add_void_buton, 'callback',
            set(obj.h.comment_text, 'callback',
            set(obj.h.comment_text, 'callback',
            set(obj.h.details_listbox, 'callback',
            set(obj.h.marker_table, 'callback',
            set(obj.h.next_stream_button, 'callback',
            set(obj.h.browse_button, 'callback',

            %}
            
            %{
            obj.void_finder2 = analysis.void_finder2;
            obj.void_finder2.data.loadExpt(2);
            obj.void_finder2.data.getStream(2,1);
            % obj.void_finder2.findPossibleVoids();
            a = obj.h.top_axes;
            axes(a);
            set(a, 'NextPlot', 'replacechildren');
            obj.void_finder2.data.plotData('raw',a);
            set(gcf,'toolbar','none');
            %}
        end
        function drag(obj)
            a = obj.h.top_axes;
            set(a,'xlimmode','manual','ylimmode','manual')
            line(a,0.5,0.5,'marker','s','markersize',10,'hittest','on','buttondownfcn',@clickmarker)
            %{
                        hittest help:
            Ability to become current object, specified as 'on' or 'off':
            Setting the value to 'on' allows the figure to become the current object when the user clicks on it. A value of 'on' also allows the figure CurrentObject property and the gco function to report the figure as the current object.
            Setting the value to 'off' sets the figure CurrentObject property to an empty GraphicsPlaceholder array when the user clicks on the figure.
            %}
            function clickmarker(src,ev)
                %
                %
                %   Inputs:
                %   -------
                %   src: the Line object which was clicked
                %   ev: the Hit object with details about the click
                set(ancestor(src,'figure'),'windowbuttonmotionfcn',{@dragmarker,src})
                set(ancestor(src,'figure'),'windowbuttonupfcn',@stopdragging)
            end
            function dragmarker(fig,ev,src)
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
            function stopdragging(fig,ev)
                set(fig,'windowbuttonmotionfcn','')
                set(fig,'windowbuttonupfcn','')
            end
        end
    end
    methods % callback functions
        function cb_nextPressed(obj)
            
        end
        function cb_prevPressed(obj)
        
        end
        function cb_nonVoid(obj)
            
        end
        function cb_addVoid(obj)
            
        end
        function browseExpts(obj)
            
        end
        function nextStream(obj)
            
        end
        function nextExpt(obj)
            
        end
        function markerTableClicked(obj)
            
        end
    end
end

