obj = analysis.void_finder;
obj.loadExpt(2);
obj.loadAndFilterStream(1,1);
data = obj.filtered_cur_stream_data;
d1 = data.dif2;
d2 = d1.dif2;

figure
plot(data)
yyaxis right
plot(d2)

threshold = 3*10^-8;
d = d2.d;

[pks,locs] = findpeaks(d,'MinPeakHeight',threshold);
tic
dd = -d;
[mins,m_locs] = findpeaks(dd,'MinPeakHeight',threshold);
toc %currently takes 9 to 10 seconds per stream..... >:(
mins = -mins;
%[pks,locs,w,p] = findpeaks(d,'MinPeakHeight',threshold);


hold on
l = d2.ftime.getTimesFromIndices(locs);
lm = d2.ftime.getTimesFromIndices(m_locs);

plot(l,pks,'k*')
plot(lm, mins, 'r^')


threshold = 3*10^-8;
tic
tt = d2.calculators.eventz.findPeaks(d2,3,'MinPeakHeight',threshold);
toc
%takes 20 seconds to run



    
    
    
    
    
    
    
    
    
    
    
    
    