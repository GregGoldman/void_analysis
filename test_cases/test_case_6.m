
    % fifth test run ----------------------------------------------------
    %  -------------------------------------------------------------------------   
    % -------------------------------------------------------------------------      
tic
    obj = analysis.void_finder;
    obj.loadExpt(2);
    obj.loadStream(1,1);
    obj.filterCurStream();
    obj.findPossibleVoids();
    toc
    
    
    
    profile on
    obj.findPossibleVoids();
    profile off
    %------------------------------------
    
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
    
     start_vals = raw_data(start_idx) - 0.01;
    end_vals = raw_data(end_idx)-0.01;
    
    h6 = plot(start_points,start_vals,'gd')
    h7 = plot(end_points,end_vals, 'gp')
    
        
    %second, deal with the reset points...
       % plan: remove any data points that are in the middle of the reset,
       % but keep the points at the edges
       
       h8 = plot(res_t,0*res_t+4, 'kp');
       res_window = 10;
       close_starts = [];
       close_ends = [];
       
       starts_to_delete = [];
       ends_to_delete = [];
       
       for (i = 1:length(res_t))
          
           %find the start points near the rest point
           %keep only the first one
            close_starts = find((start_points > (res_t(i) - res_window)) & (start_points < (res_t(i) + res_window)));
            starts_to_delete = [starts_to_delete ; close_starts(2:end)]; 
            
            close_ends = find((end_points > (res_t(i) - res_window))&(end_points < (res_t(i) + res_window)));
            ends_to_delete = [ends_to_delete; close_ends(1:end-1)]; 
       end
       
       saved_start_pts3 = start_points;
       saved_end_pts3 = end_points;
       
       start_points(starts_to_delete) = [];
       end_points(ends_to_delete) = [];
       
       
       
       start_idx = obj.filtered_cur_stream_data.time.getNearestIndices(start_points);
       end_idx = obj.filtered_cur_stream_data.time.getNearestIndices(end_points);
       
       start_vals = raw_data(start_idx) - 0.01;
       end_vals = raw_data(end_idx)-0.01;
       
       h9 = plot(start_points,start_vals,'gd')
       h10 = plot(end_points,end_vals, 'gp')
       
       
   %    deal with the glitch points found using the slope method
         glitch_markers = [obj.glitch_markers{:}];
         mid_vals = (glitch_markers(:,1) + glitch_markers(:,2))*0.5;
         time_thresh = 10;
         
         starts_to_delete = [];
         ends_to_delete = [];
         
         for (i = 1:length(mid_vals))
             %find the start points near the rest point
             %keep only the first one
             close_starts = find((start_points > (mid_vals(i) - time_thresh)) & (start_points < (mid_vals(i) + time_thresh)));
             starts_to_delete = [starts_to_delete ; close_starts];
             
             close_ends = find((end_points > (mid_vals(i) - time_thresh))&(end_points < (mid_vals(i) + time_thresh)));
             ends_to_delete = [ends_to_delete; close_ends];
         end
         
         saved_start_pts4 = start_points;
       saved_end_pts4 = end_points;
       
       start_points(starts_to_delete) = [];
       end_points(ends_to_delete) = [];
   
       
       start_idx = obj.filtered_cur_stream_data.time.getNearestIndices(start_points);
       end_idx = obj.filtered_cur_stream_data.time.getNearestIndices(end_points);
       
       start_vals = raw_data(start_idx) - 0.01;
       end_vals = raw_data(end_idx)-0.01;
       
       h12 = plot(start_points,start_vals,'gd')
       h13 = plot(end_points,end_vals, 'gp')
   
       saved_start_pts5 = start_points;
       saved_end_pts5 = end_points;
    %----------------------------------------------------------------------
    %if a start or a stop occurs without a corresponding stop or start
    %within a threshold, it does not count-----------------------------
    
    
    %PROBLEM WITH PAIR FINDING: it is not always the closest one which is
    %the correct one........ :( it is more likely the farther of the
    %closest ones...
    
    
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
    
    
    %at this point:
    % the 'starts' variable is the starting marker times
    % the 'stops' variable is the stopping marker times
    %start_yy and stop_yy are the values at those corresponding marker
    %times
    
    
    hold on
   h14 = plot(starts,start_yy,'ko');
    h15 = plot(stops,stop_yy,'ks');
    
    
    

    