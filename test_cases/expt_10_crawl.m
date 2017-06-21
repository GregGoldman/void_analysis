% expt_10_crawl:
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
 
 u_vv = [];
 u_vt = [];
 
 c_vv = [];
 c_vt = [];

 results = cell(8,1);
 
for k = 1:8
 obj.data.getStreamOld(10,k);
 obj.findPossibleVoids();
 
 obj.void_data.processHumanMarkedPts;
 obj.void_data.processCptMarkedPts;
 obj.void_data.compareUserCpt;
 obj.void_data.comparison_result;

 temp_u_vv = obj.void_data.u_vv;
 temp_u_vt = obj.void_data.u_vt;
 temp_c_vv = obj.void_data.c_vv;
 temp_c_vt = obj.void_data.c_vt;
  
 u_vv(end+ (1:length(temp_u_vv))) = temp_u_vv;
 u_vt(end+ (1:length(temp_u_vt))) = temp_u_vt;
 c_vv(end+ (1:length(temp_c_vv))) = temp_c_vv;
 c_vt(end+ (1:length(temp_c_vt))) = temp_c_vt;

 results{k} = obj.void_data.comparison_result;
end

clear temp_u_vt temp_c_vt temp_c_vv temp_u_vv
clear k

figure
plot(u_vt,u_vv,'ko','MarkerSize',10);
hold on
plot(c_vt,c_vv,'ro','MarkerSize',10);
legend('user', 'cpt')

