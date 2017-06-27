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
        obj.data.loadExptOld(10);
        obj.data.getStreamOld(10,6);
        obj.findPossibleVoids();
     
    %{
        methods are indicated as 'Old' in the name when using a
        numerical indexing system. In this case, 10 is referring to
        Control Group\161212\161212 Control group_Analyzed.nss
    
        the gui uses the other methods without 'Old' in the name (direct
        filepath referencing)
    %}
    
        obj.data.plotData('raw');
        obj.void_data.plotMarkers('raw','cpt');
        obj.void_data.plotMarkers('raw','user');
    
          % * are computer-found starts, + are computer-found stops
          % circles are user starts, squares are user stops

    See expt_10_crawl_2 for comparison work!! (file is in folder called
    test_cases)
    %}
    properties
        data                        % analysis.data
        void_data                   % analysis.void_data
        event_finder                % event_calculator
        options                     % analysis.analysis_options
        
        certainty_level_array
        % array of indices for the markers which lists how sure we are
        % ranking from 1-3, 3 being the most certain
        
    end
    methods %overall functionality
        function obj = void_finder2()
            %   a class dedicated to loading files, finding voids, and
            %   calculating voided volume and voiding time
            obj.options = analysis.analysis_options();
            obj.data =  analysis.data(obj);
            obj.void_data = analysis.void_data(obj);
        end
        function findPossibleVoids(obj)
            %
            %
            %   obj.findPossibleVoids()
            %
            %   Runs all of the methods to process the data
            
            obj.event_finder = obj.data.d2.calculators.eventz;
            
            
            %Acceleration Processing
            % ----------------------
            % - Find all the possible start and stop points 
            % - populates:
            %       obj.initial_start_times, obj.initial_end_times
            %       obj.updated_start_times, obj.updated_end_times
            obj.processD2();
            
            
            
            %Handling balance calibration
            % ---------------------------------------------
            obj.IDCalibration();
            % input is 90 seconds, representing calibration period, so no
            % voids are allowed to occur within this time period
            % populates: 
            %       void_data.calibration_start_times
            %       obj.void_data.calibration_end_times
            %       the updated list of detections
            

            %------------------------------------------------------------
            obj.findSpikes();
            % Looks for regions in the data where magnitude increases and
            % then returns to normal. Still not perfect...
            
            
            %------------------------------------------------------------
            obj.processD1();
            % Finds resets, evaporations, and glitches near those points
            % (large spikes) by looking for big jumps in the slope. Resets
            % are characterized by large negative values, evaporations by
            % large positive values, and glitches by close together
            % positive then negative peaks
            
            
            %------------------------------------------------------------
            obj.findPairs();
            % Matches starts and stops which are closest together. Stores
            % markers without a partner
            
            
            %----------------------------------------------------------
            obj.improveAccuracyByStd();
            % Iterates through the marker pairs and looks for large changes
            % relative to the mean to find starts/stops (6/23/17)
            
            
            %------------------------------------------------------------
            MIN_VOID_TIME = obj.options.min_void_time;
            NOISE_MULTIPLIER  = obj.options.noise_multiplier;
            obj.removeShortAndSmall(MIN_VOID_TIME, NOISE_MULTIPLIER);
            % obj.findType(min_void_time, noise_multiplier);
            % see comments in fcn
            
            %----------------------------------------------------------
            obj.evaluateUncertainty();
            % Ranks the likelyhood of a proper marking by the residuals
            % from a straight line drawn between start and end markers
            % (residuals normalized to the magnitude of the voided volume)           
        end
    end
    methods % data processing methods and filtering
        % processD1             (has its own file)
        % findSpikes            (has its own file)
        % improveMarkerAccuracyByStd (has its own file) %TODO: change name
        function processD2(obj)
            %
            %   obj.processD2();
            %
            %   Processing on the second derivative of the data. Start
            %   points occur at peak positives in acceleration, end points
            %   occur at peak negatives in acceleration.
            
            ACCEL_THRESH = obj.options.accel_thresh;
            
            detections = obj.event_finder.findLocalMaxima(obj.data.d2,3,ACCEL_THRESH);
            
            vd = obj.void_data;
            vd.initial_start_times = detections.time_locs{1};
            vd.initial_end_times = detections.time_locs{2};
            
            vd.updated_start_times = obj.void_data.initial_start_times;
            vd.updated_end_times = obj.void_data.initial_end_times;
        end
        function IDCalibration(obj)
            %
            %   obj.IDCalibration()
            %
            %   Removes the start and end points which have been detected
            %   during the timeframe defined by calibration_period
            %
            
            CALIBRATION_PERIOD = obj.options.calibration_period;
            
            [cal_starts, cal_ends] = obj.void_data.getMarkersInTimeRange(0,CALIBRATION_PERIOD);
           
            % removes these times from the array
            obj.void_data.invalidateRanges(cal_starts, cal_ends, 'calibration');
        end
        function skipBadData(obj)
            %
            %
            %   OUT OF DATE: this method is no longer necessary
            %
            %   obj.skipBadData();
            %
            %   Brings up a graph of the filtered data with all of the
            %   markers found just up until before pairing occurs. The user
            %   can then select any data that appears spikey and has
            %   markers in it. Hopefully in the future this function is
            %   not necessary. For now, next step is to suggest regions
            %   of spikes
            disp('method out of date')
            keyboard
            
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
            %
            %   findPairs(obj)
            %
            %   findPairs attempts to match start and end markers by
            %   matching a given start with the next closest stop. 
            
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
            n_partners_max = min(length(start_times), length(end_times));
            partners = zeros(n_partners_max,2);
            partner_count = 0;
            for i = 1:length(ind)
                if ~isnan(ind(i))
                    partner_count = partner_count + 1;
                    cur_val = ind(i);
                    
                    %currently, just keep the closest two voids
                    
                    t = find(ind == ind(i), 1, 'last');
                    start_to_save = t;
                    stop_to_save = cur_val;
                    partners(partner_count, 1) = start_to_save;
                    partners(partner_count, 2) = stop_to_save;
                end
            end           
            a = 1:length(start_times);
            b = 1:length(end_times);
            delete_start_idxs = setdiff(a,partners(:,1));
            delete_stop_idxs = setdiff(b,partners(:,2));
            
            bad_starts = start_times(delete_start_idxs);
            bad_ends = end_times(delete_stop_idxs);
            
            obj.void_data.invalidateRanges(bad_starts, bad_ends, 'unpaired');
        end
        function removeShortAndSmall(obj, min_void_time, noise_multiplier)
            %
            %   obj.removeShortAndSmall(min_void_time, noise_multiplier);
            %
            %   classifies the voiding events by looking at voided volume,
            %   voiding time, proximity to other void events, etc...
            %
            %   Inputs
            %   ------
            %   min_void_time : double
            %   noise_multiplier : double
            %       Voids must have a voided volume at least this many
            %       times the magnitude of the noise (min to max) to be
            %       considered a valid void
            
            obj.void_data.processCptMarkedPts;
            % find VV and VT
            % remove those with small void times
            temp = obj.void_data.c_vt < min_void_time;
            bad_starts = obj.void_data.updated_start_times(temp);
            bad_ends = obj.void_data.updated_end_times(temp);
            obj.void_data.invalidateRanges(bad_starts, bad_ends, 'solid_void', 'overwrite', true);
            
            obj.void_data.processCptMarkedPts;
            % re-process without those bad voids
            % pick out the voids which have a magnitude under
            % the required threshold (noise_multiplier * magnitude_of_noise)
            %   - find the magnitude of the noise assuming that the
            %     magnitude is roughly constant everywhere
            
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
            bad_starts = obj.void_data.updated_start_times(too_small);
            bad_ends = obj.void_data.updated_end_times(too_small);
            
            obj.void_data.invalidateRanges(bad_starts, bad_ends, 'too_small');
        end
        function varargout = evaluateUncertainty(obj, varargin)
            %
            %   obj.evaluateUncertainty(*start_times, *end_times)
            %
            %   Uses the residuals to determine the expected accuracy of
            %   the markers which have been placed
            %
            %   If no inputs are entered, will use the object's updated
            %   list of start and end times. If using start and end times
            %   as inputs, will use those. If optional input arguments are
            %   used, user must include 1 output argument.
            %
            %   Examples:
            %      obj.evaluateUncertainty();      %populates local parameters
            %      certainty_array = obj.evaluateUncertainty(start_times, end_times)
            
            in.start_times = obj.void_data.updated_start_times;
            in.end_times = obj.void_data.updated_end_times;
            
            populate_local = 1;
            if nargin > 1
                in = sl.in.processVarargin(in, varargin);
                populate_local = 0;
                if nargout ~= 1
                    error('incorrect number of output arguments for number of input args')
                end
            end
            
            if length(in.start_times) ~= length(in.end_times)
                error('mismatched dimensions');
            end
            
            certainty_array = zeros(1, length(in.start_times));
            for k = 1:length(in.start_times)
                start_time = in.start_times(k);
                end_time = in.end_times(k);

                start_vals = obj.data.getDataFromTimeRange('raw', [start_time - 0.005, start_time + 0.005]);
                end_vals = obj.data.getDataFromTimeRange('raw', [end_time - 0.005, end_time + 0.005]);
                
                start_val = mean(start_vals);
                end_val = mean(end_vals);
                
                if start_time == end_time || end_time < start_time
                    disp('markers overlap')
                    % thie void must be removed--its index will be zero.
                    % See end of fcn for removal
                    continue
                end
                idxs = obj.data.cur_stream_data.time.getNearestIndices([start_time, end_time]);
                idx_range = idxs(1):idxs(2);
                times_in_range = obj.data.cur_stream_data.time.getTimesFromIndices(idx_range);
                data_in_range = obj.data.getDataFromTimeRange('raw',[start_time, end_time]);
                
                y =  end_val - start_val;
                x =  end_time - start_time;
                m = y/x;
                
                b = start_val - m*start_time;
                y_hat = polyval([m,b],times_in_range);
                
                % TODO: improvement could be to fit a more specific shape
                % than a line!
                
                % get the residuals
                r = y_hat(:) - data_in_range(:);
                normalized_r = r/y;
                
                sum_abs_res = sum(abs(normalized_r));
                if (sum_abs_res > 300)
                    certainty_array(k) = 1;
                elseif(sum_abs_res > 200)
                    certainty_array(k) = 2;
                else
                    certainty_array(k) = 3;
                end
            end
            temp1 = certainty_array == 0;
            output = certainty_array(~temp1);
            
            if nargout == 1 && ~populate_local
                varargout = cell(1,1);
                varargout{1} = output;
            elseif nargout == 0
                obj.certainty_level_array = output;
                obj.void_data.invalidateRanges(obj.void_data.updated_start_times(temp1),obj.void_data.updated_end_times(temp1), 'too_small');
            else
                error('num output args is wrong')
            end
        end
        function findSolidVoids(obj)
            %
            %    obj.findSolidVoids()
            %
            %    FOR DEBUGGING ONLY!
            %    Looks at the residuals in the data to find voids which are
            %    solid vs liquid. Solid voids with bad marker edge accuracy
            %    will have larger residuals of a line fit between the data
            %    points.
            %
            %   Plots the lines and displays the residuals for analysis. 
            
            if length(obj.void_data.updated_start_times) ~= length(obj.void_data.updated_end_times)
                error('mismatched dimensions');
            end
            
            obj.data.plotData('raw')
            obj.void_data.plotMarkers('raw','cpt')
            obj.void_data.plotMarkers('raw','user')
            g = gca;
            figure
            f = gca;
            
            solid_void_starts = [];
            solid_void_ends = [];
            
            for k = 1:length(obj.void_data.updated_start_times)
                start_time = obj.void_data.updated_start_times(k);
                end_time = obj.void_data.updated_end_times(k);
                
                
                start_vals = obj.data.getDataFromTimeRange('raw', [start_time - 0.005, start_time + 0.005]);
                end_vals = obj.data.getDataFromTimeRange('raw', [end_time - 0.005, end_time + 0.005]);
                
                start_val = mean(start_vals);
                end_val = mean(end_vals);
                
                if start_time == end_time || end_time < start_time
                    disp('markers overlap')
                    continue
                end
                idxs = obj.data.cur_stream_data.time.getNearestIndices([start_time, end_time]);
                idx_range = idxs(1):idxs(2);
                times_in_range = obj.data.cur_stream_data.time.getTimesFromIndices(idx_range);
                data_in_range = obj.data.getDataFromTimeRange('raw',[start_time, end_time]);
                
                
                voided_vol = end_val - start_val;
                
                y =  end_val - start_val;
                x =  end_time - start_time;
                m = y/x;
                
                b = start_val - m*start_time;
                y_hat = polyval([m,b],times_in_range);
                
                
                hold on
                plot(g,times_in_range,y_hat,'g-', 'linewidth', 2);
                axis(g,[start_time - 1, end_time + 1, -inf, inf]);
                
                % get the residuals
                r = y_hat(:) - data_in_range(:);
                normalized_r = r/voided_vol;
                
                cla(f);
                plot(f,normalized_r);
                
                sum_abs_res = sum(abs(normalized_r));
                disp(sum_abs_res);
                if (sum_abs_res > 400)
                    % this is probably a solid void
                    solid_void_starts(end+1) = start_time;
                    solid_void_ends(end+1) = end_time;
                end
                pause
            end
            obj.void_data.updateDetections(solid_void_starts, solid_void_ends);
            obj.void_data.solid_void_start_times = solid_void_starts;
            obj.void_data.solid_void_end_times = solid_void_ends;
        end
        function plot(obj, varargin)
            %
            %   reviewDataPlot(obj)
            %
            %   Plots based on the input arguments/defaults
            %   Inputs
            %   -------
            %   data_source: 
            %       -'raw' (default)
            %       - 'filtered' shows the butterworth filter results
            %       - 'rect' shows the rectangular filter results (NYI!)
            %   plot_user: true(defualt) or false
            %   plot_cpt: true(default) or false

            % set defaults
            in.data_source = 'raw';
            in.plot_user = true;
            in.plot_cpt = true;     
            
            % modify defaults
            in = sl.in.processVarargin(in, varargin);
            
            % plotting
            obj.data.plotData(in.data_source);
            
            hold on 
            if in.plot_user
                obj.void_data.plotMarkers(in.data_source, 'user');
            end
            if in.plot_cpt
                obj.void_data.plotMarkers(in.data_source, 'cpt');
            end
        end
        function walkThroughData(obj)
            %
            %   obj.walkThroughData()
            %
            %   Plots the raw data, the rect filtered data, and the cpt
            %   markers. Pauses at each region. Press 1, enter to go
            %   forward; 0, enter, to go backward. 
            %
            %   TODO: this is both ugly and slow
            
            
            start_times = obj.void_data.updated_start_times;
            end_times = obj.void_data.updated_end_times;
            
            
            if length(start_times) ~= length(end_times)
                error('dimensions of starts/ends mismatched')
            end
            
            base_skip_time = 5;
            time_window = 1;
            
            filter = sci.time_series.filter.smoothing(0.1,'type','rect');
            temp = obj.data.cur_stream_data.subset.fromStartAndStopTimes(start_times - base_skip_time - time_window  , end_times + base_skip_time + time_window , 'un', 0);
            temp2 = temp{1};
            filtered_data = temp2.filter(filter);
            
            obj.data.cur_stream_data.plot('color','yellow');
            hold on
            filtered_data.plot('linewidth',2, 'color','blue');
            hold on
            
            start_times = obj.void_data.updated_start_times;
            end_times = obj.void_data.updated_end_times;
            
            k = 1;
            while k < length(start_times)
                cur_data  = filtered_data(k);
                d = cur_data.d;
                
                start_idx = cur_data.time.getNearestIndices(start_times(k));
                start_val = d(start_idx);
                
                end_idx = cur_data.time.getNearestIndices(end_times(k));
                end_val = d(end_idx);
                
                plot(start_times(k), start_val, 'k*', 'markersize', 12);
                plot(end_times(k), end_val, 'k+', 'markersize', 12);
                
                start = obj.void_data.updated_start_times(k) - 1;
                stop = obj.void_data.updated_end_times(k) + 1;
                
                data_in_range = obj.data.getDataFromTimeRange('raw', [start, stop]);
                
                miny = min(data_in_range);
                maxy = max(data_in_range);
                
                axis([start,stop,miny,maxy])
                
                a = input('');
                
                if a == 1
                    k = k+1;
                else
                    k = k-1;
                end
            end
        end
    end
end

