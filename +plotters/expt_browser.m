function expt_browser(analysis_GUI)
%
%   plotters.expt_browser(analysis_GUI)
%
%   Creates a temporary figure which allows for the selection of experiment
%   files given that a string has been put into the edit_text for the
%   experiment browser
%
%   Inputs:
%   ----------
%   - analysis_GUI: the GUI object which called this function
%

h.fig = figure('position',[100 100 500 500]);
set(h.fig,'Resize', 'off');
h.list_box = uicontrol('style', 'listbox', 'position', [10 60 480 430], 'string' , 'expt display area');
h.ok_button = uicontrol('style', 'pushbutton', 'position', [400,10, 100, 40], 'string', 'Select Expt');

set(h.list_box, 'String', analysis_GUI.expt_name_list);
set(h.list_box, 'callback',{@cb_boxClicked, analysis_GUI});
% cell array with callback, then the inputs
set(h.ok_button, 'callback',{@cb_okClicked, analysis_GUI, h})

end
function cb_boxClicked(hObject, eventdata, analysis_GUI)
%hobject and eventdata come automatically. h is my own special input
% update the current selection of the figure

selected_idx = get(hObject, 'Value');
analysis_GUI.selected_expt_idx = selected_idx;
end
function cb_okClicked(hObject, eventdata,analysis_GUI,h)
close(h.fig);
analysis_GUI.initExptAndStream();
%delete(h.fig);
end
