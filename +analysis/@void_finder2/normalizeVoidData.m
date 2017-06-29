function normalized_to_save = normalizeVoidData(obj, starts, stops)
%
%
%   Inputs
%   ------
%   data_obj: void_finder2.data.cur_stream_data
%   starts (array of doubles)
%   stops (array of doubles)


all_rect_filtered_data = obj.data.rect_filtered_data;

n = length(all_rect_filtered_data);

filtered_start_times = zeros(1,n);
filtered_end_times = zeros(1,n);

for k = 1:n
    temp = all_rect_filtered_data(k);
    filtered_start_times(k) = temp.time.start_time;
    filtered_end_times(k) = temp.time.end_time;
end


num_blocks = 12;
normalized_to_save = zeros(0,num_blocks);
idx = 0; % move through that array

normalized_to_save(end+(1:length(starts)) ,num_blocks) = 0;

for j = 1:length(starts)
     idx = idx + 1;
    start = starts(j);
    stop = stops(j);
    % assume that starts and stops are entirely within a filtered time
    % range
    A = start;
    B = stop;
    C = filtered_start_times;
    D = filtered_end_times; 
    
    filtered_data_idx = B > C & A < D;
    if ~any(filtered_data_idx)
       error('no filtered data in this range (and so probably no marker)') 
    end
    
    if sum(filtered_data_idx) > 1    %there are multiple overlaps
        % take the biggest overlap
    E = C(filtered_data_idx);
    F = D(filtered_data_idx);
    
    overlap1 = F - A; % end of filtered - start marker time
    overlap2 = B - E; % end marker time - start of filtered
    
    temp = [overlap1; overlap2];
    %each column is a different overlap region
   
    I = min(temp);
    % the maximum value of I is the length of the biggest overlap of the
    % group
    [~, y] = max(I);% = find(I == max(I));
    y = unique(y);
    % y is now the index of the possible filtered data sections chosen
    
    temp2 = find(filtered_data_idx);
    filtered_data_idx = temp2(y);
    end

    cur_rect_filt_data = all_rect_filtered_data(filtered_data_idx);
    

    data_blocks_cell = cur_rect_filt_data.subset.fromStartAndStopTimes(start,stop,'n_parts', num_blocks); %cell
    data_blocks = data_blocks_cell{1}; % dereference
    mean_vals = mean(data_blocks);
    offset_removed = mean_vals - min(mean_vals);
    normalized = offset_removed./(max(offset_removed) - min(offset_removed));
    
    %remove start and end which are always 0 and 1
    
    normalized_to_save(idx,:) = normalized;
end
end