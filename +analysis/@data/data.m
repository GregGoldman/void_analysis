classdef data < handle
    %
    %   Class:
    %   analysis.data_helper
    %
    %   A class which is responsible for:
    %   Loading data
    %   Getting the Stream objects
    %   Filtering/derivatives/etc
    %   This class is a propery of analysis.void_finder
    %
    %   Examples:
    %   -----------------------------------
    %   TODO
    
    properties
        h                       % analysis.data_helper
        
        save_location
        expt_file_list_result
        loaded_expts            % cell of notocord.file
        cur_expt
        
        cur_stream              % notocord.continuous_stream
        cur_stream_idx          % scalar
        cur_stream_data         % sci.time_series.data
        filtered_cur_stream_data
        d1
        d2
        
    end
    
    methods
        function obj = analysis.data(h)
            obj.h = h;  % the void_finder class which holds it
            
            obj.save_location = 'C:\Data\nss_matlab_objs';
            obj.findExptFiles(obj);
        end
        function findExptFiles(obj)
            %
            %   obj.findExptFiles()
            %
            %   Finds the list of files that we have to work with and
            %   stores them to obj.expt_file_list_result
            %
            %   TODO: update the dba.files.raw.finder class to be able to
            %   handle this with a varargin for FILE_EXTENSION
            
            FILE_EXTENSION = '.nss';
            RAW_DATA_ROOT = dba.getOption('raw_data_root');
            if ~exist(RAW_DATA_ROOT,'dir')
                %type options = dba.getOptions for more details
                %TODO: We should make it easier to edit from here ...
                %   - might be best to tie into the options code
                %   - dba.options.errors.missingFile() <- possible name
                error_msg = sl.error.getMissingFileErrorMsg(RAW_DATA_ROOT);
                error(error_msg)
            end
            obj.expt_file_list_result = sl.dir.getList(RAW_DATA_ROOT,'recursive',-1,'extension',FILE_EXTENSION);
        end
        function loadExpt(obj,index)
            %
            %   obj.loadExpt(index)
            %
            %   Loads experiment objects
            %   populates the end+1 index in obj.loaded_expts
            %
            %   inputs:
            %   ------------
            %   - index: integer index in the list of file paths of
            %           obj.expt_file_list_result.file_paths
            
            temp = length(obj.expt_file_list_result.file_paths);
            obj.loaded_expts = cell(1,temp)
            obj.loaded_expts{index} = notocord.file(obj.expt_file_list_result.file_paths{index});
            function getStream(obj, expt_idx, stream_num)
                %
                %   obj.getStream(expt_idx, stream_num)
                %
                %   Load, filter, and differentiate (twice) the stream
                %   indicated by the input arguments (see below)
                %
                %   inputs:
                %   ------------
                %   - expt_idx: integer index of the experiment to load
                %               from obj.loaded_expts
                %   - stream_num: integer index of the stream number to
                %                 load from the experiment indicated by
                %                 expt_idx
                
                obj.cur_expt = obj.loaded_expts{expt_idx};
                obj.cur_stream_idx = stream_num;
                
                h__markers(obj,stream_num);
                h__filter(obj);
                obj.d1 = obj.filtered_cur_stream_data.dif2;
                obj.d2 = obj.d1.dif2;
            end
        end
        function plotData(obj,option)
            %
            %   inputs:
            %   -----------------------
            %   - option: 'filtered' or 'raw'
            %       determines if the data plotted should come from the
            %       filtered dataset or from the raw dataset
            %
            %   TODO:
            %   ----------
            %   - return figure handles
            %
            figure
            switch lower(option)
                case 'filtered'
                    plot(obj.filtered_cur_stream_data);
                case 'raw'
                    plot(obj.cur_stream_data);
                otherwise
                    error('unrecognized option (data format)')
            end
        end
        function d = getCurStreamData(obj)
            %
            %   obj.getCurStreamData()
            %
            %   Simply returns the data array
            
            d = obj.cur_stream_data.d;
        end
        function vals = getDataFromTimeRange(obj,time_range)
            %
            %   obj.getDataFromTimeRange(time_range)
            %
            %   Given an array of points in time, attempts to find the
            %   closest indices in the data and returns those values
            %
            %   inputs:
            %   ----------
            %   - time_range: double array of time points
            %
            
            d = obj.cur_stream_data.d;
            idx = obj.cur_stream_data.time.getNearestIndices(time_range);
            vals = d(idx);
        end
        function idxs = getNearestIndices(obj,time_range)
            
        end
        function times = getTimesFromIndices(obj,idxs)
            
        end
    end
end
function h__filter(obj)

ORDER = 2;
FREQUENCY = 0.2;
TYPE = 'low';
filter = sci.time_series.filter.butter(ORDER,FREQUENCY,TYPE);
obj.filtered_cur_stream_data = obj.cur_stream_data.filter(filter);

end
function h__markers(obj, stream_num)

obj.h.void_data.cur_markers_idx = [stream_num+1, stream_num + 9];
% need to figure out if there are both start and end markers

chan_info = table2cell(obj.cur_expt.chan_info);
temp = chan_info(:,3);
[B, I, J] = unique(temp);
for ind = 1:length(B)
    count(ind) = length(find(J==ind));
end
% if count == 9, then there are only event markers, not start
% and stop markers. If it is 17(?) then it has start and stop
% markers  % it seems that only the very first experiment file that I have
% has only one marker per void
if (count(1) == 9) %this is definitely not a good way to do this...
    error('no end markers, NYI')
end
obj.h.void_data.user_start_marker_obj = obj.cur_expt.getStream(['Event markers ', sprintf('%d',cur_markers_idx(1))]);
obj.h.void_data.user_end_marker_obj = obj.cur_expt.getStream(['Event markers ', sprintf('%d',cur_markers_idx(2))]);

start_datetime = obj.cur_stream_data.time.start_datetime;
st = obj.user_start_marker_obj.times - start_datetime;
et = obj.user_end_marker_obj.times - start_datetime;
% t is now the fraction of a day since the start
% multiply by 86400 seconds in a day to convert to seconds to match up with
% the locations of the markers in the graph.

obj.h.void_data.u_start_times = 86400 * st;
obj.h.void_data.u_end_times =  86400 * et;
end