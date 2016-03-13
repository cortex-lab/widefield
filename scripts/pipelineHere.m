

% New pipeline script. 
% As before, first set options variable "ops". 

load ops.mat; % this must be present in the current directory
diary(sprintf('svdLog_%s_%s.txt', ops.mouseName, ops.thisDate));

if ~exist(ops.localSavePath, 'dir')
    mkdir(ops.localSavePath);
end
save(fullfile(ops.localSavePath, 'ops.mat'), 'ops');

%% load all movies into flat binary files

for v = 1:length(ops.vids)
    
    ops.theseFiles = [];
    theseFiles = generateFileList(ops, v);
    
    ops.vids(v).theseFiles = theseFiles;
    ops.theseFiles = theseFiles;
    
    ops.vids(v).thisDatPath = fullfile(ops.localSavePath, ['vid' num2str(v) 'raw.dat']);
    
    dataSummary = loadRawToDat(ops, v);
    
    fn = fieldnames(dataSummary);
    for f = 1:length(fn)
        results.vids(v).(fn{f}) = dataSummary.(fn{f});
    end
    
    save(fullfile(ops.localSavePath, 'results.mat'), 'results');
end

%% do image registration? 
% Register the blue image and apply the registration to the other movies
if ops.doRegistration
    % if you want to do registration, we need to first determine the
    % target image.
    tic
    if ops.verbose
        fprintf(ops.statusDestination, 'determining target image\n');
    end
    [targetFrame, nFr] = generateRegistrationTarget(ops.fileBase, ops);
    ops.Nframes = nFr;
    toc
else
    targetFrame = [];
end

%% do hemodynamic correction?



%% perform SVD
for v = 1:length(ops.vids)
    fprintf(ops.statusDestination, ['svd on ' ops.vids(v).name]);
    
    ops.Ly = results.vids(v).imageSize(1); ops.Lx = results.vids(v).imageSize(2); % not actually used in SVD function, just locally here

    if ops.doRegistration
        minDs = min(dataSummary.regDs, [], 1);
        maxDs = max(dataSummary.regDs, [], 1);

        ops.yrange = ceil(maxDs(1)):floor(ops.Ly+minDs(1));
        ops.xrange = ceil(maxDs(2)):floor(ops.Lx+minDs(2));    
    else
        ops.yrange = 1:ops.Ly; % subselection/ROI of image to use
        ops.xrange = 1:ops.Lx;
    end
    ops.Nframes = numel(results.vids(v).timeStamps); % number of frames in whole movie

    ops.mimg = results.vids(v).meanImage;

    ops.ResultsSaveFilename = [];
    ops.theseFiles = ops.vids(v).theseFiles;
    ops.RegFile = ops.vids(v).thisDatPath;
    
    tic
    [ops, U, Sv, V, totalVar] = get_svdcomps(ops);
    toc
    
    results.vids(v).U = U;
    results.vids(v).V = V;
    results.vids(v).Sv = Sv;
    results.vids(v).totalVar = totalVar;
    
end

%% save

fprintf(1, 'saving locally\n');
save(fullfile(ops.localSavePath, 'results.mat'), 'results', '-v7.3');

if isfield(ops, 'emailAddress') && ~isempty(ops.emailAddress)
    save(['email_to_' ops.emailAddress], 'v');
end

save(fullfile(ops.localSavePath, 'done.mat'), []);
fprintf(1, 'done\n');
diary off;