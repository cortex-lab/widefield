

function [numExps, nFrPerExp, allT, existExps, alignmentWorked] = determineTimelineAlignments(ops, nFrInV)
% Should return:
% - numExps, 1x1, the number of experiments that were found and aligned (0
% if alignment fails)
% - nFrPerExp, 1 x numExps, the number of frames in each experiment
% - allT, 1 x numExps cell array, each cell contains a 1 x nFrPerExp(n)
% array of the timestamps(in Timeline coordinates) of each frame
% - existExps, 1 x numExps, the number of each experiment (specifying the
% subfolder to save to)
% - alignmentWorked, 1 x 1 logical, will determine whether it saves V to
% subfolders or not

if ops.verbose
    fprintf(ops.statusDestination, '  loading timeline files to determine alignments... \n');
end

nExp = 1;
nFrPerExp = [];

rootFolder = fileparts(dat.expPath(ops.mouseName, ops.thisDate, nExp, 'expInfo', 'master'));
d = dir(rootFolder);
numExps = length(d)-2;
if numExps<1
    if ops.verbose
        fprintf(ops.statusDestination, '    no experiments found at %s\n', rootFolder);
    end
    numExps = 0;
    allT = {};
    existExps = [];
    alignmentWorked = false;
else
    expNums = cellfun(@str2num,{d(3:end).name});
    if isfield(ops, 'inclExpList') && ~isempty(ops.inclExpList)
        expNums = ops.inclExpList;
    end
    
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
    
    if sum(nFrPerExp)~=nFrInV
        if ops.verbose
            fprintf(ops.statusDestination, '  Incorrect number of frames in the movie relative to the number of strobes detected. Will save data as one V.\n');
        end
        alignmentWorked  = false;
        numExps = 0;
        allT = {};
        existExps = [];
    else
        if ops.verbose
            fprintf(ops.statusDestination, '  alignments correct. \n');
        end
        alignmentWorked = true;
        numExps = length(existExps);
    end
    
    
end