

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

if ~isfield(ops, 'saveAllToExp') || ~ops.saveAllToExp

    if ops.verbose
        fprintf(ops.statusDestination, '  saving U... \n');
    end
    
    saveU(U, Upath, ops);
    saveDSAsMat(dataSummary, Upath, ops);    

end
    
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

        saveV(V, t, svdFilePath, ops);

        dsFilePath = [dat.expFilePath(ops.mouseName, ops.thisDate, existExps(n), 'calcium-widefield-svd', 'master') '_summary'];
        dataSummary.frameNumbers = allDS.frameNumbers(fileInds(n)+1:fileInds(n+1));
        dataSummary.imageMeans = allDS.imageMeans(fileInds(n)+1:fileInds(n+1));
        dataSummary.timeStamps = allDS.timeStamps(fileInds(n)+1:fileInds(n+1));
        if ops.doRegistration
            dataSummary.regDs = allDS.regDs(fileInds(n)+1:fileInds(n+1),:);
        end
        
        saveDSAsMat(dataSummary, dsFilePath, ops)                

        if isfield(ops, 'saveAllToExp') && ops.saveAllToExp
            if ops.verbose
                fprintf(ops.statusDestination, '  saving U... \n');
            end
            thisUpath = dat.expFilePath(ops.mouseName, ops.thisDate, existExps(n), 'calcium-widefield-svd', 'master');
            saveU(U, thisUpath(1:end-3), ops);
        end
        
    end
else % alignment didn't work, just save it like U, in the root directory
    if ops.verbose
        fprintf(ops.statusDestination, '  saving V... \n');
    end
    
    if isfield(ops, 'inclExpList') && numel(ops.inclExpList)==1
        % only gave one experiment. So even if alignment failed, we're
        % going to put the V in that subfolder
        vPath = fullfile(Upath, num2str(ops.inclExpList), 'SVD_Results');
    else
        vPath = fullfile(Upath, 'SVD_Results');
    end
    
    saveV(V, [], vPath, ops);
    
    if isfield(ops, 'saveAllToExp') && ops.saveAllToExp
        % we skipped saving U before, because we thought we'd save it to
        % the subdirectory. But the alignment didn't work so we're skipping
        % that idea. 
        if ops.verbose
            fprintf(ops.statusDestination, '  saving U... \n');
        end
        saveU(U, Upath, ops);
    end
end
    
% Register results files with database here??

if ops.verbose
    fprintf(ops.statusDestination,'done saving\n');
end


function saveU(U, Upath, ops)
if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
    writeUVtoNPY(U, [], fullfile(Upath, ['SVD_Results_U' ops.vids(ops.thisVid).name]), []);
else
    save(fullfile(Upath, 'SVD_Results_U'), '-v7.3', 'U');
end

function saveV(V, t, Vpath, ops)
if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
    writeUVtoNPY([], V, [], [Vpath '_V' ops.vids(ops.thisVid).name]);
    if ~isempty(t)
        writeNPY(t, [Vpath '_t' ops.vids(ops.thisVid).name '.npy']);
    end
else
    if ~isempty(t)
        save([Vpath '_V' ops.vids(ops.thisVid).name], '-v7.3', 'V', 't');
    else
        save([Vpath '_V' ops.vids(ops.thisVid).name], '-v7.3', 'V');
    end
end

function saveDSAsMat(dataSummary, Upath, ops)
    save(fullfile(Upath, ['dataSummary_' ops.vids(ops.thisVid).name]), 'dataSummary', 'ops');