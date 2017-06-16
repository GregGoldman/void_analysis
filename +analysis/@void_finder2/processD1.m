function processD1(obj)
%   function processD1()
%   analysis.void_finder2.processD1();
%   method of the void_finder which analyzes the first derivative to find
%   points of   1)glitches 2)resets 3)evaporations


SPEED_THRESH = 3*10^-3;
big_jump_pts = obj.event_finder.findLocalMaxima(obj.data.d1,3,SPEED_THRESH);
positives = big_jump_pts.time_locs{1};
negatives = big_jump_pts.time_locs{2};

TOO_CLOSE = 10;
%seconds. only care abt a sharp up or down, not one after the other.
%spikes which are closer together than TOO_CLOSE are considered glitches

[pos_pres_in_neg, idx_of_loc_in_neg] = ismembertol(positives,negatives,TOO_CLOSE, 'DataScale', 1); %{'OutputAllIndices',true %}
% returns an array containing logical 1 (true) where the elements of A are within tolerance of the elements in B
% also returns an array, LocB, that contains the index location in B for each element in A that is a member of B.
evap_POI = positives(~pos_pres_in_neg);

[~, ~, bad_neg_idxs] = find(idx_of_loc_in_neg);
ind = 1:length(negatives);
reset_POI_idx = setdiff(ind,unique(bad_neg_idxs));
reset_POI = negatives(reset_POI_idx);

h__findGlitches(obj,positives,negatives,pos_pres_in_neg, idx_of_loc_in_neg, bad_neg_idxs);
h__findEvaporations(obj,evap_POI);
h__findResets(obj,reset_POI);
end
function h__findGlitches(obj,positives,negatives, pos_pres_in_neg, idx_of_loc_in_neg, bad_neg_idxs)
%   glitch spikes have a characteristic up-then-down behavior in the slope.
%   areas of very close maxs and mins in the slope are generally glitch
%   points. This function removes them from the updated list of detections
glitch_start_peaks = positives(pos_pres_in_neg);
glitch_end_peaks = negatives(bad_neg_idxs);

obj.void_data.glitch_start_times = [];
obj.void_data.glitch_end_times = [];
TIME_THRESH = 15;
for i = 1:length(glitch_start_peaks)
    start_time = glitch_start_peaks(i) - TIME_THRESH;
    end_time = glitch_end_peaks(i) + TIME_THRESH;
    
    [bad_starts, bad_ends] = obj.void_data.getMarkersInTimeRange(start_time, end_time);
    
    temp = obj.void_data.glitch_start_times;
    obj.void_data.glitch_start_times = union(temp,bad_starts);
    
    temp2 = obj.void_data.glitch_end_times;
    obj.void_data.glitch_end_times = union(temp2,bad_ends);
end
obj.void_data.updateDetections(obj.void_data.glitch_start_times, obj.void_data.glitch_end_times);
end
function h__findEvaporations(obj,evap_POI)
%   for now, cut out 10 seconds on either side, although this has the
%   potential to cause problems...
%   shows up roughly in the middle of the evaporation period

start_times = obj.void_data.updated_start_times;
end_times = obj.void_data.updated_end_times;
EVAP_WINDOW = 10; 

start_deletions = [];
end_deletions = [];

for (i = 1:length(evap_POI))
    left_edge = evap_POI(i) - EVAP_WINDOW;
    right_edge = evap_POI(i) + EVAP_WINDOW;
    
    [bad_starts, bad_ends] = obj.void_data.getMarkersInTimeRange(left_edge, right_edge);
    
    start_deletions = union(start_deletions, bad_starts);
    end_deletions = union(end_deletions, bad_ends);
end

obj.void_data.evap_start_times = start_deletions;
obj.void_data.evap_end_times = end_deletions;

obj.void_data.updateDetections(obj.void_data.evap_start_times, obj.void_data.evap_end_times);
end
function h__findResets(obj,reset_POI)
%   Take the first start point within the reset windown near the big reset
%   jump and the last end point. These tend to be correct
%   remove anything in between

start_times = obj.void_data.updated_start_times;
end_times = obj.void_data.updated_end_times;
RES_WINDOW = 10;

start_deletions = [];
end_deletions = [];

good_starts = [];
good_ends = [];
for i = 1:length(reset_POI)    
    %find the start points near the rest point
    %keep only the first one
    left_edge = reset_POI(i) - RES_WINDOW;
    right_edge = reset_POI(i) + RES_WINDOW;
    
    [close_starts, close_ends] = obj.void_data.getMarkersInTimeRange(left_edge, right_edge);
    % at this point, it is possible that all of these points were already
    % deleted by glitch detection (possibly incorrectly). Have to check
    if length(close_starts) ~= 0
        starts_to_remove = close_starts(2:end);
        
        start_to_save = close_starts(1);
        start_deletions = union(start_deletions, starts_to_remove);
        good_starts = union(good_starts,start_to_save);
        
    end
    if length(close_ends) ~= 0
        ends_to_remove = close_ends(1:end-1);
        ends_to_save = close_ends(end);
        end_deletions = union(end_deletions, ends_to_remove);
        good_ends = union(good_ends, ends_to_save);
        
    end
end
obj.void_data.removed_reset_start_times = start_deletions;
obj.void_data.removed_reset_end_times = end_deletions;

obj.void_data.reset_start_times = good_starts;
obj.void_data.reset_end_times = good_ends
obj.void_data.updateDetections(obj.void_data.removed_reset_start_times,obj.void_data.removed_reset_end_times);
end