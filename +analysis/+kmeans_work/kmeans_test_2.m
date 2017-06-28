%kmeans_test_2.m
tic
num_blocks = 12;
normalized_to_save = zeros(0,num_blocks - 2);
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

normalized_to_save(end+(1:length(starts)) ,num_blocks - 2) = 0;
for j = 1:length(starts)
    start = starts(j);
    stop = stops(j);

    idx = idx + 1;

    
    data = obj.data.cur_stream_data.subset.fromStartAndStopTimes(start,stop,'n_parts', num_blocks); %cell
    data2 = data{1}; % dereference
    mean_vals = mean(data2);
    offset_removed = mean_vals - mean_vals(1);
    normalized = offset_removed./(offset_removed(end) - offset_removed(1));
    
    normalized = normalized(2:end-1);
    %remove start and end which are always 0 and 1
    
    normalized_to_save(idx,:) = normalized; 
end

end

end
toc
%-------------------------------------
%{
[I C] = kmeans(normalized_to_save, 10)
%plot(C','LineWidth',2)
idxs = 1:10;
temp = mat2cell(idxs',ones(10,1));
temp2 = cellfun(@num2str,temp, 'UniformOutput', false);
legend(temp2)


figure
num_I = sum(I == 1:15);
total_analyzed = sum(num_I);


for k = 1:10
subplot(4,3,k)
plot(C(k,:)')
p =  num_I(k) / total_analyzed;

title(sprintf('%0u , %0.1f %%',k, p*100))
end

subplot(4,3,11)
hist(I)


comments = {'each row of C is a cluster. Each column of C is a dimension in the data points';...
    'plot plots the columns of y wrt their indices. have to plot C transpose to see data trends'};

plot(C(1,:)');

comparison_data.I = I;
comparison_data.C = C;
comparison_data.norm = normalized_to_save;
comparison_data.comments = comments;
%}
%---------------------------------------------------

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
 save('comparison_data_15','-struct', 'comparison_data')


%-------------------------------------------------------------------
%{
[I C] = kmeans(normalized_to_save, 20);
%plot(C','LineWidth',2);
%idxs = 1:20;
%temp = mat2cell(idxs',ones(20,1));
%temp2 = cellfun(@num2str,temp, 'UniformOutput', false);
%legend(temp2)

figure
num_I = sum(I == 1:20);
total_analyzed = sum(num_I);

for k = 1:20
subplot(4,5,k)
plot(C(k,:)')
p =  num_I(k) / total_analyzed;

title(sprintf('%0u , %0.1f %%',k, p*100))
end


%{
comments = {'each row of C is a cluster. Each column of C is a dimension in the data points';...
    'plot plots the columns of y wrt their indices. have to plot C transpose to see data trends'};
comparison_data.I = I;
comparison_data.C = C;
comparison_data.norm = normalized_to_save;
comparison_data.comments = comments;
%}
%}
%---------------------------------------
 %testing the calssification
 
 
 data_1 = normalized_to_save(1,:);
 D = pdist2(data_1, C); % returns the euclidean distances
 temp = D == min(D);
 classification = find(temp);
 %classification is now the number in our dataset of the one it goes with.
 




