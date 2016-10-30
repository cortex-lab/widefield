

function quickMovieWithVids(mouseName, thisDate, expNum)

reposName = 'master';
nSV = 250;

expPath = dat.expPath(mouseName, thisDate, expNum, 'main', 'master');

[U, V, t] = quickLoadUVt(expPath, nSV);

load(dat.expFilePath(mouseName, thisDate, expNum, 'Timeline', 'master'));
traces = prepareTimelineTraces(Timeline);

auxVid = prepareAuxVids(mouseName, thisDate, expNum);

writeMovieLocation = fullfile(expPath, sprintf('widefield_%s_%s_%d', mouseName, thisDate, expNum));
movieWithTracesSVD(U, V, t, traces, writeMovieLocation, auxVid);
