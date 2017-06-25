function findSpikes(obj)
%
%   obj.findSpikes();
%
%   JAH: I've added my own description for reference
%
%   Spikes are artifacts in the signal that should not be counted as
%   voiding events. Unlike voids, balance data following a spike tends 
%   to return to the same value as before the spike. 
%
%   In this algorithm we compare the amplitude of balance values before
%   and after potential void starts and stops. If this amplitude is too
%   similar, the potential start or stop is marked as no longer valid.
%   
%
%   JAH: Old description
%   spikes tend to have start markers at roughly the same value on
%   both sides of the spike. need to find start points that are
%   close together in time and in magnitude.
%   also test whether or not the value before the spike is the
%   same as after the spike.

%JAH: Move to options
%.spike_time_window
%.spike_y_tol
TIME_WINDOW = 10; %seconds
Y_TOL = 0.1;

%JAH: I'm not thrilled with the word 'updated' ... although I'm not sure
%what would be better
start_times = obj.void_data.updated_start_times;
[spike_starts, spike_ends] = h__spikes(obj, start_times, TIME_WINDOW, Y_TOL);

%JAH: updateDetections should be renamed
%void_data.removeStartStopTimes?
obj.void_data.updateDetections(spike_starts, spike_ends);

end_times = obj.void_data.updated_end_times;
[spike_starts2, spike_ends2] = h__spikes(obj,end_times, TIME_WINDOW, Y_TOL);
obj.void_data.updateDetections(spike_starts2, spike_ends2);

obj.void_data.spike_start_times = sort([spike_starts, spike_starts2]);
obj.void_data.spike_end_times = sort([spike_ends, spike_ends2]);
end

%   helper functions ------------------------------------
function [spike_start_markers, spike_end_markers] = h__spikes(obj, time_array, TIME_WINDOW, Y_TOL)
%
%
%   TODO: Describe once more briefly what this function is doing

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
