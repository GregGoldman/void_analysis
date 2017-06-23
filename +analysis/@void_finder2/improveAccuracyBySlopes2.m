function improveAccuracyByStd(obj)
%
%   analysis.void_finder2.improveAccuracyByStd
%
%   A differeny method for finding the start and end points.
%   finds deviation from nearby mean values

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

filter = sci.time_series.filter.smoothing(0.1,'type','rect');
temp = obj.data.cur_stream_data.filter(filter);
            

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
    data = temp.d;


for k = 1:length(start_times)
    start_time = start_times(k);
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
    base_right_edge = mid_time - base_skip_time;
    base_left_edge = base_right_edge - time_window;
    
    idx_edges = temp.time.getNearestIndices([base_left_edge, base_right_edge]);
    idxs_in_range = idx_edges(1): idx_edges(2);
    data_in_range = data(idxs_in_range);
    
    m = mean(data_in_range);
    s = std(data_in_range);
    
    cur_times = base_right_edge + (1:2)*time_increment;
    cur_idxs = temp.time.getNearestIndices(cur_times);
    cur_vals = data(cur_idxs);
    while any(cur_vals - m < 3*s)
        base_right_edge = base_right_edge + time_increment;
        cur_times = base_right_edge + (1:2)*time_increment;
        cur_idxs = temp.time.getNearestIndices(cur_times);
        cur_vals = data(cur_idxs);
    end
    x_start_intersect(k) = cur_times(1);

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
        base_left_edge = mid_time + base_skip_time;
        base_right_edge = base_left_edge + time_window;
        
        idx_edges = temp.time.getNearestIndices([base_left_edge, base_right_edge]);
        idxs_in_range = idx_edges(1): idx_edges(2);
        data_in_range = data(idxs_in_range);
        
        m = mean(data_in_range);
        s = std(data_in_range);
        
        cur_times = base_left_edge - (1:2)*time_increment;
        cur_idxs = temp.time.getNearestIndices(sort(cur_times));
        cur_vals = data(cur_idxs);
        
        while any(abs(m - cur_vals) < 3*s)
            base_left_edge = base_left_edge - time_increment;
            cur_times = base_left_edge - (1:2)*time_increment;
            cur_idxs = temp.time.getNearestIndices(sort(cur_times));
            cur_vals = data(cur_idxs);
        end
        x_end_intersect(k) = cur_times(1);
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
end