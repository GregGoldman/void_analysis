function showScale(~, ax, varargin)
%
%   showAxesScale(ax)
%
%   Changes axes ticks to show the absolute time at the left edge, then
%   just the data scale on the x axis
%   For example, in a long time series, the base edge edge might show 1000
%   seconds, then ticks could be 2, 4, 6, 8 ... from that edge
%
%   Inputs
%   -----
%   ax: handle to the axes to modify
%   axes_selection*: scalar (optional)
%       choose to apply the function to the x axis (1), y axis (2), or both
%       (3) (default)

axes_selection = 3; %default both axes
if nargin > 2
    axes_selection = varargin{1};
end

set(zoom(ax), 'ActionPostCallback', @(x,y)cb_adjust(ax,axes_selection))
set(pan(ax.Parent),'ActionPostCallback',   @(x,y)cb_adjust(ax,axes_selection))
h__showScale(ax,axes_selection)

end
function h__showScale(ax,axes_selection)
num_ticks = 6;
num_increments =  num_ticks - 1;

if axes_selection == 1 || axes_selection ==3
    xleft = ax.XLim(1);
    xright = ax.XLim(2);
    
    num_seconds = xright - xleft;
    increment = num_seconds / num_increments;
    
    temp = 1:num_increments;
    
    xtick = [xleft, xleft + temp * increment];
    
    xtick_labels = zeros(1, num_ticks);
    xtick_labels(1) = xleft;
    xtick_labels(2:end) = temp * increment;
    xtick_labels = round(xtick_labels,2);
    ax.XTickMode = 'manual';
    
    ax.XTick = xtick;
    ax.XTickLabel = xtick_labels;
end

if axes_selection == 2 || axes_selection == 3;
    ylow = ax.YLim(1);
    yhigh = ax.YLim(2);
    
    mag = yhigh - ylow;
    increment = mag / num_increments;
    
    temp = 1:num_increments;
    ytick = [ylow, ylow + temp * increment];
    ytick_labels = zeros(1, num_ticks);
    ytick_labels(1) = ylow;
    ytick_labels(2:end) = temp*increment;
    ytick_labels = round(ytick_labels,2);
    ax.XTickMode = 'manual';
    
    ax.YTick = ytick;
    ax.YTickLabel = ytick_labels;
end
end
function cb_adjust(ax,axes_selection,varargin)
h__showScale(ax,axes_selection);
end