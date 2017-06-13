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
        
        cpt_success_idx
        %  indices in obj.updated_start_times (or end_times) which have
        %  both start and end matched with the user-found values
        
        u_success_idx
        %  the corresponding indices in the user markers to those points
        %  in cpt_success_idx
        
        cpt_wrong_in_user_marks_idx
        %  indices in the user-marked points which the computer did
        %  not find within an appropriate tolerance
        
        cpt_wrong_in_cpt_marks_idx
        %  indices in the computer-marked points which have no
        %  corresponding correct user markers
        
    end
    
    methods
        function obj = comparison_result(p,cpt_success_idx,u_success_idx,cpt_wrong_in_user_marks_idx,cpt_wrong_in_cpt_marks_idx)
            obj.p = p;
            obj.cpt_success_idx = cpt_success_idx;
            obj.u_success_idx = u_success_idx;
            obj.cpt_wrong_in_user_marks_idx = cpt_wrong_in_user_marks_idx;
            obj.cpt_wrong_in_cpt_marks_idx = cpt_wrong_in_cpt_marks_idx;
        end
        function plotCorrect(obj)
            %   TODO: return plot handle!!
            
            hold off
            plot(obj.p.cur_stream_data)
            
            % plots the markers indicated by the user on the orignal data
            
            data = obj.p.cur_stream_data.d;
            
            cpt_start_times = obj.p.updated_start_times(obj.cpt_success_idx);
            cpt_end_times = obj.p.updated_end_times(obj.cpt_success_idx);
            
            cpt_start_data_idx = obj.p.cur_stream_data.time.getNearestIndices(cpt_start_times);
            cpt_end_data_idx = obj.p.cur_stream_data.time.getNearestIndices(cpt_end_times);
            
            cpt_start_y = data(cpt_start_data_idx);
            cpt_end_y = data(cpt_end_data_idx);
            
            %--------------------------------
            u_start_times = obj.p.u_start_times(obj.u_success_idx);
            u_end_times = obj.p.u_end_times(obj.u_success_idx);
            
            u_start_data_idx = obj.p.cur_stream_data.time.getNearestIndices(u_start_times);
            u_end_data_idx = obj.p.cur_stream_data.time.getNearestIndices(u_end_times);
            
            u_start_y = data(u_start_data_idx);
            u_end_y = data(u_end_data_idx);
            
            %-------------------------------
            
            hold on
            plot(cpt_start_times,cpt_start_y,'k*', 'MarkerSize', 10);
            plot(cpt_end_times,cpt_end_y, 'k+',  'MarkerSize', 10);
            
            plot(u_start_times,u_start_y, 'ko', 'MarkerSize', 10);
            plot(u_end_times,u_end_y, 'ks', 'MarkerSize', 10);
        end
        function plotIncorrect(obj)
            
        end
    end
    
end

