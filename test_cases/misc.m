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
    
    toc