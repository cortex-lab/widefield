

function saveSVD(ops, U, V, dataSummary)

[numExps, nFrPerExp, allT, existExps, alignmentWorked] = determineTimelineAlignments(ops, size(V,2));

if ops.verbose
    fprintf(1, 'saving SVD results to server... \n');
end

% upload results to server

filePath = dat.expPath(ops.mouseName, ops.thisDate, 1, 'main', 'master');
Upath = fileparts(filePath); % root for the date - we'll put U (etc) and data summary here
if ~exist(Upath)
    mkdir(Upath);
end

if ops.verbose
    fprintf(1, '  saving U... \n');
end

saveU(U, dataSummary.meanImage, Upath, ops);
save(fullfile(Upath, ['dataSummary_' ops.vidName]), 'dataSummary', 'ops');
    
if alignmentWorked

    allV = V;    
    fileInds = cumsum([0 nFrPerExp]);

    for n = 1:numExps
        if ops.verbose
            fprintf(1, '  saving V for exp %d... \n', existExps(n));
        end
        filePath = dat.expPath(ops.mouseName, ops.thisDate, existExps(n), 'main', 'master');
        mkdir(filePath);
        
        V = allV(:,fileInds(n)+1:fileInds(n+1));
        t = allT{n};

        saveV(V, t, filePath, ops);
        
    end
else % alignment didn't work, just save it like U, in the root directory
    if ops.verbose
        fprintf(1, '  saving V... \n');
    end
    
    vPath = Upath;
    
    saveV(V, [], vPath, ops);
    
end
    
% Register results files with database here??

if ops.verbose
    fprintf(1,'done saving\n');
end


function saveU(svdSpatialComponents, meanImage, Upath, ops)

fn = fullfile(Upath, ['svdSpatialComponents_' ops.vidName]);
fnMeanImage = fullfile(Upath, ['meanImage_' ops.vidName]);

if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
    writeUVtoNPY(svdSpatialComponents, [], fn, []);
    writeNPY(meanImage, [fnMeanImage '.npy']);
else
    save(fn, '-v7.3', 'svdSpatialComponents');
    save(fnMeanImage, 'meanImage');
end

function saveV(svdTemporalComponents, t, Vpath, ops)

fn = fullfile(Vpath, ['svdTemporalComponents_' ops.vidName]);
fnT = fullfile(Vpath, ['svdTemporalComponents_' ops.vidName '.timestamps']);

if isfield(ops, 'saveAsNPY') && ops.saveAsNPY
    writeUVtoNPY([], svdTemporalComponents, [], fn);
    if ~isempty(t)
        writeNPY(t, [fnT '.npy']);
    end
else
    if ~isempty(t)
        save(fn, '-v7.3', 'svdTemporalComponents', 't');
    else
        save(fn, '-v7.3', 'svdTemporalComponents');
    end
end
