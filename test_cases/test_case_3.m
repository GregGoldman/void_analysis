   
      %third test run
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
    
    
    figure
    plot(obj.cur_stream_data);
    hold on
    unfiltered_d = obj.cur_stream_data.d;
    start_y = unfiltered_d(edges_obj.locs{1});
    end_y = unfiltered_d(edges_obj.locs{2});
    plot(edges_obj.time_locs{1},start_y,'k*')
    plot(edges_obj.time_locs{2},end_y, 'k+')
    
    
    
    
    start_marker_idx = obj.cur_stream_data.time.getNearestIndices(obj.cur_marker_times);
    end_marker_idx = obj.cur_stream_data.time.getNearestIndices(obj.cur_end_marker_times);
    
    start_y = unfiltered_d(start_marker_idx); 
    end_y = unfiltered_d(end_marker_idx);
    plot(obj.cur_marker_times,start_y, '>')
    plot(obj.cur_end_marker_times,end_y, '<')
    
    
    f = sci.time_series.filter.butter(2,[0.01 0.5],'stop');
    filt_d = obj.filtered_cur_stream_data.filter(f);
    
    %{
    error check
    if the ending value after a peak (on the original mass data) is very close in magnitude (within
    some threshold) to the value before the peak, then that peak is most
    likely not a void
    
    
    if there are a series of points that do not have the same number of
    starts and stops, there is an issue with that area.
    
    1.859*10^4
    1.862*10^4
    blip in data is about 3 seconds
    %}
    