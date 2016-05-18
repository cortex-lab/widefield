
try % putting the entire script in a try-catch block to we can return even if it fails

% New pipeline script. 

addpath(genpath('/mnt/zserver/Code/Rigging/main'));
addpath(genpath('/mnt/zserver/Code/Rigging/cb-tools')); % for some dat package helper functions
addpath('/mnt/data/svdinput'); % for the local override of dat.paths
addpath(genpath('/mnt/data/svdinput/npy-matlab'));
addpath(genpath('/apps/widefield'));

load ops.mat; % this must be present in the current directory
diaryFilename = sprintf('svdLog_%s_%s.txt', ops.mouseName, ops.thisDate);
diary(diaryFilename);

ops.localSavePath = pathForThisOS(ops.localSavePath);
for v = 1:length(ops.vids)
    ops.vids(v).fileBase = pathForThisOS(ops.vids(v).fileBase);
end

if ~exist(ops.localSavePath, 'dir')
    mkdir(ops.localSavePath);
end
save(fullfile(ops.localSavePath, 'ops.mat'), 'ops');

%% copy all the files from the camera computers to the local computer

remoteDataSource = ops.remoteDataSource;
for d = 1:length(remoteDataSource)
    r = remoteDataSource{d};
    loc = ops.localDataDest{d};
    if ops.verbose
        fprintf(1, 'copying files for data source %d from: \n   %s \nto: \n   %s\n', d, r, loc);
    end
    [success, message, messageID] = copyfile(pathForThisOS(fullfile(r, '*.tif')), pathForThisOS(loc));
    if ops.verbose && success
        fprintf(1, 'success. deleting files from remote.\n');
        delete(fullfile(r, '*.tif'));
    elseif success
        delete(fullfile(r, '*.tif'));
    elseif ops.verbose
        fprintf(1, 'error copying: %s.\n', message);
    end
end
    

%% load all movies into flat binary files

for v = 1:length(ops.vids)
    
    clear loadDatOps;
    
    ops.theseFiles = [];
    theseFiles = generateFileList(ops, v);
    
    ops.vids(v).theseFiles = theseFiles;
    loadDatOps.theseFiles = theseFiles;
        
    ops.vids(v).thisDatPath = fullfile(ops.localSavePath, ['vid' num2str(v) 'raw.dat']);
    loadDatOps.datPath = ops.vids(v).thisDatPath;    
    loadDatOps.verbose = ops.verbose;
    loadDatOps.rawDataType = ops.rawDataType;
    
    loadDatOps.frameMod = ops.vids(v).frameMod;
    loadDatOps.hasASCIIstamp = ops.hasASCIIstamp;
    loadDatOps.hasBinaryStamp = ops.hasBinaryStamp;
    loadDatOps.binning = ops.binning;
    loadDatOps.flipudVid = ops.vids(v).flipudVid;
    
    dataSummary = loadRawToDat(loadDatOps);
    
    fn = fieldnames(dataSummary);
    results(v).name = ops.vids(v).name;
    for f = 1:length(fn)
        results(v).(fn{f}) = dataSummary.(fn{f});
    end
    
    save(fullfile(ops.localSavePath, 'results.mat'), 'results');
end

%% do image registration? 
% Register a master image and apply the registration to the other movies
if ops.doRegistration

    regOps.NimgFirstRegistration = ops.NimgFirstRegistration;
    regOps.NiterPrealign = ops.NiterPrealign;
    regOps.SubPixel = ops.SubPixel;
    regOps.RegPrecision = ops.RegPrecision;
    regOps.phaseCorrelation = ops.phaseCorrelation;
    regOps.nRegisterBatchLimit = ops.nRegisterBatchLimit;
    regOps.useGPU = ops.useGPU;
    
    v = ops.masterVid;
    datPath = ops.vids(v).thisDatPath;
    
    % determine target frame for the master video
    if ops.verbose
        fprintf(1, 'determining target for image registration\n');
    end
    imageSize = results(v).imageSize;
    nFr = results(v).nFrames;
    targetFrame = determineTargetFrame(datPath, imageSize, nFr, regOps);
    
    
    % figure out the shifts required to align to it
    if ops.verbose
        fprintf(1, 'determining registration shifts\n');
    end
    ds = alignToTarget(datPath, targetFrame, imageSize, nFr, regOps);
    
    % now shift every video to match
    if ops.verbose
        fprintf(1, 'applying registration\n');
    end
    for v = 1:length(ops.vids)
        results(v).registrationDs = ds;
        if ops.verbose
            fprintf(1, '  to vid %d\n', v);
        end
        datPath = ops.vids(v).thisDatPath;
        regPath = fullfile(ops.localSavePath, ['vid' num2str(v) 'reg.dat']);
        ops.vids(v).thisRegPath = regPath;
        registerDatFile(datPath, regPath, ds, results(v).imageSize, results(v).nFrames, regOps);
    end
    
