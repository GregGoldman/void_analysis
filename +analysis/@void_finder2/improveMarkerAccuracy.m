function improveMarkerAccuracy(obj)
%
%   OUT OF DATE! Use improveAccuracyBySlopes
%
%
%   analysis.void_finder.improveMarkerAccuracy();
%
%   Attempts to get closer to the actual start of the void
%   event. Finds the slope just before and after the markers,
%   the finding the intersections of the resultant befor/after
%   lines. Uses the raw data for this calculation.
%
%   Treats reset points differently. Finds the max and min in
%   between reset start/end markers, then moves outward until
%   slopes approach consistent levels
%
%   TODO: give this its own class!!!!!!
%   TODO: make it more efficient!!!!!
%   TODO: split up into functions!!!!
error('out of date')

start_times = obj.void_data.updated_start_times;
end_times = obj.void_data.updated_end_times;

reset_start_times = obj.void_data.reset_start_times;
reset_end_times = obj.void_data.reset_end_times;

if length(start_times) ~= length(end_times)
    error('dimensions of starts/ends mismatched')
elseif length(reset_start_times) ~= length(reset_end_times)
    error('dimensions of reset points mismatched')
end

reset_idxs = [];

time_window = 1;
back_from_start = 2;
%   step the time distance back_from_start backward from the
%   start point, then from that point take the datapoints
%   forward in time_window
forward_from_start = 0;
%   step forward_from_start from the start point, then from
%   that point take the datapoints foward in time_window

back_from_end = 1;
forward_from_end = 2;

x_start_intersect = zeros(1,length(start_times));
x_end_intersect = zeros(1,length(end_times));

for i = 1:length(start_times)
    if ~ismember(start_times(i),reset_start_times)
        %--------- processing for the start points------------
        % flat section before start
        left_edge1 = start_times(i) - back_from_start;
        right_edge1 = left_edge1 + time_window;
        b1 = h__coefs(obj,left_edge1, right_edge1);
        % slope section after start
        left_edge2 = start_times(i) + forward_from_start;
        right_edge2 = left_edge2 + time_window;
        b2 = h__coefs(obj,left_edge2, right_edge2);
        
        x0_start = start_times(i);
        x_start_intersect(i) = fzero(@(x) glmval(b1-b2,x,'identity'),x0_start);
        
        %--------- processing for the end points------------
        %flat section after end
        left_edge3 = end_times(i) + forward_from_end;
        right_edge3 = left_edge3 + time_window;
        b3 = h__coefs(obj,left_edge3, right_edge3);
        %slope section before end
        left_edge4 = end_times(i) - back_from_end;
        right_edge_4 = left_edge4 + time_window;
        b4 = h__coefs(obj,left_edge4, right_edge_4);
        
        x0_end = start_times(i);
        x_end_intersect(i) = fzero(@(x) glmval(b3-b4,x,'identity'),x0_end);
        
    else %	this is a reset point
        %   get the max and min within the region of data
        %   go left of max until slope approaches the slope
        %   even further to the left (within a threshold) and
        %   do the same thing to the right for the end points
        %
        %   TODO: update the times found in the reset times so
        %   that we can be more accurate in displaying them
        
        reset_idxs(end+1) = i;
        [data_vals, times] = obj.data.getDataFromTimeRange('raw', [start_times(i), end_times(i)]);
        
        [~, max_loc] = max(data_vals);
        [~, min_loc] = min(data_vals);
        
        max_time = times(max_loc);
        min_time = times(min_loc);
        
        %find slopes over 1 second windows, shifting each
        %window by 0.25 second each time.
        time_window = 1;
        time_increment = 0.25;
        SLOPE_THRESH = 0.1;  %the allowable difference in slope
        base_skip_time = 10; % go out 10 seconds to find proper slope
        %   (seems to be reasonable given the data)
        %   ----------process for the start points------------
        right_edge_time = max_time;
        left_edge_time = right_edge_time - time_window;
        b1 = h__coefs(obj,left_edge_time, right_edge_time);
        
        base_right_edge = max_time - base_skip_time;
        base_left_edge = base_right_edge - time_window;
        b_base = h__coefs(obj,base_left_edge, base_right_edge);
        
        while abs(b_base(2) - b1(2)) > SLOPE_THRESH
            % keep incrementing to the left. Will then
            % hopefully get the start of the void within 1/4
            % of a second.
            right_edge_time = right_edge_time - time_increment;
            left_edge_time = right_edge_time - time_window;
            
            b1 = h__coefs(obj,left_edge_time, right_edge_time);
        end
        x_start_intersect(i) = right_edge_time;
        
        %------------process for the end points ------------
        % basically reverses the order of the code above (left
        % to right instead of right to left)
        left_edge_time = min_time;
        right_edge_time = left_edge_time + time_window;
        b1 = h__coefs(obj,left_edge_time,right_edge_time);
        
        base_left_edge = min_time + base_skip_time - time_window;
        base_right_edge = base_left_edge + time_window;
        b_base = h__coefs(obj,base_left_edge, base_right_edge);
        
        while abs(b_base(2) - b1(2)) > SLOPE_THRESH
            % keep incrementing to the left. Will then
            % hopefully get the start of the void within 1/4
            % of a second.
            left_edge_time = left_edge_time + time_increment;
            right_edge_time = left_edge_time + time_increment;
            
            b1 = h__coefs(obj,left_edge_time, right_edge_time);
        end
        x_end_intersect(i) = left_edge_time;
    end
end

obj.void_data.updated_start_times = x_start_intersect;
obj.void_data.updated_end_times = x_end_intersect;

obj.void_data.reset_start_times = x_start_intersect(reset_idxs);
obj.void_data.reset_end_times = x_end_intersect(reset_idxs);
end
%helpers
function b  = h__coefs(obj,left_edge, right_edge)
[vals, times]= obj.data.getDataFromTimeRange('raw', [left_edge, right_edge]);
b = glmfit(times, vals);
end