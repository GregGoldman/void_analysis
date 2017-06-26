classdef analysis_options < handle
    %
    %   analysis.analysis_options
    %
    %   Stores the options for filtering the data using void_finder2
    properties
        accel_thresh %d2 processing
       
        %some noise stuff
        calibration_period
        min_void_time
        noise_multiplier
        spike_time_window
        spike_magnitude_tolerance
        
        %d1 processing
        speed_thresh
        d1_spike_window
        glitch_time_window
        evap_time_window
        reset_time_window
        
        % filtering
        order 
        frequency
        type
    end
    
    methods
        function obj = analysis_options(varargin)
           obj.accel_thresh = 2*10^-8;
           obj.calibration_period = 90;
           obj.min_void_time = 0.5;
           obj.noise_multiplier = 0.25;
           obj.speed_thresh = 3*10^-3;
           obj.d1_spike_window = 10;
           obj.glitch_time_window = 15;
           obj.evap_time_window = 10;
           obj.reset_time_window = 10;
           obj.spike_time_window = 10;
           obj.spike_magnitude_tolerance = 0.1;
           obj.order = 2;
           obj.frequency = 0.2;
           obj.type = 'low';
           
           
           obj = sl.in.processVarargin(obj, varargin);
        end
        function updateProperties(obj,varargin)
            %
            %   updateProperties(obj,varargin)
            %
            %   Examples:
            %   obj.updateProperties('accel_thresh', 1.*10^-8, 'spike_magnitude_tolerance', 0.05);
            
            
            obj = sl.in.processVarargin(obj,varargin);
        end
    end
    
end

