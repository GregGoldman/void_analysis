function processD1_2(obj)
%   function processD1()
%   analysis.void_finder.processD1();
%   method of the void_finder which analyzes the first derivative to find
%   points of   1)glitches 2)resets 3)evaporations


SPEED_THRESH = 4*10^-3;
big_jump_pts = obj.event_finder.findLocalMaxima(obj.d1,3,SPEED_THRESH);
positives = big_jump_pts.time_locs{1};
negatives = big_jump_pts.time_locs{2};

TOO_CLOSE = 10;
%seconds. only care abt a sharp up or down, not one after the other.
%spikes which are closer together than TOO_CLOSE are considered glitches

[pos_pres_in_neg, idx_of_loc_in_neg] = ismembertol(positives,negatives,TOO_CLOSE, 'DataScale', 1); %{'OutputAllIndices',true %}
% returns an array containing logical 1 (true) where the elements of A are within tolerance of the elements in B
% also returns an array, LocB, that contains the index location in B for each element in A that is a member of B.
evap_POI = positives(~pos_pres_in_neg);
t = find(idx_of_loc_in_neg); %need to know where the values are not zero
tt = idx_of_loc_in_neg(t);
ind = 1:length(negatives);
ind = setdiff(ind,tt);
reset_POI = negatives(ind);


h__findGlitches(obj,positives,negatives,pos_pres_in_neg, idx_of_loc_in_neg,tt);
h__findEvaporations(obj,evap_POI);
h__findResets(obj,reset_POI);
end
function h__findGlitches(obj,positives,negatives, pos_pres_in_neg, idx_of_loc_in_neg,tt)
%   glitch spikes have a characteristic up-then-down behavior in the slope.
%   areas of very close maxs and mins in the slope are generally glitch
%   points. This function removes them from the updated list of detections
glitch_peak_starts = positives(pos_pres_in_neg);

glitch_peak_ends = negatives(tt);
%these points are values in time

time_thresh = 5;
for i = 1:length(glitch_peak_starts)
    start_time = glitch_peak_starts(i) - time_thresh;
    end_time = glitch_peak_ends(i) + time_thresh;
    
    % mark the bad start points
    all_start_markers = obj.updated_start_times;
    start_idxs = (all_start_markers > start_time) & (all_start_markers < end_time);
    obj.glitch_start_times = all_start_markers(start_idxs)';
    
    % mark the bad end points
    all_end_markers = obj.updated_end_times;
    end_idxs = (all_end_markers > start_time) & (all_end_markers < end_time);
    obj.glitch_end_times = all_end_markers(end_idxs);
end
obj.updateDetections(obj.glitch_start_times, obj.glitch_end_times);
end
function h__findEvaporations(obj,evap_POI)
%   for now, cut out 10 seconds on either side, although this has the
%   potential to cause problems...
%   shows up roughly in the middle of the evaporation period


start_times = obj.updated_start_times;
end_times = obj.updated_end_times;
EVAP_WINDOW = 10; 

start_deletions_idx = [];
end_deletions_idx = [];

for (i = 1:length(evap_POI))
    start_deletions_idx = [start_deletions_idx;find((start_times > (evap_POI(i) - EVAP_WINDOW)) & (start_times < (evap_POI(i) + EVAP_WINDOW)))'];
    end_deletions_idx = [end_deletions_idx; find((end_times > (evap_POI(i) - EVAP_WINDOW))&(end_times < (evap_POI(i) + EVAP_WINDOW)))'];
end

obj.evap_start_times = start_times(start_deletions_idx);
obj.evap_end_times = end_times(end_deletions_idx);

obj.updateDetections(obj.evap_start_times, obj.evap_end_times);
end
function h__findResets(obj,reset_POI)
%   Take the first start point within the reset windown near the big reset
%   jump and the last end point. These tend to be correct
%   remove anything in between

start_times = obj.updated_start_times;
end_times = obj.updated_end_times;

RES_WINDOW = 10;
close_starts = [];
close_ends = [];

start_resets_idx = [];
end_resets_idx = [];
start_deletions_idx = [];
end_deletions_idx = [];

for i = 1:length(reset_POI)    
    %find the start points near the rest point
    %keep only the first one
    close_starts = find((start_times > (reset_POI(i) - RES_WINDOW)) & (start_times < (reset_POI(i) + RES_WINDOW)));
    start_deletions_idx = [start_deletions_idx ; close_starts(2:end)];
    start_resets_idx(end+1) = close_starts(1);

    close_ends = find((end_times > (reset_POI(i) - RES_WINDOW))&(end_times < (reset_POI(i) + RES_WINDOW)));
    end_deletions_idx = [end_deletions_idx; close_ends(1:end-1)];
    end_resets_idx(end+1)= close_ends(1);
end


obj.reset_start_times = start_times(start_resets_idx);
obj.reset_end_times = end_times(end_resets_idx);

obj.updateDetections(start_times(start_deletions_idx), end_times(end_deletions_idx));
end