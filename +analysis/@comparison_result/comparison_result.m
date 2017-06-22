classdef comparison_result < handle
    %
    %   Class:
    %   analysis.comparison_result
    %
    %   stores thre results of comparing the computer-identified voids to
    %   the user-identified voids
    
    properties
        p
        %  parent void_finder class
        
        %-------------
        % prob get rid of these. That comparison doesn't work well
        correct_starts
        matched_u_starts
        incorrect_starts
        missed_starts
        
        correct_ends
        matched_u_ends
        incorrect_ends
        missed_ends
        
        
        % --------------
        % variables below apply when only both start and ends are correct        
        final_start_times
        final_end_times
        % the times from the computer-found data which are matched both
        % start and end
        cpt_wrong_start
        cpt_wrong_end
        
        user_missed_start
        user_missed_end
        
        

    end
    
    methods
        function obj = comparison_result(p)
            obj.p = p;
            obj.compareOverlap();
        end
        function compareOverlap(obj)
            %
            %   obj.compareOverlap()
            %
            %   considers voids correct if there is a certain percent
            %   overlap in the void time
            %
            OVERLAP_THRESH = 0.1;
            
            obj.p.processHumanMarkedPts; %for error checking purposes in number of start/end markers
            
            start_times = obj.p.updated_start_times;
            end_times = obj.p.updated_end_times;
            
            u_start_times = obj.p.u_start_times;
            u_end_times = obj.p.u_end_times;
            
            correct_cpt = [];
            correct_user = [];
            
            for k = 1:length(start_times)
                A = start_times(k);
                B = end_times(k);
                
                for j = 1:length(u_start_times)
                 C = u_start_times(j);
                 D = u_end_times(j);
                 
                 if (B > C && A < D)
                     % there is overlap
                     overlap_length = min([B-A, D-A,D-C, B-C]);
                     user_length = D-C;
                     if overlap_length / user_length > OVERLAP_THRESH
                       % we consider the void to be correct
                       correct_cpt(end+1) = k;
                       correct_user(end+1) = j;
                     end
                    break 
                 end
                end
            end
            
            cpt_idx = 1:length(start_times);
            u_idx = 1:length(u_start_times);
            
            incorrect_cpt = setdiff(cpt_idx,correct_cpt);
            incorrect_u = setdiff(u_idx,correct_user);
            
            obj.final_start_times = start_times(correct_cpt);
            obj.final_end_times = end_times(correct_cpt);
            
            obj.cpt_wrong_start = start_times(incorrect_cpt);
            obj.cpt_wrong_end = end_times(incorrect_cpt);
            
            obj.user_missed_start = u_start_times(incorrect_u);
            obj.user_missed_end = u_end_times(incorrect_u);           
        end
        function runComparison(obj)
            %
            %   obj.runComparison()
            %
            %   keeps track of where we are within 1 second of the
            %   user-found markers
            
            start_times = obj.p.updated_start_times;
            end_times = obj.p.updated_end_times;
            
            u_start_times = obj.p.u_start_times;
            u_end_times = obj.p.u_end_times;
            tolerance = 1;
            [a,b] = ismembertol(start_times,u_start_times,tolerance,'DataScale',1);
            % a is logical mask of where data in start_times is within
            % tolerance of data in u_start_times
            obj.correct_starts = start_times(a);
            obj.matched_u_starts = u_start_times(b(b~=0));
            
            obj.incorrect_starts = start_times(~a);
            temp = 1:length(u_start_times);
            temp2 = setdiff(temp,b(b~=0));
            obj.missed_starts = u_start_times(temp2);
            

            [c,d] = ismembertol(end_times, u_end_times, tolerance, 'DataScale',1);
            obj.correct_ends = end_times(c);
            obj.matched_u_ends = u_end_times(d(d~=0));
            
            obj.incorrect_ends = end_times(~c);
            temp = 1:length(u_end_times);
            temp2 = setdiff(temp,d(d~=0));
            obj.missed_ends = u_end_times(temp2);
            
            % now have to find where both start and end are correct
            
            both_correct_idx =  (a & c)';
            obj.final_start_times = start_times(both_correct_idx);
            obj.final_end_times = end_times(both_correct_idx);
            
            not_correct_idx = ~both_correct_idx;
            obj.cpt_wrong_start = start_times(not_correct_idx);
            obj.cpt_wrong_end = end_times(not_correct_idx);
            
            idx_array = 1:length(u_start_times); % same as length of u_end_times
            t1 = setdiff(idx_array,b);
            t2 = setdiff(idx_array,d);
            
            t3 = union(t1,t2);
            % t3 is the user markers which did not have BOTH matched
            % starts/ends
            
            obj.user_missed_start = u_start_times(t3);
            obj.user_missed_end = u_end_times(t3); 
        end
        function walk(obj,source)
            obj.p.h.data.plotData('raw');
            obj.p.plotMarkers('raw','cpt');
            obj.p.plotMarkers('raw','user');
            
            switch lower(source)
                case 'cpt'
                    POI = obj.cpt_wrong_start;
                case 'user'
                    POI = obj.user_missed_start;
                otherwise
                    error('unrecognized')
            end
            
            for k = 1:length(POI)
                left = POI(k) - 5;
                right = POI(k) + 10;
                
                data_in_range = obj.p.h.data.getDataFromTimeRange('raw', [left right]);
                maxy = max(data_in_range);
                miny = min(data_in_range);
                
                axis([left,right,miny - 1,maxy + 1])
                val = obj.p.h.data.getDataFromTimePoints('raw',POI(k));
                plot(POI(k),val,'rh','MarkerSize',12)
                pause
            end
        end
        function walkThroughDetections(obj, source)
            %
            %   walkThroughDetections(source)
            %
            %   Skips along through all of the data showing areas that
            %   cause problems.
            %
            %   Inputs:
            %   ---------
            %   - source: 'missed_starts', 'incorrect_starts', 'missed_ends',
            %             'incorrect_ends'
            %
            
       switch source
           case 'missed_starts'
              POI = obj.missed_starts;
           case 'incorrect_starts'
              POI = obj.incorrect_starts;
           case 'missed_ends'
               POI = obj.missed_ends;
           case 'incorrect_ends'
                POI = obj.incorrect_ends;
           otherwise
               error('unrecognized input')
       end
                       
        obj.p.h.data.plotData('raw');
        obj.p.plotMarkers('raw','cpt');
        obj.p.plotMarkers('raw','user');
        %{
        every time that enter is pressed, the next incorrectly marked
        region is zoomed to in the figure. The times are output to the
        command window
        %}
        for k = 1:length(POI)
            left = POI(k) - 5;
            right = POI(k) + 5;
            
            data_in_range = obj.p.h.data.getDataFromTimeRange('raw', [left right]);
            maxy = max(data_in_range);
            miny = min(data_in_range);
            
            axis([left,right,miny - 1,maxy + 1])
            val = obj.p.h.data.getDataFromTimePoints('raw',POI(k));
            plot(POI(k),val,'rh','MarkerSize',12)
            pause
        end
        end
        function viewIncorrects(obj)
            %
            %   The result of this is confusing to look at /not helpful
            %
            
            figure
            data_class = obj.p.h.data;
            data_class.plotData('raw');
            
            start_times = obj.incorrect_starts;
            start_vals = data_class.getDataFromTimePoints('raw',start_times);
            end_times = obj.incorrect_ends;
            end_vals = data_class.getDataFromTimePoints('raw', end_times);
            
            u_start_times = obj.missed_starts;
            u_end_times = obj.missed_ends;
            u_start_vals = data_class.getDataFromTimePoints('raw',u_start_times);
            u_end_vals = data_class.getDataFromTimePoints('raw',u_end_times);          
            
            hold on
            plot(start_times,start_vals,'k*','MarkerSize',10);
            plot(end_times,end_vals,'k+','MarkerSize',10);
            plot(u_start_times,u_start_vals,'ko','MarkerSize',10);
            plot(u_end_times,u_end_vals,'ks','MarkerSize',10);

        end
    end
    
end

