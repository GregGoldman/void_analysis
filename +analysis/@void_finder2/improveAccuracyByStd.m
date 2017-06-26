function improveAccuracyByStd(obj)
%
%   analysis.void_finder2.improveAccuracyByStd
%
%   A differeny method for finding the start and end points.
%   finds deviation from nearby mean values


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


proximity_issue_starts = [];
proximity_issue_ends = [];

time_window = 1;
time_increment = 0.05;
base_skip_time = 5;

filter = sci.time_series.filter.smoothing(0.1,'type','rect');
temp = obj.data.cur_stream_data.subset.fromStartAndStopTimes(start_times - base_skip_time - 2*time_window  , end_times + base_skip_time + 2*time_window , 'un', 0);
temp2 = temp{1};
filtered_data = temp2.filter(filter);

obj.data.rect_filtered_data = filtered_data;

points_to_collect = (1:10);


solid_starts = [];
solid_ends = [];

for k = 1:length(start_times)
    data = filtered_data(k);
    raw_data = data.d;
    
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
        base_right_edge = start_times(k) - base_skip_time + time_window;
        base_left_edge = base_right_edge - time_window;
        
        idx_edges = data.time.getNearestIndices([base_left_edge, base_right_edge]);
        idxs_in_range = idx_edges(1): idx_edges(2);
        data_in_range = raw_data(idxs_in_range);
        
        
        m = mean(data_in_range);
        s = std(data_in_range);
        
        
        right_edge = base_right_edge;
        cur_times = right_edge + points_to_collect*time_increment;
        cur_idxs = data.time.getNearestIndices(cur_times);
        cur_vals = raw_data(cur_idxs);
        while any(cur_vals(:) - m < points_to_collect(:)*s) || any(cur_vals - m < 0)
            % cur_vals are outside noise and all cur_vals are positive is end
            % condition
            right_edge = right_edge + time_increment;
            
            cur_times = right_edge + points_to_collect*time_increment;
            if any(cur_times >= end_times(k))
                x_start_intersect(k) = start_times(k);
                break
            end
            cur_idxs = data.time.getNearestIndices(cur_times);
            cur_vals = raw_data(cur_idxs);
        end
        if x_start_intersect(k) ==0
            x_start_intersect(k) = cur_times(1);
        end
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
        base_left_edge = end_times(k) + base_skip_time - time_window;
        base_right_edge = base_left_edge + time_window;
        
        idx_edges = data.time.getNearestIndices([base_left_edge, base_right_edge]);
        idxs_in_range = idx_edges(1): idx_edges(2);
        data_in_range = raw_data(idxs_in_range);
        
        m = mean(data_in_range);

        
        d = data.d;
        [max_val, idx]= max(d);
        max_time = data.time.getTimesFromIndices(idx);
        if max_val > m + 10*s && max_time < end_times(k) && max_time > start_times(k) && ~any(ismember(end_times(k), reset_end_times))
            %this is a solid void
            solid_starts(end + 1) = x_start_intersect(k); %because this has already been adjusted. Not super efficient..... :( will fix later
            solid_ends(end + 1) = end_times(k);
            x_end_intersect(k) = end_times(k);
        else
            s = std(data_in_range);
            left_edge = base_left_edge;
            cur_times = left_edge - flip(points_to_collect)*time_increment;
            cur_idxs = data.time.getNearestIndices(cur_times);
            cur_vals = raw_data(cur_idxs);
            
            while any(m - cur_vals(:) < flip(points_to_collect(:))*s) || any(m - cur_vals < 0)
                left_edge = left_edge - time_increment;

                cur_times = left_edge - flip(points_to_collect)*time_increment;
                if any(cur_times <= start_times(k))
                    %disp('Accuracy detection did not find a void')
                    %keyboard
                    x_end_intersect(k) = end_times(k);
                    break
                end
                cur_idxs = data.time.getNearestIndices(cur_times);
                cur_vals = raw_data(cur_idxs);
            end
            if x_end_intersect(k) == 0
                x_end_intersect(k) = cur_times(end);
            end
        end
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

obj.void_data.updateDetections(solid_starts,solid_ends);

obj.void_data.solid_void_start_times = [obj.void_data.solid_void_start_times(:)', solid_starts(:)'];
obj.void_data.solid_void_end_times = [obj.void_data.solid_void_end_times(:)'; solid_ends(:)'];
end