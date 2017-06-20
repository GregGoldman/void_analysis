function output =  areYouSure(message, input_flag)
%
%   plotters.areYouSure(message)
%
%   Creates a temporary window with yes/no option
%   Allows for accepting input from the user
%
%   Inputs:
%   --------
%   - message: the message for the box to display
%   - input_flag: 1 if you desire an input
%                 0 if you do not
h.received = 0;
h.fig = figure('position',[400 400 300 200]);
set(h.fig,'toolbar','none');
set(h.fig,'menubar', 'none');
set(h.fig,'resize','off');

h.yes_button = uicontrol('style', 'pushbutton', 'position', [10,10, 135, 40], 'string', 'Accept');
h.no_button = uicontrol('style', 'pushbutton', 'position', [155,10,135,40], 'String', 'Cancel');
h.text = uicontrol('style', 'text', 'position', [10,90,280,100],'String', message);
set(h.text,'FontSize',12);

if input_flag
    h.edit = uicontrol('style', 'edit', 'position', [10,60,280,20]);
    set(h.edit,'callback',{@cb_input});
end

set(h.yes_button, 'callback', {@cb_yes});
set(h.no_button, 'callback', {@cb_no});
waitfor(h.fig);
output = h.received;

% nested functions are the easiest way to make this work
    function cb_yes(src,ev)
    h.received = 1;
    close(h.fig);
    end
    function cb_no(src,ev)
    h.received = 0;
    close(h.fig);
    end
    function cb_input(src,ev)
    h.received = src.String;
    close(h.fig);
    end
end
