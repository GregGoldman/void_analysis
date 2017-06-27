function findSpikes(obj)
%
%   obj.findSpikes();
%
%   spikes tend to have start markers at roughly the same value on
%   both sides of the spike. need to find start points that are
%   close together in time and in magnitude.
%   also test whether or not the value before the spike is the
%   same as after the spike.


TIME_WINDOW = obj.options.spike_time_window; %seconds
Y_TOL = obj.options.spike_magnitude_tolerance;

vd = obj.void_data;

start_times = obj.void_data.updated_start_times;
[spike_starts, spike_ends] = h__spikes(obj, start_times, TIME_WINDOW, Y_TOL);

end_times = obj.void_data.updated_end_times;
[spike_starts2, spike_ends2] = h__spikes(obj,end_times, TIME_WINDOW, Y_TOL);

temp1 = sort([spike_starts, spike_starts2]);
temp2 = sort([spike_ends, spike_ends2]);

obj.void_data.invalidateRanges(temp1,temp2, 'spike', 'overwrite', true)
end

%   helper functions ------------------------------------
function [spike_start_markers, spike_end_markers] = h__spikes(obj, time_array, TIME_WINDOW, Y_TOL)
% for each time of interest, look forward and backward. If the start and
% end values are close together, there was likely a spike.

% preallocate for speed
spike_start_markers = zeros(1,20);
spike_end_markers = zeros(1,20);

start_count = 1;
end_count = 1;
start_deletions = [];
end_deletions = [];

for k = 1:length(time_array)
    cur_time = time_array(k);
    back_time = cur_time - TIME_WINDOW;
    forward_time = cur_time + TIME_WINDOW;
    
    temp = obj.data.getDataFromTimePoints('filtered',[back_time, forward_time]);
    back_val = temp(1);
    forward_val = temp(2);
    
    if abs(forward_val - back_val) < Y_TOL
        % this is probably a spike. Get all of the starts and
        % stops in that range
        [start_deletions, end_deletions] = obj.void_data.getMarkersInTimeRange(back_time, forward_time);
        
        if length(start_deletions) + start_count >= length(spike_start_markers)
           spike_start_markers = [spike_start_markers, zeros(1,20)]; 
        end
        if length(end_deletions) + end_count >= length(spike_end_markers)
           spike_start_markers = [spike_start_markers, zeros(1,20)]; 
        end
        
        spike_start_markers(start_count:(start_count + length(start_deletions) - 1)) = start_deletions;
        spike_end_markers(end_count:(end_count + length(end_deletions) - 1)) = end_deletions;
        
        start_count = length(spike_start_markers) + 1;
        end_count = length(spike_end_markers) +1;
    end
    start_deletions(start_deletions == 0) = [];
    end_deletions(end_deletions == 0) = [];
end
end
