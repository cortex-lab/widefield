

function saveSVD(ops, U, V, dataSummary)

if ops.verbose
    fprintf(ops.statusDestination, 'saving SVD results to server... \n');

    fprintf(ops.statusDestination, '  loading timeline files to determine alignments... \n');
end

nExp = 1;
nFrPerExp = [];

rootFolder = fileparts(dat.expPath(ops.mouseName, ops.thisDate, nExp, 'expInfo', 'master'));
d = dir(rootFolder);
numExps = length(d)-2;
if numExps<1
    fprintf(1, '    no experiments found at %s\n', rootFolder);
    numExps = 0;
else
    expNums = cellfun(@num2str,{d(3:end).name});
    existExps = [];
    for e = 1:length(expNums)
        timelinePath = dat.expFilePath(ops.mouseName, ops.thisDate, expNums(e), 'timeline', 'master');
        if exist(timelinePath)
            load(timelinePath)
            strobeTimes = getStrobeTimes(Timeline, ops.rigName);
            nFrPerExp(e) = numel(strobeTimes);
            allT{e} = strobeTimes;
            existExps(end+1) = expNums(e);            
        end
    end
    
    if sum(nFrPerExp)~=size(V,2)
        fprintf(ops.statusDestination, '  Incorrect number of frames in the movie relative to the number of strobes detected. Will save data as one V.\n');
        alignmentWorked  = false;
        numExps = length(existExps);
    else
        if ops.verbose
            fprintf(ops.statusDestination, '  alignments correct. \n');
        end
        alignmentWorked = true;
        numExps = 0;
    end
    
    
end

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
    writeUVtoNPY(U, [], fullfile(Upath, 'SVD_Results_U'), []);
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
            fprintf(ops.statusDestination, '  saving V for exp %d... \n', existExps(n));
        end
        filePath = dat.expPath(ops.mouseName, ops.thisDate, existExps(n), 'widefield', 'master');
        mkdir(filePath);
        svdFilePath = dat.expFilePath(ops.mouseName, ops.thisDate, existExps(n), 'calcium-widefield-svd', 'master');

        V = allV(:,fileInds(n)+1:fileInds(n+1));
        t = allT{n};

        if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
            writeUVtoNPY([], V, [], [svdFilePath '_V']);
            writeNPY(t, [svdFilePath '_t.npy']);
        else
            save([svdFilePath '_V'], '-v7.3', 'V', 't'); 
        end

        dsFilePath = [dat.expFilePath(ops.mouseName, ops.thisDate, existExps(n), 'calcium-widefield-svd', 'master') '_summary'];
        dataSummary.frameNumbers = allDS.frameNumbers(fileInds(n)+1:fileInds(n+1));
        dataSummary.imageMeans = allDS.imageMeans(fileInds(n)+1:fileInds(n+1));
        dataSummary.timeStamps = allDS.timeStamps(fileInds(n)+1:fileInds(n+1));
        if ops.doRegistration
            dataSummary.regDs = allDS.regDs(fileInds(n)+1:fileInds(n+1),:);
        end
        save(dsFilePath, 'dataSummary');

    end
else % alignment didn't work, just save it like U, in the root directory
    if ops.verbose
        fprintf(ops.statusDestination, '  saving V... \n');
    end
    if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
        writeUVtoNPY([], V, [], fullfile(Upath, 'SVD_Results_V'));
    else
        save(fullfile(Upath, 'SVD_Results_V'), '-v7.3', 'V');
    end
end
    
% Register results files with database here??

if ops.verbose
    fprintf(ops.statusDestination,'done \n');
end