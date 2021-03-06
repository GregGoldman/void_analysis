classdef data < handle
    %
    %   Class:
    %   analysis.data
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
        parent                       %analysis.void_finder2
        
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
        
        rect_filtered_data
        
    end
    methods
        function obj = data(parent)
            obj.parent = parent;  % the void_finder class which holds it
            obj.findDefaultExptFiles();
           
            %{
            obj.save_location = 'C:\Data\nss_matlab_objs';
            obj.findDefaultExptFiles();
            %}
        end
        function loadExptByString(obj, expt_id)
            %
            %   obj.loadExptByString(obj,expt_id)
            %
            %   Inputs
            %   -------
            %   expt_id: string
            %       the date of the experiment as a string (i.e. '161109')
            %
            %   TODO: incorporate optional inputs, dealing with multiple
            %   files of same ID, etc...
            %
            %   examples: loadExptByString('161109')
 
            list_result = obj.expt_file_list_result;            
            file_names = list_result.file_names;
            file_paths = list_result.file_paths;
            
            temp = strncmp(file_names, expt_id, length(expt_id));
            obj.loadExpt(file_paths{temp});
        end
        function findDefaultExptFiles(obj)
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
        function findExptFiles(obj, file_path)
            %
            %   obj.findExptFiles(file_path)
            %
            %   given the file path of a folder, search that folder and
            %   subfolders for .nss files
            %   Inputs:
            %   ----------
            %   - file_path: string of file path to search
            
            obj.save_location = file_path;
            FILE_EXTENSION = '.nss';
            if ~exist(file_path,'dir')
                %type options = dba.getOptions for more details
                %TODO: We should make it easier to edit from here ...
                %   - might be best to tie into the options code
                %   - dba.options.errors.missingFile() <- possible name
                error_msg = sl.error.getMissingFileErrorMsg(file_path);
                error(error_msg)
            end
            obj.expt_file_list_result = sl.dir.getList(file_path,'recursive',-1,'extension',FILE_EXTENSION);      
        end
        function loadExpt(obj, file_path)
            %
            %   obj.loadExpt(file_path)
            %
            %   Loads experiment objects
            %   populates the end+1 index in obj.loaded_expts
            %
            %   inputs:
            %   ------------
            %   - file_path: path of expt to load
            
            obj.cur_expt = notocord.file(file_path);
        end
        function loadExptOld(obj,index)
            %       OUT OF DATE
            %   obj.loadExptOld(index)
            %
            %   Loads experiment objects
            %   populates the index in obj.loaded_expts
            %
            %   inputs:
            %   ------------
            %   - index: integer index in the list of file paths of
            %           obj.expt_file_list_result.file_paths
            
            temp = length(obj.expt_file_list_result.file_paths);
            obj.loaded_expts = cell(1,temp);
            obj.loaded_expts{index} = notocord.file(obj.expt_file_list_result.file_paths{index});
        end
        function getStream(obj, stream_num)
            %   obj.getStream(stream_num)
            %
            %   Load, filter, and differentiate (twice) the stream
            %   indicated by the input argument from the current experiment
            %
            %   inputs:
            %   ------------
            %   - stream_num: integer index of the stream number to
            %                 load 
            
            obj.cur_stream_idx = stream_num;
            
            h__markersAndStream(obj,stream_num);
            h__filter(obj);
            obj.d1 = obj.filtered_cur_stream_data.dif2Loop;
            obj.d2 = obj.d1.dif2Loop; 
        end
        function getStreamOld(obj, expt_idx, stream_num)
            %       OUT OF DATE
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
            
            h__markersAndStream(obj,stream_num);
            h__filter(obj);
            
            obj.d1 = obj.filtered_cur_stream_data.dif2Loop;
            obj.d2 = obj.d1.dif2Loop;
        end
        function plotData(obj,option,varargin)
            %
            %   plotData(obj,option, *axes)
            %
            %   Inputs:
            %   -------
            %   option:
            %       - 'filtered'
            %       - 'raw'
            %   Optional Inputs:
            %   axes: 
            %       Axes handle to plot into 
            
            
            
            if nargin == 3 
                switch lower(option)
                    case 'filtered'
                        plot(obj.filtered_cur_stream_data,'axes',varargin{1});
                    case 'raw'
                        plot(obj.cur_stream_data,'axes',varargin{1});
                    otherwise
                        error('unrecognized option (data format)')
                end
            else
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
        end
        function d = getCurStreamData(obj)
            %
            %   obj.getCurStreamData()
            %
            %   Simply returns the data array
            
            d = obj.cur_stream_data.d;
        end
        function vals = getDataFromTimePoints(obj,source,time_points)
            %
            %   obj.getDataFromTimePoints(time_range)
            %
            %   Given an array of points in time, attempts to find the
            %   closest indices in the data and returns those values only
            %
            %   inputs:
            %   ----------
            %   - source: 'filtered' or 'raw'
            %   - time_range: double array of time points
            %
            switch lower(source)
                case 'filtered'
                    d = obj.filtered_cur_stream_data.d;
                case 'raw'
                    d = obj.cur_stream_data.d;
                otherwise
                    error('unrecognized data source')
            end
            
            idxs = obj.cur_stream_data.time.getNearestIndices(time_points);
            vals = d(idxs);
        end
        function [vals, varargout] = getDataFromTimeRange(obj,source,time_range)
            %
            %   obj.getDataFromTimeRange(source, time_range)
            %
            %   Given an array of points in time, attempts to find the
            %   closest indices in the data and returns those values and
            %   all in between
            %
            %   Inputs
            %   -------
            %   - source: 'filtered' or 'raw'
            %   - time_range: double array of time points which specify the
            %      edges of a range
            %
            %   Outputs
            %   -------
            %   vals: the values from the time range and source
            %   varargout: returns the time array as well
            %
            %   Examples:
            %   [vals, times] = obj.getDataFromTimeRange('raw', time_range)
 
            
            switch lower(source)
                case 'filtered'
                    d = obj.filtered_cur_stream_data.d;
                case 'raw'
                    d = obj.cur_stream_data.d;
                otherwise
                    error('unrecognized data source')
            end
            
            % if time_range is a single point, we just want the data at
            % that specific point
            
            % if time_range is two points, we want the data within that
            % range
            
            if length(time_range) == 2
                start_idx = obj.cur_stream_data.time.getNearestIndices(time_range(1));
                end_idx = obj.cur_stream_data.time.getNearestIndices(time_range(2));
                idx_range = start_idx:end_idx;
            elseif length(time_range) == 1
                idx_range = obj.cur_stream_data.time.getNearestIndices(time_range);
            else
                error('unrecognized time range, NYI')
            end
            
            vals = d(idx_range);
            
            if nargout == 2
            % return the time array as well
            varargout{1} = obj.cur_stream_data.time.getTimesFromIndices(idx_range);
            end
        end
    end
