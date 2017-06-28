function normalized_to_save = normalizeVoidData(obj, starts, stops)
%
%
%   Inputs
%   ------
%   data_obj: void_finder2.data.cur_stream_data
%   starts (array of doubles)
%   stops (array of doubles)


all_rect_filtered_data = obj.data.rect_filtered_data;

num_blocks = 12;
normalized_to_save = zeros(0,num_blocks);
idx = 0; % move through that array

normalized_to_save(end+(1:length(starts)) ,num_blocks) = 0;

for j = 1:length(starts)
    start = starts(j);
    stop = stops(j);
    idx = idx + 1;
    
    cur_rect_filt_data = all_rect_filtered_data(j);
    

    data_blocks_cell = cur_rect_filt_data.subset.fromStartAndStopTimes(start,stop,'n_parts', num_blocks); %cell
    data_blocks = data_blocks_cell{1}; % dereference
    mean_vals = mean(data_blocks);
    offset_removed = mean_vals - min(mean_vals);
    normalized = offset_removed./(max(offset_removed) - min(offset_removed));
    
    %remove start and end which are always 0 and 1
    
    normalized_to_save(idx,:) = normalized;
end
end