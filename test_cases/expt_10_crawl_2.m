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

    %force to be column vectors
    correct_vv = [correct_vv,temp_c_vv(:)'];
    correct_vt = [correct_vt,temp_c_vt(:)'];
    
    missed_vv = [missed_vv,temp_m_vv(:)'];
    missed_vt = [missed_vt,temp_m_vt(:)'];
    
    incorrect_vv = [incorrect_vv,temp_i_vv(:)'];
    incorrect_vt = [incorrect_vt, temp_i_vt(:)'];
    
    
    results{k} = comp_result;
end

clear temp_c_vt temp_c_vv temp_i_vt temp_i_vv temp_m_vt temp_m_vv


figure
%voiding volume vs voiding time

plot(correct_vt, correct_vv, 'g*', 'markersize',5)
hold on
plot(incorrect_vt,incorrect_vv, 'b*', 'markersize', 5)
plot(missed_vt, missed_vv,'r*', 'markersize', 5)
xlabel('Voiding Time (seconds)')
ylabel('Voided Volume (ml)');
legend('Correct', 'Incorrect', 'Missed')

%{
save('correct', 'correct_vt','correct_vv');
save('incorrect','incorrect_vt','incorrect_vv')
save('missed','missed_vt', 'missed_vv')


%}


%{
fixing errors:
obj.plotMarkers('raw', 'user')
%find the error

% 1st time
t  = end_markers(end);
end_markers(end) = start_markers(end-1);
end_markers(end+1) = t;
start_markers(end-1) = [];
length(start_markers);
length(end_markers);
obj.u_start_times = start_markers;
obj.u_end_times = end_markers;
dbcont
%obj.plotMarkers('raw', 'user')


%second time
start_markers(end) = [];
obj.u_start_times = start_markers;
dbcont
%}

