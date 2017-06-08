
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
    toc
    
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
    start_points(start_deletions) = [];
    end_points(end_deletions) = [];
    
    toc %0.071 seconds
    
    %-------------------------------------------------------------------
    %if there is a decreasing slope before a stop point, then that stop
    %point should not be there
    %------------------------------------------------------------------
  %%%** possible easier way to do this: look back a few data pts. is that
  %%%value smaller or larger?
            %problem with that is that we then get rid of all of the sharp
            %drops...
                %could solve this by having another threshold change after
                %considering how quickly changes occur with the reset.
    
    evaporation_rate = 5; %some number which is relatively small compared to the huge drops for resets
        %need a good way to find this to proceed -- basically need some
        %approximation for a normal evaporation rate
        % will be a similar but reversed thing for removing false starts
        
    %skip 10 seconds backward
    %take the slope over 5 seconds
    %if it is not positive, then this must be a false start
    
    %loop through all of the starts
    
	temp = end_points;
    for i = 1: length(end_points)
        %grab older data
        
    end
    
    
    linear_calculator = sci.time_series.calculators.regression.linearFit(data_to_fit);
    
    
    
    
    
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
    
    
    

    