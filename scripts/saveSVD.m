

function saveSVD(ops, U, V, Sv, totalVar, dataSummary)

fprintf(1, 'saving SVD results to server... \n');

fprintf(1, '  loading timeline files to determine alignments... \n');
nExp = 1;
nFrPerExp = [];
timelinePath = dat.expFilePath(ops.mouseName, ops.thisDate, nExp, 'timeline', 'master');
while exist(timelinePath)
    load(timelinePath)
    strobeTimes = getStrobeTimes(Timeline, ops.rigName);
    nFrPerExp(nExp) = numel(strobeTimes);
    allT{nExp} = strobeTimes;
    nExp = nExp+1;
    timelinePath = dat.expFilePath(ops.mouseName, ops.thisDate, nExp, 'timeline', 'master');
end

assert(sum(nFrPerExp)==size(V,2), 'Incorrect number of frames in the movie relative to the number of strobes detected. Will not save data to server.');

fprintf(1, '  alignments correct. \n');

numExps = nExp-1;

% upload results to server
filePath = dat.expPath(ops.mouseName, ops.thisDate, 1, 'widefield', 'master');
Upath = fileparts(filePath); % root for the date - we'll put U (etc) and data summary here
if ~exist(Upath)
    mkdir(Upath);
end

fprintf(1, '  saveing U... \n');
save(fullfile(Upath, 'SVD_Results_U'), '-v7.3', 'U', 'Sv', 'ops', 'totalVar');
save(fullfile(Upath, 'dataSummary'), 'dataSummary');

allDS = dataSummary;
allV = V;    
fileInds = cumsum([0 nFrPerExp]);

for n = 1:numExps
    fprintf(1, '  saveing V for exp %d... \n', n);
    filePath = dat.expPath(ops.mouseName, ops.thisDate, n, 'widefield', 'master');
    mkdir(filePath);
    svdFilePath = [dat.expFilePath(ops.mouseName, ops.thisDate, n, 'calcium-widefield-svd', 'master') '_V'];
    V = allV(:,fileInds(n)+1:fileInds(n+1));
    t = allT{n};
    save(svdFilePath, '-v7.3', 'V', 't'); 
    
    dsFilePath = [dat.expFilePath(ops.mouseName, ops.thisDate, n, 'calcium-widefield-svd', 'master') '_summary'];
    dataSummary.frameNumbers = allDS.frameNumbers(fileInds(n)+1:fileInds(n+1));
    dataSummary.imageMeans = allDS.imageMeans(fileInds(n)+1:fileInds(n+1));
    dataSummary.timeStamps = allDS.timeStamps(fileInds(n)+1:fileInds(n+1));
    dataSummary.regDs = allDS.regDs(fileInds(n)+1:fileInds(n+1),:);
    save(dsFilePath, 'dataSummary');
    
end

fprintf(1,'done \n');