tic
obj = analysis.void_finder;
obj.loadExpt(2);
obj.loadStream(1,1);
obj.filterCurStream();
obj.findPossibleVoids();
toc