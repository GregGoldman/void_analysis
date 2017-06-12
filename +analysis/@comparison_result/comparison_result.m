classdef comparison_result < handle
    %
    %   Class:
    %   analysis.comparison_result 
    %
    %   stores thre results of comparing the computer-identified voids to
    %   the user-identified voids
    
    properties
        missed_idx
        %index in the array of user markers which the computer did not find
        
        wrong_idx
        %index in the array of computer markers which are not matched with
        %the computer
        
        cpt_success_idx
        %index in the array of computer markers which are matched with the
        %user markers
        
        u_success_idx
        %index in the array of user markers which match with computer
        %markers
    end
    
    methods
        function obj = comparison_result(missed_idx,wrong_idx,cpt_success_idx,u_success_idx)
            obj.missed_idx = missed_idx;
            obj.wrong_idx = wrong_idx;
            obj.cpt_success_idx = cpt_success_idx;
            obj.u_success_idx = u_success_idx;
            
        end 
    end
    
end

