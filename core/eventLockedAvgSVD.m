
function [avgPeriEventV, winSamps, periEventV, sortedLabels] = eventLockedAvgSVD(U, V, t, eventTimes, eventLabels, calcWin)
% function [avgPeriEventV, periEventV] = eventLockedAvgSVD(U, V, t, eventTimes, eventLabels, calcWin)
%
% Inputs: 
% - U: Ypix x Xpix x nSV
% - V: nSV x nTimePoints
% - t: 1 x nTimePoints, the time points of each sample in V
% - eventTimes: 1 x nEvents, the time of each event. 
% - eventLabels: 1 x nEvents, the label of each event, e.g. the contrast
% value or some text label. If this is a cell array, the "tuning curve"
% will be plotted evenly spaced; if numeric array then these will be the
% x-axis values of the tuning curve
% - window: 1 x 2, the start and end times relative to the event
%
% Outputs:
% - avgPeriEventV: nEventTypes x nSV x nTimePoints, average temporal
% components across all events of each type
% - winSamps: labels for the time axis, relative to the event times
% - periEventV: nEvents x nSV x nTimePoints, the temporal components around
% each event
% - sortedLabels: the labels of the rows of periEventV

t = t(:)'; % make row
eventTimes = eventTimes(:)';
[eventTimes, ii] = sort(eventTimes);
sortedLabels = eventLabels(ii);

% Ypix = size(U,1);
% Xpix = size(U,2);
% nSV = size(U,3);
nSV = size(V,1);

eLabels = unique(eventLabels);
nConditions = length(eLabels);

Fs = 1/median(diff(t));
winSamps = calcWin(1):1/Fs:calcWin(2);
periEventTimes = bsxfun(@plus, eventTimes', winSamps); % rows of absolute time points around each event
periEventV = zeros(nSV, length(eventTimes), length(winSamps));
for s = 1:nSV
    periEventV(s,:,:) = interp1(t, V(s,:), periEventTimes);
end

avgPeriEventV = zeros(nConditions, nSV, length(winSamps));
for c = 1:nConditions
    if iscell(eventLabels)
        thisCondEvents = cellfun(@(x)strcmp(x,eLabels(c)),sortedLabels);
    else
        thisCondEvents = sortedLabels==eLabels(c);
    end
    avgPeriEventV(c,:,:) = squeeze(nanmean(periEventV(:,thisCondEvents,:),2));
end

periEventV = permute(periEventV, [2 1 3]);