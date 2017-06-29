function compareKMeans(obj)
%
%   obj.compareKMeans
%
%   The last set of testing on the voids does shape analysis.

starts = obj.void_data.updated_start_times;
stops = obj.void_data.updated_end_times;

normalized_voids = obj.normalizeVoidData(starts, stops);

package_root = sl.stack.getPackageRoot;
file_path = fullfile(package_root,'+analysis','comparison_storage','comparison_data_15_filtered_final.mat');
load(file_path, '-mat', 'C')

 D = pdist2(normalized_voids, C); % returns the euclidean distances
 [~, A] = min(D,[],2);
 %classification is now the number type of the voids we classified

 temp = cell(1,6);
 temp{1} = {'solid_void', [9 13]}; %remove
 temp{2} = {'resets',[2 5 17 20]};
 temp{3} = {'pos_solid',[1 3 4 8 11 14 19]};
 temp{4} = {'good',[7 12 15 18]};
 temp{5} = {'glitch', [6 10 16]}; %remove

 % TODO: need to compare with times!
 for k = 1:5
     cur = temp{k};
     B = A == cur{2};
     [rows, ~] = find(B);
     storage.(cur{1}) = sort(rows);
 end
 obj.possible_solid_start_times = starts(storage.pos_solid);
 obj.possible_solid_end_times = stops(storage.pos_solid);
 
 for k = [1,5] % allow for expansion
     cur = temp{k};
     obj.void_data.invalidateRanges(starts(storage.(cur{1})), stops(storage.(cur{1})),cur{1}, 'overwrite', false);
 end
end

