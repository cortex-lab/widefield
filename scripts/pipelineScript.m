

% script to run Marius's SVD. To use it, first copy setSVDParams.m into the
% root directory of this repository and rename it to mySetSVDparams.m. Edit
% that file with the options you want. Then run:

% >> ops = mySetSVDparams();

% Then run this script. 




%% First step, convert the tif files into a binary file. 
% Along the way we'll compute timestamps, meanImage, etc. 
% This is also the place to do image registration if desired, so that the
% binary file will contain the registered images.

if ~exist(ops.localSavePath, 'dir')
    mkdir(ops.localSavePath);
end
save(fullfile(ops.localSavePath, 'ops.mat'), 'ops');

if ~exist(ops.datPath)
    
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
    
    tic
    [frameNumbers, imageMeans, timeStamps, meanImage, imageSize, regDs] = ...
        loadRawToDat(ops.datPath, ops, targetFrame);
    dataSummary.frameNumbers = frameNumbers;
    dataSummary.imageMeans = imageMeans;
    dataSummary.timeStamps = timeStamps;
    dataSummary.meanImage = meanImage;
    dataSummary.imageSize = imageSize;
    dataSummary.regDs = regDs;    
    dataSummary.registrationTargetFrame = targetFrame;
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

ops.ResultsSaveFilename = [];

tic
[ops, U, Sv, V, totalVar] = get_svdcomps(ops);
toc
dataSummary.Sv = Sv;
dataSummary.totalVar = totalVar;

% save results locally first in case something goes wrong with getting them
% to the server
save(fullfile(ops.localSavePath, 'SVD_results'), '-v7.3', 'U', 'Sv', 'V', 'totalVar', 'dataSummary', 'ops');
saveSVD(ops, U, V, dataSummary)

fprintf(ops.statusDestination, 'all done, success!\n');

if ops.statusDestination~=1 
    % close the file
    fclose(ops.statusDestination);
end


%%
% svdViewer(U, Sv, V, ops.Fs, totalVar)

