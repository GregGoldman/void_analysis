input = 'Spikes'
switch input
    case 'Voids Found'
        data = obj.start_marker_times;
    case 'Calibration'
        a = obj.void_finder2.void_data.calibration_start_times;
        b = obj.void_finder2.void_data.calibration_end_times;
    case 'Spikes'
        a =  obj.void_finder2.void_data.spike_start_times;
        b =  obj.void_finder2.void_data.spike_end_times;
    case 'Evaporations'
        a =  obj.void_finder2.void_data.evap_end_times;
        b =  obj.void_finder2.void_data.evap_start_times;
    case 'Glitches'
        a =  obj.void_finder2.void_data.glitch_start_times;
        b =  obj.void_finder2.void_data.glitch_end_times;
    case 'Bad Resets'
        % too close to glitches, evaporations, etc
        a = obj.void_finder2.void_data.removed_reset_start_times;
        b = obj.void_finder2.void_data.removed_reset_end_times;
    case 'Unpaired'
        a =  obj.void_finder2.void_data.unpaired_start_times;
        b =  obj.void_finder2.void_data.unpaired_stop_times;
    otherwise
        error('there''s a bug here')
end
c = [a,b];
d = sort(c);

times_of_interest = [];

tolerance = 60;
stop_idx = length(d);
k = 1;
while(k < stop_idx)
    times_of_interest(end+1) = d(k);
    temp = d - d(k) < tolerance;
    temp2 = find(~temp);
    
    if isempty(temp2)
        break
    else
        temp3 = find(~temp);
        k = temp3(1); %skip over the times we have already seen
    end
end


% times_of_interest is now an array that will have start
% times that skip over any other points within 1 minute


%TODO:
%           obj.refreshTimesList();