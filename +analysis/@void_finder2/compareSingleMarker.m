function compareSingleMarker(obj,start,stop)

[starts, stops] = obj.void_data.getMarkersInTimeRange(start,stop);

normalized_voids = obj.normalizeVoidData(starts, stops);

package_root = sl.stack.getPackageRoot;
file_path = fullfile(package_root,'+analysis','comparison_storage','comparison_data_15_filtered_final.mat');
load(file_path, '-mat', 'C')

 D = pdist2(normalized_voids, C); % returns the euclidean distances
 [~, A] = min(D,[],2);

end