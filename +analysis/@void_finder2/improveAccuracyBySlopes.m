function improveAccuracyBySlopes(obj)
%
%   analysis.void_finder2.improveAccuracyBySlopes
%
%   A differeny method for finding the start and end points.
%   Finds a region of uniform slope as a baseline (evaporation period)
%   Then from each void, goes outward until the slope has approached normal
%   levels once again
%
%   Examples:
%   --------
%   obj.improveAccuracyBySlopes();

start_times = obj.void_data.updated_start_times;
end_times = obj.void_data.updated_end_times;

reset_start_times = obj.void_data.reset_start_times;
reset_end_times = obj.void_data.reset_end_times;

if length(start_times) ~= length(end_times)
    error('dimensions of starts/ends mismatched')
elseif length(reset_start_times) ~= length(reset_end_times)
    error('dimensions of reset points mismatched')
end


x_start_intersect = zeros(1,length(start_times));
x_end_intersect = zeros(1,length(end_times));

% go out a range from each of the points, take the slope, then
% incrementally move away from the center time to get a slope that returns
% to normal. If there is another void within a too-close time range, leave
% it alone and mark it for review.

% also attempt to remove the voids which are too steep to accurately
% measure: most of these occur within 

proximity_issue_starts = [];
proximity_issue_ends = [];

time_window = 1;
time_increment = 0.1;
slope_thresh = 0.015;
base_skip_time = 5;
for k = 1:length(start_times)
    mid_time = round((end_times(k) + start_times(k))/2);
    
    if (k ~= 1) %is the start too close to a previosu end point?
        left_ok = ((start_times(k) - end_times(k-1) > base_skip_time));
    else
        left_ok = 1;
    end
    if (k ~= length(start_times)) %is the end too close to an upcoming start point?
        right_ok = (start_times(k+1) - (end_times(k)) > base_skip_time);
    else
        right_ok = 1;
    end

    % ---------------processing for the start times------------------
    % TODO: could make this subsection a function, then would only have to
    % call a function twice instead of slightly different code 
    if left_ok
    right_edge_time = mid_time + 0.5; %go too far over in case the markers don't line up w the middle
    left_edge_time = mid_time - time_window;
    b1 = h__coefs(obj,left_edge_time,right_edge_time);
    
    base_right_edge = mid_time - base_skip_time;
    base_left_edge = base_right_edge - time_window;
    b_base = h__coefs(obj, base_left_edge, base_right_edge);
    
    while abs(b1(2) - b_base(2)) > slope_thresh
        right_edge_time = right_edge_time - time_increment;
        left_edge_time = right_edge_time - time_window;
        b1 = h__coefs(obj,left_edge_time,right_edge_time);
    end
    x_start_intersect(k) = right_edge_time;
    else
       x_start_intersect(k) = start_times (k);
       proximity_issue_starts(end+1) = start_times(k);
    end
    reset_start_flag = ismember(reset_start_times, start_times(k));
    if any(reset_start_flag)
        reset_start_times(reset_start_flag) = x_start_intersect(k);
    end   
    
    % ---------------processing for the end times------------------
    if right_ok
        left_edge_time = mid_time - 0.5;
        right_edge_time = mid_time + time_window;
        b1 = h__coefs(obj,left_edge_time,right_edge_time);
        
        base_left_edge = mid_time + base_skip_time;
        base_right_edge = base_left_edge + time_window;
        b_base = h__coefs(obj, base_left_edge, base_right_edge);
        
        while abs(b1(2) - b_base(2)) > slope_thresh
            left_edge_time = left_edge_time + time_increment;
            right_edge_time = left_edge_time + time_window;
            b1 = h__coefs(obj,left_edge_time,right_edge_time);
        end
        x_end_intersect(k) = left_edge_time;
    else
        x_end_intersect(k) = end_times(k);
        proximity_issue_ends(end+1) = end_times(k);
    end
    reset_end_flag = ismember(reset_end_times, end_times(k));
    if any(reset_end_flag)
        reset_end_times(reset_end_flag) = x_end_intersect(k);
    end   
end

obj.void_data.reset_start_times = reset_start_times;
obj.void_data.reset_end_times = reset_end_times;

obj.void_data.proximity_issue_ends = proximity_issue_ends;
obj.void_data.proximity_issue_starts = proximity_issue_starts;

obj.void_data.updated_start_times = x_start_intersect;
obj.void_data.updated_end_times = x_end_intersect;
%{
hold on
start_vals = obj.data.getDataFromTimePoints('raw',x_start_intersect);
end_vals = obj.data.getDataFromTimePoints('raw',x_end_intersect);
plot(x_start_intersect,start_vals,'kd', 'MarkerSize', 10);
plot(x_end_intersect,end_vals,'kp', 'MarkerSize', 10);
%}
end
function b  = h__coefs(obj,left_edge, right_edge)
[vals, times]= obj.data.getDataFromTimeRange('raw', [left_edge, right_edge]);
b = glmfit(times, vals);
end