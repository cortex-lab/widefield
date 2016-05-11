

function [numExps, nFrPerExp, allT, existExps, alignmentWorked] = determineTimelineAlignments(ops, nFrInV)
% Attempts to determine the timestamps of every movie frame in each
% experiment, in Timeline coordinates. It will do this by finding the
% timestamps of the camera exposure signals and seeing whether there are
% the correct numbers of these things. It will see whether it can get
% the right number using *all* experiments for that mouse and date; if not,
% it will see whether you specified expRefs in which case it will try to
% use just those expRefs. If neither of these results in the correct number
% of timestamps for movie frames that you have, the alignment has failed
% and no timestamps will be stored.
%
% ops should contain:
% - mouseName, str
% - thisDate, str
% - verbose, logical
% - rigName, str. Determines which signal is pulled out of Timeline for the
% timestamps, see function getStrobeTimes
% - frameMod, 1x2. Specifies which frames to use according to:
%    mod(frameNums, frameMod(1))==frameMod(2);
% - expRefs, cell array of strings, optional. Which expRefs to use.
% - inclExpList, array of integers, optional. Which expNums to use, just 
% an alternative to specifying expRefs.
%
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
%
% 

if ops.verbose
    fprintf(1, '  loading timeline files to determine alignments... \n');
end

nExp = 1;
nFrPerExp = [];

rootFolder = fileparts(dat.expPath(ops.mouseName, ops.thisDate, nExp, 'expInfo', 'master'));
d = dir(rootFolder);
numExps = length(d)-2;
if numExps<1
    if ops.verbose
        fprintf(1, '    no experiments found at %s\n', rootFolder);
    end
    numExps = 0;
    allT = {};
    existExps = [];
    alignmentWorked = false;
else
    
    if isfield(ops, 'inclExpList') && ~isempty(ops.inclExpList)
        expNums = ops.inclExpList;
    else
        expNums = cellfun(@str2num,{d(3:end).name});
    end
    
    if isfield(ops, 'expRefs') && ~isempty(ops.expRefs)
        expRefs = ops.expRefs;
    else
        expRefs = {};
        for e = 1:length(expNums)
            expRefs{e} = dat.constructExpRef(ops.mouseName, ops.thisDate, expNums(e));
        end
    end
    
    existExps = {};
    for e = 1:length(expRefs)
        timelinePath = dat.expFilePath(expRefs{e}, 'timeline', 'master');
        if exist(timelinePath)
            load(timelinePath)
            strobeTimes = getStrobeTimes(Timeline, ops.rigName);
            theseStrobeNumbers = 1:numel(strobeTimes);
%             theseStrobeNumbers = sum(nFrPerExp)+1:sum(nFrPerExp)+numel(strobeTimes);
            inclStrobes = mod(theseStrobeNumbers, ops.frameMod(1))==ops.frameMod(2); 
            nFrPerExp(e) = numel(strobeTimes(inclStrobes));
            allT{e} = strobeTimes(inclStrobes);
            existExps{end+1} = expRefs{e};            
        end
    end
    
    if sum(nFrPerExp)==nFrInV
        if ops.verbose
            fprintf(1, '  alignments correct. \n');
        end
        alignmentWorked = true;
        numExps = length(existExps);
        return;
    else         
        if ops.verbose
            fprintf(1, '  Incorrect number of frames in the movie relative to the number of strobes detected. Will save data as one V.\n');
        end
        alignmentWorked  = false;
        numExps = 0;
        allT = {};
        existExps = [];
    end
        
end