
    %second test run
    tic
    obj = analysis.void_finder;
    toc %0.070369 seconds
    tic
    obj.loadExpt(2);
    toc  %2.851483 seconds
    tic
    obj.loadAndFilterStream(1,1);
    toc %2.738669 seconds    
    plot(obj.filtered_cur_stream_data);
    
    tic
    obj.findPossibleVoids();
    toc
    
    raw_data = obj.cur_stream_data.d;
    edges_obj = obj.cur_starts_and_stops;
    plot(obj.cur_stream_data);
    hold on
    
    start_y = raw_data(edges_obj.locs{1});
    end_y = raw_data(edges_obj.locs{2});
    plot(edges_obj.time_locs{1},start_y,'k*')
    plot(edges_obj.time_locs{2},end_y, 'k+')
    

    
    B = sort(edges_obj.pks{1});
    C = sort(edges_obj.pks{2});
    
    %{
    ideas:
    1) if there are two stops in a row, delete one of them (weakest option)
   
 
    2) if one of the peaks is absurdly high, get rid of it
    
        for the starts, anything larger than (at the most) 0.04 seems to be
        impossible...

        for the stops: anything greater in magnitude than 0.06

        PROBLEM WITH THIS-----
        this also gets rid of the markers where the scale resets, and we
        actually need to interpret those as voids...
    %}
    
        
    start_thresh = 0.04 * 10^-5;
    stop_thresh = 0.06*10^-5;
    
    idx = find(edges_obj.pks{1}>start_thresh);
    
    %{
    new plan
    what we actually need to do is filter such that there is a maximum
    amount that there can be a jump in the original data. huge jumps are
    obviously noise, and other huge jumps are the scale being reset...
    
    
    find a way to remove spikes that jump up and then go back down to
    roughly the same magnitude--these are errors
    
    %}
 