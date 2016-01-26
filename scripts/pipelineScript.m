

% script to run Marius's SVD

ops.mouseName = 'Dale'; 
ops.thisDate = '2016-01-24';
ops.rigName = 'bigrig';

fileBase = fullfile('L:\data\', ops.mouseName, ops.thisDate); % where the raw tif files are

datPath = fullfile('J:\', ops.mouseName, ops.thisDate, [ops.thisDate '.dat']); % file to create. 
% should be a fast, local drive. Need disk space equal to the size of the
% raw tif files. 

savePath = fullfile('J:\', ops.mouseName, ops.thisDate); % where to put results. 
mkdir(savePath);

ops.verbose = true;

ops.rawDataType = 'tif'; % or 'customPCO'
ops.hasASCIIstamp = true; % if your movie has legible timestamps in the corner
ops.hasBinaryStamp = true; % if the binary time stamps were turned on

ops.NavgFramesSVD = 7500; % number of frames to include in this computation
ops.nSVD = 2000; % number of SVD components to keep

ops.Fs = 50; % sampling rate of the movie

ops.useGPU = true;

ops.RegFile = datPath;

% registration parameters
ops.doRegistration = true;
ops.NimgFirstRegistration  = 750; % could use a smaller value if your movie is short? probably this is fine
ops.NiterPrealign          = 10; % increase this if "ErrorInitialAlign" doesn't go to zero
ops.SubPixel               = Inf; % leave alone
ops.RegPrecision = 'same'; % leave alone
ops.phaseCorrelation = true; % controls whitening - seems to work better with this on
ops.nRegisterBatchLimit = 750; % won't try to register more than this at once - for me I get memory errors with more than 750. 


%% First step, convert the tif files into a binary file. 
% Along the way we'll compute timestamps, meanImage, etc. 
% This is also the place to do image registration if desired, so that the
% binary file will contain the registered images.

if ~exist(datPath)
    
    if ops.doRegistration
        % if you want to do registration, we need to first determine the
        % target image. 
        tic
        fprintf(1, 'determining target image\n');
        [targetFrame, nFr] = generateRegistrationTarget(fileBase, ops);
        ops.Nframes = nFr;
        toc
    else
        targetFrame = [];
    end    
    
    tic
    [frameNumbers, imageMeans, timeStamps, meanImage, imageSize, regDs] = loadRawToDat(fileBase, datPath, ops, targetFrame);
    save(fullfile(savePath, 'dataSummary.mat'), 'frameNumbers', 'imageMeans', 'timeStamps', 'meanImage', 'imageSize', 'regDs');
    toc
else
    load(fullfile(savePath, 'dataSummary.mat'));
end

%% Second step, compute and save SVD
ops.Ly = imageSize(1); ops.Lx = imageSize(2); % not actually used in SVD function, just locally here

if ops.doRegistration
    minDs = min(regDs, [], 1);
    maxDs = max(regDs, [], 1);

    ops.yrange = ceil(maxDs(1)):floor(ops.Ly+minDs(1));
    ops.xrange = ceil(maxDs(2)):floor(ops.Lx+minDs(2));    
else
    ops.yrange = 1:ops.Ly; % subselection/ROI of image to use
    ops.xrange = 1:ops.Lx;
end
ops.Nframes = numel(timeStamps); % number of frames in whole movie

ops.mimg = meanImage;
if ops.hasASCIIstamp
    % remove the timestamp data
    ops.mimg(1:8,1:292) = 0;
elseif ops.hasBinaryStamp
    % remove the timstamp data
    ops.mimg(1,1:20) = 0;
end

ops.ResultsSaveFilename = fullfile(savePath, 'SVDresults.mat');

tic
[ops, U, Sv, V, totalVar] = get_svdcomps(ops);
toc

%%
svdViewer(U, Sv, V, ops.Fs, totalVar)


%% after reviewing the SVD, you want to do these:

nKeep = 1200; % or however much you want
U = U(:,:,1:nKeep); V = V(1:nKeep,:); Sv = Sv(1:nKeep);

% here there should [will] be code to split the frames up into experiments
% by looking at exposure strobes from timeline. For now:
nExp = 1;
nFrPerExp = [];
timelinePath = dat.expFilePath(ops.mouseName, ops.thisDate, nExp, 'timeline', 'master');
while exist(timelinePath)
    load(timelinePath)
    strobeTimes = getStrobeTimes(Timeline, ops.rigName);
    nFrPerExp(nExp) = numel(strobeTimes);
    nExp = nExp+1;
    timelinePath = dat.expFilePath(ops.mouseName, ops.thisDate, nExp, 'timeline', 'master');
end

assert(sum(nFrPerExp)==size(V,2), 'Incorrect number of frames in the movie relative to the number of strobes detected. Will not save data to server.');

% upload results to server
filePath = dat.expPath(ops.mouseName, ops.thisDate, 1, 'widefield', 'master');
Upath = filePath(1:end-1); % root for the date - we'll put U (etc) and data summary here
if ~exist(Upath)
    mkdir(Upath);
end
svdFilePath = dat.expFilePath(ops.mouseName, ops.thisDate, 1, 'calcium-widefield-svd', 'master');
save(svdFilePath, '-v7.3', 'U', 'Sv', 'V', 'ops', 'totalVar'); 
save(fullfile(filePath, 'dataSummary'), 'frameNumbers', 'imageMeans', 'timeStamps', 'meanImage', 'imageSize', 'regDs');