end

%% do hemodynamic correction?
% - don't do this here - it likely works just as well on SVD representation
% (though that has not been explicitly tested). 



%% perform SVD

svdOps.NavgFramesSVD = ops.NavgFramesSVD;
svdOps.verbose = ops.verbose;
svdOps.nSVD = ops.nSVD;
svdOps.useGPU = ops.useGPU;

for v = 1:length(ops.vids)
    fprintf(1, ['svd on ' ops.vids(v).name '\n']);
    
    svdOps.Ly = results(v).imageSize(1); svdOps.Lx = results(v).imageSize(2); % not actually used in SVD function, just locally here

    if ops.doRegistration
        minDs = min(results(v).registrationDs, [], 1);
        maxDs = max(results(v).registrationDs, [], 1);

        svdOps.yrange = ceil(maxDs(1)):floor(svdOps.Ly+minDs(1));
        svdOps.xrange = ceil(maxDs(2)):floor(svdOps.Lx+minDs(2));    
        
        svdOps.RegFile = ops.vids(v).thisRegPath;
    else
        svdOps.yrange = 1:svdOps.Ly; % subselection/ROI of image to use
        svdOps.xrange = 1:svdOps.Lx;
        svdOps.RegFile = ops.vids(v).thisDatPath;
    end
    svdOps.Nframes = results(v).nFrames; % number of frames in whole movie

    svdOps.mimg = results(v).meanImage;
        
    tic
    [U, Sv, V, totalVar] = get_svdcomps(svdOps);
    toc   
    
    % what to do about this? Need to save all "vids" - where?
    fprintf(1, 'attempting to save to server\n');
    
    saveOps.rigName = ops.vids(v).rigName;
    saveOps.verbose = ops.verbose;
    saveOps.mouseName = ops.mouseName;
    saveOps.thisDate = ops.thisDate;
    saveOps.vidName = ops.vids(v).name;
    saveOps.saveAsNPY = ops.saveAsNPY;
    saveOps.frameMod = ops.vids(v).frameMod;
    saveOps.expRefs = ops.expRefs;
    
    results(v).Sv = Sv;
    results(v).totalVar = totalVar;
    saveSVD(saveOps, U, V, results(v))
    
    results(v).U = U;
    results(v).V = V;
    
end

%% save

fprintf(1, 'saving all results locally at %s\n', fullfile(ops.localSavePath, 'results.mat'));
save(fullfile(ops.localSavePath, 'results.mat'), 'results', '-v7.3');


fprintf(1, 'done\n');
diary off;
rng('shuffle');

if isfield(ops, 'emailAddress') && ~isempty(ops.emailAddress)        
                                                                                                                                                                         messages = {'I am the SVD master.', 'Decomposing all day, decomposing all night.', 'Yes! Yes! Woooooooooo!', 'Wha wha whaaat?? It happened! It really happened!!'};    
    % Send the email
    mailFromLugaro(ops.emailAddress, [ops.mouseName '_' ops.thisDate ' finished.'], ...
        messages{randi(numel(messages),1)}, diaryFilename);
    
end

% save(fullfile(ops.localSavePath, 'done.mat'), []);
% Instead, copy the folder of raw files into the /mnt/data/toArchive folder
destFolder = fullfile('/mnt/bigdrive/', ops.mouseName, ops.thisDate);
mkdir(destFolder);
movefile(fullfile('/mnt/data/svdinput/', ops.mouseName, ops.thisDate, '*'), destFolder);

% clean up dat files
for v = 1:length(ops.vids)
    if isfield(ops.vids(v), 'thisDatPath') && exist(ops.vids(v).thisDatPath)
        delete(ops.vids(v).thisDatPath);
    end
    if isfield(ops.vids(v), 'thisRegPath') && exist(ops.vids(v).thisRegPath)
        delete(ops.vids(v).thisRegPath);
    end
end


catch me
    diary off;
if isfield(ops, 'emailAddress') && ~isempty(ops.emailAddress)
    mailFromLugaro(ops.emailAddress, [ops.mouseName '_' ops.thisDate ' got an error :('], ...
        me.message, diaryFilename);
end

end 