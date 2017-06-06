% load_nss_test.M
% see notocord.file


%!!! IMPORTANT: event markers 2 goes with channel  01 !!!

%test cases:
file_path = 'C:\Data\GSK\Phase 2\Control Group\161107\161107_Control_group_ analyzed.nss';
wtf = notocord.file(file_path);


% the continuous_stream class with fs, dt, n_samples, duration
stream1 = wtf.getStream('Analog Channel  01');
% calibrated, placed animals, start and end times
mark1 = wtf.getStream('Event markers 1');

stream2 = wtf.getStream('Analog Channel  01');
mark2 = wtf.getStream('Event markers 2'); 
temp = stream2.getData();
plot(temp)
hold on

%{
filter = sci.time_series.filter.butter(1,5, 'low'); %order, freq, type
temp2 = temp.filter(filter);
plot(temp2)
%}

filter = sci.time_series.filter.butter(1,4, 'low') %order, freq, type
temp3 = temp.filter(filter);
hold on 
plot(temp3)


start_datetime = temp.time.start_datetime;
t = mark2.times - start_datetime;
% t is now the fraction of a day since the start
% multiply by 86400 seconds in a day to convert to seconds to match up with
% the locations of the markers in the graph.

t2 = 86400 * t;
y = 0.*mark2.times -0.5;
hold on
plot(t2,y,'k*');


%{
summary of algorithm:
loop through at a given time interval which should be based on the average
time of a void. 

there needs to be a limiter on how many times a void can occur over a given
duration of time. maybe voids which occur very soon after other voids can
be grouped into a different array


%}


% guesswork for typical void duration: 
% anywhere from 4 seconds to 30 seconds
% step size: 20 seconds

step_size = 20/temp3.time.dt; % a number of data points
n_steps = floor(temp3.time.n_samples / step_size); 
raw_data = temp3.d;
dt = temp3.time.dt;

%these are the threshold values

thresh = [0.15 0.1 0.05 0.025];
guess = cell(0,0); %where we will store guesses at voids (weakest)

%{
        strongest   medium    weak     weakest
            -          -        -         - 
%}
time_blocker = 50; %anything less than this amnt of time is pretty unlikely to be a new void.
time_since_last_void = 0;
prev_val = raw_data(1);
void_found = 0; 

for i = 1:n_steps
    if ((time_since_last_void > time_blocker)&&(~void_found))
    cur_val = raw_data(step_size*i);

        for k = 1:length(thresh) %loop thru the cols (the thresholds)
            if (cur_val >= (thresh(k)*prev_val + prev_val))
                %       multiply by the dt to get the time we are at
                guess{end+1,k} = i*step_size*dt;
                void_found = 1;
                time_since_last_void = 0;
                break
            else
                void_found = 0;
            end
        end
    else
        void_found = 0;
    end
    prev_val = raw_data(step_size*i);
    time_since_last_void = time_since_last_void + step_size * dt; 
end


for k = 1:4
col = guess(:,k);
index = cellfun('isempty',col)
markers = col(~index)

markers = cell2mat(markers);


yy = 0.*markers -0.5 - 0.5*k;

hold on
plot(markers,yy, '*')
end

% need to plot the time intervals to make my life easier:
tt = 0: step_size*dt :n_steps*dt*step_size;
ff = tt*0 +1;

hold on 
plot(tt,ff,'k.')


