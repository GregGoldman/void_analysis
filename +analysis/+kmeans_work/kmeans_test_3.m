%kmeans_test_3.m
tic
num_blocks = 12;
normalized_to_save = zeros(0,num_blocks);
idx = 0; % move through that array

obj = analysis.void_finder2;

for l = 6:11
fprintf('Cur_expt: %0u \n', l)

obj.data.loadExptOld(l);

if l ~= 6
    obj.data.loaded_expts{l-1} = []; 
end

for k = 1:8
fprintf('Cur stream: %0u \n', k)
obj.data.getStreamOld(l,k);
obj.findPossibleVoids();
starts = obj.void_data.updated_start_times;
stops = obj.void_data.updated_end_times;

received = obj.normalizeVoidData(starts,stops);
normalized_to_save(end+(1:length(starts)) ,1:num_blocks) = received;

end
end
toc
%-------------------------------------

[I C] = kmeans(normalized_to_save, 15);
%plot(C','LineWidth',2);
%idxs = 1:15;
%temp = mat2cell(idxs',ones(15,1));
%temp2 = cellfun(@num2str,temp, 'UniformOutput', false);
%legend(temp2)

figure
num_I = sum(I == 1:15);
total_analyzed = sum(num_I);

for k = 1:15
subplot(4,4,k)
plot(C(k,:)')
p =  num_I(k) / total_analyzed;

title(sprintf('%0u , %0.1f %%',k, p*100))
end

subplot(4,4,16)
hist(I)


comments = {'each row of C is a cluster. Each column of C is a dimension in the data points';...
    'plot plots the columns of y wrt their indices. have to plot C transpose to see data trends'};
comparison_data.I = I;
comparison_data.C = C;
comparison_data.norm = normalized_to_save;
comparison_data.comments = comments;
 save('comparison_data_15_filtered_fixed','-struct', 'comparison_data')
