
    % fourth test run ----------------------------------------------------
% %  -------------------------------------------------------------------------   
    % -------------------------------------------------------------------------      
    tic
    obj = analysis.void_finder;
    toc %0.070369 seconds
    tic
    obj.loadExpt(2);
    toc  %2.851483 seconds
    tic
    obj.loadAndFilterStream(1,1);
    toc %2.738669 seconds 
    tic
    obj.findPossibleVoids();
    toc %63 seconds to run
    
    edges_obj = obj.cur_starts_and_stops;
    figure
    plot(obj.filtered_cur_stream_data);
    hold on
    raw_data = obj.filtered_cur_stream_data.d;  
    start_y = raw_data(edges_obj.locs{1});
    end_y = raw_data(edges_obj.locs{2});
    plot(edges_obj.time_locs{1},start_y,'k*')
    plot(edges_obj.time_locs{2},end_y, 'k+')
    
    start_points = obj.cur_starts_and_stops.time_locs{1};
    end_points = obj.cur_starts_and_stops.time_locs{2};
    %-----------------------------------------------------------------------
    % if voids occur within the first 90 seconds, do not count
    % ------------------------------------------------------------
    calibration_period = 90; %seconds
    early_starts = find(start_points<calibration_period);
    start_points(early_starts) = [];
    
    early_stops = find(end_points<calibration_period);
    end_points(early_stops) = [];
    
    
    start_idx = obj.filtered_cur_stream_data.time.getNearestIndices(start_points);
    end_idx = obj.filtered_cur_stream_data.time.getNearestIndices(end_points);
    
    raw_data = obj.filtered_cur_stream_data.d;
    
    start_vals = raw_data(start_idx);
    end_vals = raw_data(end_idx);
    
    hold on
    h1 = plot(start_points,start_vals,'ko');
    h2 = plot(end_points, end_vals, 'ks');
    
    %analyze visually to check
    
    
        %------------------------------------------------------------------------
    %   if there is a random spike, ignore that spot
    %   ----------------------------------------------------------------------
    %   take a sample 5 seconds before the start.
    %   also take one 10 or 15 seconds later. if the values are close,
    %   disregard any points in that range
    %
    % TODO: a possible better way to do this is to consider if there is a
    % middle point which goes way above the end point... that's probably
    % better...
    %actually! probably not...
    tic
    back_time = 5;
    skip_time = 10;
    %so total spike width is roughly 15 seconds
    min_difference = 0.1;
    
    start_deletions = [];
    end_deletions = [];
    
    for i = 1:length(start_points)
        % i is times in seconds

        starting_idx = obj.filtered_cur_stream_data.time.getNearestIndices(start_points(i) - back_time);
        ending_idx = obj.filtered_cur_stream_data.time.getNearestIndices(start_points(i)+skip_time);
        
        starting_val = obj.filtered_cur_stream_data.d(starting_idx);
        ending_val = obj.filtered_cur_stream_data.d(ending_idx);
        
        in_between = obj.filtered_cur_stream_data.d(starting_idx:ending_idx);
        
        
        if (abs(starting_val - ending_val)<min_difference)
            %then we have to remove and of the points in between
            start_deletions = [start_deletions; find((start_points > start_points(i)-back_time)&(start_points<start_points(i)+skip_time))];
            
            end_deletions = [end_deletions; find((end_points>start_points(i)-back_time)&(end_points<start_points(i)+skip_time))];
        end
  
        
  
        if i == length(start_points)
            break;
        end
    end
    saved_start_pts = start_points;
    saved_end_pts = end_points;
    
    start_points(start_deletions) = [];
    end_points(end_deletions) = [];
    
    toc %0.071 seconds
    
    
      start_idx = obj.filtered_cur_stream_data.time.getNearestIndices(start_points);
    end_idx = obj.filtered_cur_stream_data.time.getNearestIndices(end_points);
    
     start_vals = raw_data(start_idx) - 0.01;
    end_vals = raw_data(end_idx)-0.01;
    
    h3 = plot(start_points,start_vals,'rd')
    h4 = plot(end_points,end_vals, 'rp')
    
    
    %-------------------------------------------------------------------
    %Treat the resets differently
    %------------------------------------------------------------------
    
    %first, remove all of the evaporation points 
    evap_t = obj.evaporation_times;
    res_t = obj.reset_times;
    
    evap_window = 10; %
    %for now, cut out 10 seconds on either side, although this has the
    %potential to cause problems...
    
    h5 = plot(evap_t,0*evap_t+2,'kh');
    %shows up roughly in the middle of the evaporation period
    start_deletions = [];
    end_deletions = [];
    
    for (i = 1:length(evap_t))
        start_deletions = [start_deletions;find((start_points > (evap_t(i) - evap_window)) & (start_points < (evap_t(i) + evap_window)))];
        end_deletions = [end_deletions; find((end_points > (evap_t(i) - evap_window))&(end_points < (evap_t(i) + evap_window)))];
    end
    
    %will just need to bring up these points as questionable when presented
    %to the user
    saved_start_pts2 = start_points;
    saved_end_pts2 = end_points;
    
    start_points(start_deletions) = [];
    end_points(end_deletions) = [];
  
      start_idx = obj.filtered_cur_stream_data.time.getNearestIndices(start_points);
    end_idx = obj.filtered_cur_stream_data.time.getNearestIndices(end_points);
    
     start_vals = raw_data(start_idx) - 0.02;
    end_vals = raw_data(end_idx)-0.02;
    
    h6 = plot(start_points,start_vals,'gd')
    h7 = plot(end_points,end_vals, 'gp')
    
        %note to self: would integration be a good option?
        
    %second, deal with the reset points...
       % plan: remove any data points that are in the middle of the reset,
       % but keep the points at the edges
       
       h8 = plot(res_t,0*res_t+4, 'kp');
       res_window = 6;
       close_starts = [];
       close_ends = [];
       
       for (i = 1:length(res_t))
           close_starts = [close_starts;find((start_points > (res_t(i) - res_window)) & (start_points < (res_t(i) + res_window)))];
           close_ends = [close_ends; find((end_points > (res_t(i) - res_window))&(end_points < (res_t(i) + res_window)))];
       end
   %need to find pairings and delete middle ones
        %better option: do this along the way!
   
   
    %----------------------------------------------------------------------
    %if a start or a stop occurs without a corresponding stop or start
    %within a threshold, it does not count-----------------------------
    
    %first, loop through the starting times
    start_array = start_points;
    stop_array = end_points;
    
    %now, sort them
   [sorted_start_array, SI] = sort(start_array);
   [sorted_stop_array,  EI] = sort(stop_array);
   
    result_class = sl.array.nearestPoint(sorted_stop_array,sorted_start_array, 'p1');
    
    pairs_by_sorted_idx = result_class.xy_pairs;
    %[x index, y index];
    
    starts = sorted_start_array(pairs_by_sorted_idx(:,1)); %these are in units of time
    stops = sorted_stop_array(pairs_by_sorted_idx(:,2));

    start_idxs = obj.filtered_cur_stream_data.time.getNearestIndices(starts); %these are in units of index
    stop_idxs = obj.filtered_cur_stream_data.time.getNearestIndices(stops);
    
    start_yy = obj.filtered_cur_stream_data.d(start_idxs); %these are the points on the graphs
    stop_yy =  obj.filtered_cur_stream_data.d(stop_idxs);
    
    
    hold on
    plot(starts,start_yy,'ko')
    plot(stops,stop_yy,'ks')
    
    
    

    