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

start_times = obj.void_data.updated_start_times;
[spike_starts, spike_ends] = h__spikes(obj, start_times, TIME_WINDOW, Y_TOL);
obj.void_data.updateDetections(spike_starts, spike_ends);

end_times = obj.void_data.updated_end_times;
[spike_starts2, spike_ends2] = h__spikes(obj,end_times, TIME_WINDOW, Y_TOL);
obj.void_data.updateDetections(spike_starts2, spike_ends2);

obj.void_data.spike_start_times = sort([spike_starts, spike_starts2]);
obj.void_data.spike_end_times = sort([spike_ends, spike_ends2]);
end

%   helper functions ------------------------------------
function [spike_start_markers, spike_end_markers] = h__spikes(obj, time_array, TIME_WINDOW, Y_TOL)
spike_start_markers = [];
spike_end_markers = [];

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
        spike_start_markers = [spike_start_markers, start_deletions];
        spike_end_markers = [spike_end_markers, end_deletions];
    end
end
end