end
function h__filter(obj)
ORDER = obj.parent.options.order;
FREQUENCY = obj.parent.options.frequency;
TYPE = obj.parent.options.type;

filter = sci.time_series.filter.butter(ORDER,FREQUENCY,TYPE);
obj.filtered_cur_stream_data = obj.cur_stream_data.filter(filter);
end
function h__markersAndStream(obj, stream_num)
%
%   TODO: what if there are no markers or we don't want the markers?
%

obj.parent.void_data.cur_markers_idx = [stream_num+1, stream_num + 9];
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
if (count(1) == 9) %this is definitely NOT a good way to do this...
    error('no end markers, NYI')
end
obj.parent.void_data.user_start_marker_obj = obj.cur_expt.getStream(['Event markers ', sprintf('%d',obj.parent.void_data.cur_markers_idx(1))]);
obj.parent.void_data.user_end_marker_obj = obj.cur_expt.getStream(['Event markers ', sprintf('%d',obj.parent.void_data.cur_markers_idx(2))]);
           
obj.cur_stream = obj.cur_expt.getStream(['Analog Channel  0', sprintf('%d',obj.cur_stream_idx)]);
obj.cur_stream_data = obj.cur_stream.getData();
            
start_datetime = obj.cur_stream_data.time.start_datetime;
st = obj.parent.void_data.user_start_marker_obj.times - start_datetime;
et = obj.parent.void_data.user_end_marker_obj.times - start_datetime;
% t is now the fraction of a day since the start
% multiply by 86400 seconds in a day to convert to seconds to match up with
% the locations of the markers in the graph.

obj.parent.void_data.u_start_times = 86400 * st;
obj.parent.void_data.u_end_times =  86400 * et;
end