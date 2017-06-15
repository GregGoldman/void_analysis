classdef void_finder2 <handle
    %
    %   Class:
    %   analysis.void_finder2
    %
    %   obj = analysis.void_finder2
    %
    %   This is really the running class. It does the calculations on
    %   actually finding where the voids are
    
    %{
    %   methods:
    %   ------------
    %   findExptFiles
    %       inputs:
    %       -

    %
    example:
       
        obj = analysis.void_finder2;
        obj.data.loadExpt(4);
        obj.data.getStream(4,3);
        obj.findPossibleVoids();
          % this will bring up an option to remove bad data somewhere in
          % the middle. Right now, it is important that this step is taken
          % until I can improve the recognition of those regions

          % to see the results:
        obj.data.plotData('raw');
        obj.void_data.plotMarkers('raw','cpt');
        obj.void_data.plotMarkers('raw','user');
    
          % * are computer-found starts, + are computer-found stops
          % circles are user starts, squares are user stops
    %}
    properties
        data                        % analysis.data
        void_data                   % analysis.void_data
        event_finder                % event_calculator
     
    end
    methods %overall functionality
        function obj = void_finder2()
            %   a class dedicated to loading files, finding voids, and
            %   calculating voided volume and voiding time
            obj.data =  analysis.data(obj);
            obj.void_data = analysis.void_data(obj);
        end
        function findPossibleVoids(obj)
            
            obj.event_finder = obj.data.d2.calculators.eventz;
            
            %-------------------------------------------------------------
            %   for the acceleration to find all the possible start and stop
            %   points (comes in obj.initial_detections)
            obj.processD2();
            %------------------------------------------------------------
            obj.IDCalibration(90); %input is 90 seconds, calibration period
            % updates obj.calibration_marks
            % also calls updateDetections (see obj.updated_detections)
            %------------------------------------------------------------
            obj.findSpikes();
            %------------------------------------------------------------
            obj.processD1();
            %------------------------------------------------------------
            obj.skipBadData();
            %------------------------------------------------------------
            obj.findPairs();
            %----------------------------------------------------------
            obj.findVoidType(2);
        end
    end
    %----------------------------------------------------------------------
    methods % data processing methods and filtering
        % processD1             (has its own file)
        % findSpikes            (has its own file)
        % improveMarkerAccuracy (has its own file)
        improveMarkerAccuracy(obj)
        function processD2(obj)
            %
            %   obj.processD2();
            %
            %   Processing on the second derivative of the data. Start
            %   points occur at peak positives in acceleration, end points
            %   occur at peak negatives in acceleration.
            
            ACCEL_THRESH = 3*10^-8;
            
            detections = obj.event_finder.findLocalMaxima(obj.data.d2,3,ACCEL_THRESH);
            obj.void_data.initial_start_times = detections.time_locs{1};
            obj.void_data.initial_end_times = detections.time_locs{2};
            
            obj.void_data.updated_start_times = obj.void_data.initial_start_times;
            obj.void_data.updated_end_times = obj.void_data.initial_end_times;
        end
        function IDCalibration(obj, calibration_period)
            %
            %   obj.IDCalibration(calibration_period)
            %
            %   Removes the start and end points which have been detected
            %   during the timeframe defined by calibration_period
            %
            
            start_times = obj.void_data.initial_start_times;
            end_times = obj.void_data.initial_end_times;
            
            obj.void_data.calibration_start_times = start_times(start_times<calibration_period);
            obj.void_data.calibration_end_times = end_times(end_times<calibration_period);
            
            obj.void_data.updateDetections(obj.void_data.calibration_start_times, obj.void_data.calibration_end_times);
        end
        function skipBadData(obj)
            %
            %   obj.skipBadData();
            %
            %   Brings up a graph of the filtered data with all of the
            %   markers found just up until before pairing occurs. The user
            %   can then select any data that appears spikey and has
            %   markers in it. Hopefully in the future this function is
            %   not necessary. For now, next step is to suggest regions
            %   of spikes
            
            continue_flag = input('would you like to select bad regions? (1 = yes, 0 = no)\n');
            if (continue_flag ~= 1)
                return
            end
            
            obj.data.plotData('filtered');
            obj.void_data.plotMarkers('filtered','cpt');
            
            disp('select a start and end point to remove the range from processed data')
            disp('zoom to a new region after every two selections (a prompt will appear)\n\n')
            
            disp('hit enter to begin. \nDo any panning/zooming before your response.\n');
            pause
            
            while continue_flag
                
                [x,~] = ginput(2);
                
                if length(x) ~= 2
                    disp('not enough points')
                    close
                    return
                elseif x(1) > x(2)
                    disp('invalid point selection')
                    close
                    return
                end

                [starts, ends] = obj.void_data.getMarkersInTimeRange(x(1),x(2));

                obj.void_data.updateDetections(starts, ends);
                obj.void_data.spike_start_times = union(obj.void_data.spike_start_times, starts);
                obj.void_data.spike_end_times = union(obj.void_data.spike_end_times, ends);
                
                continue_flag = input('would you like to select more regions? (1 = yes, 0 = no)\nDo any panning/zooming before response\n');
                if continue_flag ~= 1
                    close
                    return
                end
            end
            close
        end
        function findPairs(obj)
            %   findPairs(obj)
            %   findPairs attempts to match start and end markers by
            %   matching a given start with the next closest stop. It also
            %   deals with cases of missing points i.e.:
            %             start start stop
            %   should leave out the middle start point
            %   these points tend to occur in areas of tiny slope
            %   changes during a void, so they can reasonably be discounted
            
            %first, loop through the starting times
            start_times = obj.void_data.updated_start_times;
            end_times = obj.void_data.updated_end_times;
            
            ind = sl.array.nearestPoint2(start_times,end_times,'next');
            %   IND = NEARESTPOINT2(X,Y) finds the value in Y which is the closest to
            %   each value in X, so that abs(Xi-Yk) => abs(Xi-Yj) when k is not equal to j.
            %   IND contains the indices of each of these points.
            %   Example:
            %      NEARESTPOINT2([1 4 12],[0 3]) % -> [1 2 2]
            %       for each index in x, the value is the closest index in y
            %   'next'    : find the points in Y that are closets, but follow a point in X
            %               NEARESTPOINT2([1 4 3 12],[0 3],'next') % -> [2 NaN 2 NaN]
            
            % match pairs:
            partners = [];
            for i = 1:length(ind)
                if ~isnan(ind(i))
                    cur_val = ind(i);
                    
                    % we want to keep the one which is farthest away (the
                    % first one)
                    t = find(ind == ind(i));
                    start_to_save = t(1);
                    stop_to_save = cur_val;
                    % this assumes that starts always come first... and we
                    % may have a start start stop
                    
                    partners(end+1,1) = start_to_save;
                    partners(end,2) = stop_to_save;
                end
            end
            
            a = 1:length(start_times);
            b = 1:length(end_times);
            delete_start_idxs = setdiff(a,partners(:,1));
            delete_stop_idxs = setdiff(b,partners(:,2));
            
            obj.void_data.unpaired_start_times = start_times(delete_start_idxs);
            obj.void_data.unpaired_stop_times = end_times(delete_stop_idxs);
            
            obj.void_data.updateDetections(obj.void_data.unpaired_start_times,obj.void_data.unpaired_stop_times);
        end  
        function findVoidType(obj, noise_multiplier)
            %
            %   obj.findType();
            %
            %   classifies the voiding events by looking at voided volume,
            %   voiding time, proximity to other void events, etc...
            %
            %   Inputs:
            %   -----------
            %   - noise_multiplier: (double) voids must have a voided
            %                        volume at least this many times the 
            %                        magnitude of the noise (min to max) 
            %                        to be considered a valid void
            
            
            % First Step: pcik out the voids which have a magnitude under
            % the required threshold (noise_multiplier * magnitude_of_noise)
            %   - find the magnitude of the noise assuming that the
            %     magnitude is roughly constant everywhere
            obj.void_data.processCptMarkedPts;
            
            
            time_back = 5;
            time_window = 1;
            start_time = obj.void_data.updated_start_times(1) - time_back;
            end_time = start_time + time_window;
            data_range = obj.data.getDataFromTimeRange('raw',[start_time,end_time]);
            top = max(data_range);
            bottom = min(data_range);
            
            noise_mag = abs(top - bottom);
            min_volume = noise_multiplier * noise_mag;
            
            vv = obj.void_data.c_vv;
            
            too_small = (vv < min_volume);
            
            obj.void_data.too_small_start_times = obj.void_data.updated_start_times(too_small);
            obj.void_data.too_small_end_times = obj.void_data.updated_end_times(too_small);
            
            obj.void_data.updateDetections(obj.void_data.too_small_start_times, obj.void_data.too_small_end_times);
            
            % at this point, we have gotten rid of all of the super small
            % voids, so we it is time to make our markers more accurate  
            obj.improveMarkerAccuracy();
            
            obj.void_data.processCptMarkedPts();
            
           
            MAX_SLOPE = 0.7;
            temp = obj.void_data.c_slopes > MAX_SLOPE;
            bad_starts = obj.void_data.updated_start_times(temp);
            bad_ends = obj.void_data.updated_end_times(temp);
            
            obj.void_data.solid_void_start_times = bad_starts;
            obj.void_data.solid_void_end_times = bad_ends;
            
            obj.void_data.updateDetections(bad_starts, bad_ends);
        end
    end
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    methods % data extraction (voided volume, voiding time, etc...) and comparisons to user
        function compareUserCpt(obj)
            %   THIS FUNCTION NOT YET FINISHED/NOT YET WORKING
            % NYI
            
            %   most recent issue: a cpt marked point may match up with a
            %   user marked point, being considered correct, but that point
            %   may not actually be the correct match with the start
            %   point... Will have to look into this further. Going to deal
            %   with the filtering/processing more first.
            %
            %   look for cpt-marked points which are within one second of
            %   user-marked points
            %
            %   Dealing with reset points:
            %   The start and end times with reset points tend to be father
            %   from the user markers. extend the tolerance near these
            %   points and assume they are correct
            
            if length(obj.updated_start_times) ~= length(obj.updated_end_times)
                error('uneven number of markers... how did you do that?')
            end
            if length(obj.reset_end_times) ~= length(obj.reset_end_times)
                error('mismatched reset start and end times')
            end
            
            start_times = obj.updated_start_times;
            end_times = obj.updated_end_times;
            u_start_times = obj.u_start_times;
            u_end_times = obj.u_end_times;
            
            tolerance = 1;
            %--------------------------------------------------------
            %   finding the correct start indices
            %   TODO: fix the variable naming in here!!!!
            [a, b] = ismembertol(u_start_times,start_times,tolerance,'DataScale',1);
            % a is logical mask of where the data in u_start_times is within
            % tolerance of the data in start_times
            % b contains the indices in start times for each value in
            % vector a
            correct_start_idxs = b(b~=0); %indices of start_times which are matched with a user marker (within 1 second)
            matched_u_start_idxs = find(a); %indices of user start markers which had a correct cpt algorithm marker nearby
            %   ---------
            %   finding the correct end indices
            [c,d] = ismembertol(u_end_times,end_times,tolerance,'DataScale',1);
            % see comment on similar line with [a b] above
            correct_end_idxs = d(d~=0);
            matched_u_end_idxs = find(c);
            
            
            %   finding the overlap for both correct start and correct end
            %   indices
            cpt_success_idx = intersect(correct_start_idxs,correct_end_idxs);
            %   above line gives the indices of paired markers which are
            %   both correct
            
            %   find the corresponding markers to cpt_success_idx in the
            %   user-found markers
            u_success_idx = intersect(matched_u_start_idxs,matched_u_end_idxs);
            %{
            result of this section:
            cpt_success_idx:    indices in obj.updated_start_times (or
                                end_times) which have both start and end
                                matched with the user-found values
            
            u_success_idx:      the corresponding indices in the
                                user markers to those points in
                                cpt_success_idx
            %}
            %--------------------------------------------------------------
            % find indices which the computer missed:
            cpt_wrong_in_user_marks_idx = setdiff(1:length(u_start_times),u_success_idx);
            %   above line is the indices in the user-marked points which
            %   the computer did not find within an appropriate tolerance
            %   for both the start and the end points
            
            
            % wrong points (points which the computer got wrong)
            % indices on this list are included if either or both start and
            % end are wrong
            cpt_wrong_in_cpt_marks_idx = setdiff(1:length(start_times),cpt_success_idx);
            %{
            Results of this section:
            
            cpt_wrong_in_user_marks_idx:    indices in the user-marked
                                            points which the computer did
                                            not find within an appropriate
                                            tolerance
            
            cpt_wrong_in_cpt_marks_idx:     indices in the computer-marked
                                            points which have no
                                            corresponding correct user
                                            markers
            %}
            %--------------------------------------------------------------
            obj.comparison_result = analysis.comparison_result(obj,cpt_success_idx,u_success_idx,cpt_wrong_in_user_marks_idx,cpt_wrong_in_cpt_marks_idx);
        end
    end
end

