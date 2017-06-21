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
        
        correct_starts
        matched_u_starts
        incorrect_starts
        missed_starts
        
        correct_ends
        matched_u_ends
        incorrect_ends
        missed_ends

    end
    
    methods
        function obj = comparison_result(p)
            obj.p = p;
            obj.runComparison();
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
            obj.missed_starts = u_start_times(temp2)
            

            [c,d] = ismembertol(end_times, u_end_times, tolerance, 'DataScale',1);
            obj.correct_ends = end_times(c);
            obj.matched_u_ends = u_end_times(d(d~=0));
            
            obj.incorrect_ends = end_times(~c);
            temp = 1:length(u_end_times);
            temp2 = setdiff(temp,d(d~=0));
            obj.missed_ends = u_end_times(temp2);
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

