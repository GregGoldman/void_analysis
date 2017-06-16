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
%}
    properties
        h
        fig_handle
        
        void_finder2
        
    end
    
    methods
        function obj = analysis_GUI()
            gui_path = fullfile('C:\Repos\void_analysis\+plotters\@analysis_GUI\analysis_GUI.fig');
            obj.fig_handle = openfig(gui_path);
            obj.h = guihandles(obj.fig_handle);
            setappdata(obj.fig_handle,'obj',obj);
            
            
            obj.void_finder2 = analysis.void_finder2;
             
            obj.void_finder2.data.loadExpt(2);
            obj.void_finder2.data.getStream(2,1);
            obj.void_finder2.findPossibleVoids();
            a = obj.h.top_axes;
            obj.void_finder2.data.plotData('raw',a);
            
            
        end
        function drag(obj)
            a = obj.h.top_axes;
            set(a,'xlimmode','manual','ylimmode','manual')
            line(a,0.5,0.5,'marker','s','markersize',10,'hittest','on','buttondownfcn',@clickmarker)
        end
            
    end  
end
function clickmarker(src,ev)
set(ancestor(src,'figure'),'windowbuttonmotionfcn',{@dragmarker,src})
set(ancestor(src,'figure'),'windowbuttonupfcn',@stopdragging)
end
function dragmarker(fig,ev,src)
coords=get(gca,'currentpoint');
x=coords(1,1,1);
y=coords(1,2,1);
disp(x)
disp(y)
set(src,'xdata',x,'ydata',y);
end
function stopdragging(fig,ev)
set(fig,'windowbuttonmotionfcn','')
set(fig,'windowbuttonupfcn','')
end
