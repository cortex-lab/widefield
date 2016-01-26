

% script to run Marius's SVD

ops = setSVDParams();
mkdir(ops.localSavePath);

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
        [targetFrame, nFr] = generateRegistrationTarget(ops.fileBase, ops);
        ops.Nframes = nFr;
        toc
    else
        targetFrame = [];
    end    
    
    tic
    [frameNumbers, imageMeans, timeStamps, meanImage, imageSize, regDs] = ...
        loadRawToDat(ops.fileBase, datPath, ops, targetFrame);
    dataSummary.frameNumbers = frameNumbers;
    dataSummary.imageMeans = imageMeans;
    dataSummary.timeStamps = timeStamps;
    dataSummary.meanImage = meanImage;
    dataSummary.imageSize = imageSize;
    dataSummary.regDs = regDs;    
    save(fullfile(ops.localSavePath, 'dataSummary.mat'), 'dataSummary');
    toc
else
    load(fullfile(ops.localSavePath, 'dataSummary.mat'));
end

%% Second step, compute and save SVD
ops.Ly = dataSummary.imageSize(1); ops.Lx = dataSummary.imageSize(2); % not actually used in SVD function, just locally here

if ops.doRegistration
    minDs = min(dataSummary.regDs, [], 1);
    maxDs = max(dataSummary.regDs, [], 1);

    ops.yrange = ceil(maxDs(1)):floor(ops.Ly+minDs(1));
    ops.xrange = ceil(maxDs(2)):floor(ops.Lx+minDs(2));    
else
    ops.yrange = 1:ops.Ly; % subselection/ROI of image to use
    ops.xrange = 1:ops.Lx;
end
ops.Nframes = numel(dataSummary.timeStamps); % number of frames in whole movie

ops.mimg = dataSummary.meanImage;
if ops.hasASCIIstamp
    % remove the timestamp data
    ops.mimg(1:8,1:292) = 0;
elseif ops.hasBinaryStamp
    % remove the timstamp data
    ops.mimg(1,1:20) = 0;
end

ops.ResultsSaveFilename = [];

tic
[ops, U, Sv, V, totalVar] = get_svdcomps(ops);
toc

%%
svdViewer(U, Sv, V, ops.Fs, totalVar)


%% after reviewing the SVD, you want to do these:

% nKeep = 1200; % or however much you want
% U = U(:,:,1:nKeep); V = V(1:nKeep,:); Sv = Sv(1:nKeep);
% 
% saveSVD(ops, U, V, Sv, totalVar, dataSummary)