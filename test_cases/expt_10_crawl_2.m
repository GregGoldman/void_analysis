%   goes through experiment 10 and collects all the voided vols and voided
%   times


% to see the results:
%{
        obj.data.plotData('raw');
        obj.void_data.plotMarkers('raw','cpt');
        obj.void_data.plotMarkers('raw','user');
%}

obj = analysis.void_finder2;
obj.data.loadExptOld(10);

results = cell(8,1);

correct_vv = [];
correct_vt = [];

missed_vv = [];
missed_vt = [];

incorrect_vv = [];
incorrect_vt = [];

for k = 1:8
    obj.data.getStreamOld(10,k);
    obj.findPossibleVoids();
    obj.void_data.compareUserCpt;
    comp_result = obj.void_data.comparison_result;

    temp_c_vt = obj.void_data.getVoidingTime(comp_result.final_start_times, comp_result.final_end_times);
    temp_c_vv = obj.void_data.getVV(comp_result.final_start_times, comp_result.final_end_times);
    
    temp_m_vt = obj.void_data.getVoidingTime(comp_result.user_missed_start, comp_result.user_missed_end);
    temp_m_vv = obj.void_data.getVV(comp_result.user_missed_start, comp_result.user_missed_end);
    
    temp_i_vt = obj.void_data.getVoidingTime(comp_result.cpt_wrong_start, comp_result.cpt_wrong_end);
    temp_i_vv = obj.void_data.getVV(comp_result.cpt_wrong_start, comp_result.cpt_wrong_end);

    correct_vv = union(correct_vv,temp_c_vv);
    correct_vt = union(correct_vt,temp_c_vt);
    
    missed_vv = union(missed_vv,temp_m_vv);
    missed_vt = union(missed_vt,temp_m_vt);
    
    incorrect_vv = union(incorrect_vv,temp_i_vv);
    incorrect_vt = union(incorrect_vt, temp_i_vt);
end
