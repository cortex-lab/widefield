

function saveSVD(ops, U, V, dataSummary)

if ops.verbose
    fprintf(ops.statusDestination, 'saving SVD results to server... \n');

    fprintf(ops.statusDestination, '  loading timeline files to determine alignments... \n');
end
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

if sum(nFrPerExp)~=size(V,2)
    fprintf(ops.statusDestination, '  Incorrect number of frames in the movie relative to the number of strobes detected. Will not save data to server.\n');
    alignmentWorked  = false;
else
    if ops.verbose
        fprintf(ops.statusDestination, '  alignments correct. \n');
    end
    alignmentWorked = true;
end

numExps = nExp-1;

% upload results to server
filePath = dat.expPath(ops.mouseName, ops.thisDate, 1, 'widefield', 'master');
Upath = fileparts(filePath); % root for the date - we'll put U (etc) and data summary here
if ~exist(Upath)
    mkdir(Upath);
end

if ops.verbose
    fprintf(ops.statusDestination, '  saving U... \n');
end
if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
    writeUVtoNPY(U, [], fullfile(Upath, 'SVD_Results_U.npy'), []);
else
    save(fullfile(Upath, 'SVD_Results_U'), '-v7.3', 'U');
end
save(fullfile(Upath, 'dataSummary'), 'dataSummary', 'ops');

if alignmentWorked

    allDS = dataSummary;
    allV = V;    
    fileInds = cumsum([0 nFrPerExp]);

    for n = 1:numExps
        if ops.verbose
            fprintf(ops.statusDestination, '  saving V for exp %d... \n', n);
        end
        filePath = dat.expPath(ops.mouseName, ops.thisDate, n, 'widefield', 'master');
        mkdir(filePath);
        svdFilePath = dat.expFilePath(ops.mouseName, ops.thisDate, n, 'calcium-widefield-svd', 'master');

        V = allV(:,fileInds(n)+1:fileInds(n+1));
        t = allT{n};

        if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
            writeUVtoNPY([], V, [], [svdFilePath '_V.npy']);
            writeNPY(t, [svdFilePath '_t.npy']);
        else
            save([svdFilePath '_V'], '-v7.3', 'V', 't'); 
        end

        dsFilePath = [dat.expFilePath(ops.mouseName, ops.thisDate, n, 'calcium-widefield-svd', 'master') '_summary'];
        dataSummary.frameNumbers = allDS.frameNumbers(fileInds(n)+1:fileInds(n+1));
        dataSummary.imageMeans = allDS.imageMeans(fileInds(n)+1:fileInds(n+1));
        dataSummary.timeStamps = allDS.timeStamps(fileInds(n)+1:fileInds(n+1));
        dataSummary.regDs = allDS.regDs(fileInds(n)+1:fileInds(n+1),:);
        save(dsFilePath, 'dataSummary');

    end
else % alignment didn't work, just save it like U, in the root directory
    if ops.verbose
        fprintf(ops.statusDestination, '  saving V... \n');
    end
    if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
        writeUVtoNPY([], V, [], fullfile(Upath, 'SVD_Results_V.npy'));
    else
        save(fullfile(Upath, 'SVD_Results_V'), '-v7.3', 'U');
    end
end
    
% Register results files with database here??

if ops.verbose
    fprintf(ops.statusDestination,'done \n');
end