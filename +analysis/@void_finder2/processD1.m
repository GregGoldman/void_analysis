function processD1(obj)
%   function processD1()
%   analysis.void_finder2.processD1();
%   method of the void_finder which analyzes the first derivative to find
%   points of   1)glitches 2)resets 3)evaporations


SPEED_THRESH = obj.options.speed_thresh;
big_jump_pts = obj.event_finder.findLocalMaxima(obj.data.d1,3,SPEED_THRESH);
positives = big_jump_pts.time_locs{1};
negatives = big_jump_pts.time_locs{2};

TOO_CLOSE = obj.options.d1_spike_window;
%seconds. only care abt a sharp up or down, not one after the other.
%spikes which are closer together than TOO_CLOSE are considered glitches

[pos_pres_in_neg, idx_of_loc_in_neg] = ismembertol(positives,negatives,TOO_CLOSE, 'DataScale', 1); 
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

TIME_THRESH = obj.options.glitch_time_window;
[bad_starts, bad_ends] = obj.void_data.getMarkersInTimeRange(glitch_start_peaks - TIME_THRESH, glitch_end_peaks + TIME_THRESH);

obj.void_data.invalidateRanges(bad_starts, bad_ends, 'glitch', 'overwrite', true);
end
function h__findEvaporations(obj,evap_POI)
%   for now, cut out 10 seconds on either side, although this has the
%   potential to cause problems...
%   shows up roughly in the middle of the evaporation period

EVAP_WINDOW = obj.options.evap_time_window;

left_edge = evap_POI - EVAP_WINDOW;
right_edge = evap_POI + EVAP_WINDOW;

[bad_starts, bad_ends] = obj.void_data.getMarkersInTimeRange(left_edge, right_edge);
obj.void_data.invalidateRanges(bad_starts, bad_ends, 'evap', 'overwrite', true);
end
function h__findResets(obj,reset_POI)
%   Take the first start point within the reset windown near the big reset
%   jump and the last end point. These tend to be correct
%   remove anything in between

RES_WINDOW = obj.options.reset_time_window;

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
    if ~isempty(close_starts)
        starts_to_remove = close_starts(2:end);
        
        start_to_save = close_starts(1);
        start_deletions = union(start_deletions, starts_to_remove);
        good_starts = union(good_starts,start_to_save);
    end
    if ~isempty(close_ends)
        ends_to_remove = close_ends(1:end-1);
        ends_to_save = close_ends(end);
        end_deletions = union(end_deletions, ends_to_remove);
        good_ends = union(good_ends, ends_to_save);
    end
end
obj.void_data.invalidateRanges(start_deletions, end_deletions, 'removed_reset');

obj.void_data.reset_start_times = good_starts;
obj.void_data.reset_end_times = good_ends;
end