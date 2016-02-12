

function saveSVD(ops, U, V, dataSummary)

[numExps, nFrPerExp, allT, existExps, alignmentWorked] = determineTimelineAlignments(ops, size(V,2));

if ops.verbose
    fprintf(ops.statusDestination, 'saving SVD results to server... \n');
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
    
    if isfield(ops, 'inclExpList') && numel(ops.inclExpList)==1
        % only gave one experiment. So even if alignment failed, we're
        % going to put the V in that subfolder
        vPath = fullfile(Upath, num2str(ops.inclExpList), 'SVD_Results_V');
    else
        vPath = fullfile(Upath, 'SVD_Results_V');
    end
    
    if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
        writeUVtoNPY([], V, [], vPath);
    else
        save(vPath, '-v7.3', 'V');
    end
end
    
% Register results files with database here??

if ops.verbose
    fprintf(ops.statusDestination,'done saving\n');
end
