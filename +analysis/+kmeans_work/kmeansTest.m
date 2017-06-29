%kmeansTest.m

obj = analysis.void_finder2;
obj.data.loadExptOld(10);
obj.data.getStreamOld(10,6);
obj.findPossibleVoids();

starts = obj.void_data.updated_start_times;
stops = obj.void_data.updated_end_times;


num_blocks = 10;


normalized_to_save = zeros(length(starts),num_blocks);
%should we remove the first index (always zero) and do an extra point?
%same thing for the last index (always one)

idxs_to_save = zeros(length(starts),num_blocks);
C_to_save = zeros(length(starts),3);

for k = 1:length(starts)
    start = starts(k);
    stop = stops(k);
    
    data = obj.data.cur_stream_data.subset.fromStartAndStopTimes(start,stop,'n_parts', num_blocks); %cell
    data2 = data{1}; % dereference
    mean_vals = mean(data2);
    offset_removed = mean_vals - mean_vals(1);
    normalized = offset_removed./(offset_removed(end) - offset_removed(1));
    
    normalized_to_save(k,:) = normalized;
    
    [idx C] = kmeans(normalized(:),3);
    keyboard
    idxs_to_save(k,:) = idx';
    C_to_save(k,:) = C';
end
