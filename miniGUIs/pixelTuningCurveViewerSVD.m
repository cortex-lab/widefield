

function pixelTuningCurveViewerSVD(U, V, t, eventTimes, eventLabels, window)
% function pixelTuningCurveViewerSVD(U, V, t, eventTimes, eventLabels, window)
%
% Displays: A) the image of the brain for a certain time point and
% condition; B) the traces across time for a certain pixel and all
% conditions; C) the value at that pixel and time point across conditions
%
% Allows the user to modify which pixel, time point, and condition are
% shown through simple click actions or keyboard shortcuts. 
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
% Controls:
% - click in the three plots to change pixel, time point, and condition
% respectively
% - Use left/right arrow keys to change time point (hold down to play)
% - Use up/down arrow keys to change condition
% - Use i/j/k/l to navigate pixels
% - Use c to reset display limits
% - Use mouse scroll wheel to zoom/recenter display limits


t = t(:)'; % make row
eventTimes = eventTimes(:)';

Ypix = size(U,1);
Xpix = size(U,2);
nSV = size(U,3);

eLabels = unique(eventLabels);
nConditions = length(eLabels);

fprintf(1, 'pre-calculation...\n');
Fs = 1/median(diff(t));
winSamps = window(1):1/Fs:window(2);
periEventTimes = bsxfun(@plus, eventTimes', winSamps); % rows of absolute time points around each event
periEventV = zeros(nSV, length(eventTimes), length(winSamps));
for s = 1:nSV
    periEventV(s,:,:) = interp1(t, V(s,:), periEventTimes);
end

avgPeriEventV = zeros(nConditions, nSV, length(winSamps));
for c = 1:nConditions
    if iscell(eventLabels)
        thisCondEvents = cellfun(@(x)eq(x,eLabels(c)),eventLabels);
    else
        thisCondEvents = eventLabels==eLabels(c);
    end
    avgPeriEventV(c,:,:) = squeeze(mean(periEventV(:,thisCondEvents,:),2));
end
fprintf(1, 'done.\n');

allData.U = U;
allData.V = avgPeriEventV;
allData.winSamps = winSamps;
allData.eLabels = eLabels;

ud.Ypix = Ypix;
ud.Xpix = Xpix;
ud.nConditions = nConditions;
ud.nTimePoints = length(winSamps);
ud.thisTimePoint = 1; 
ud.thisPixel = [round(Ypix/2) round(Xpix/2)];
ud.thisCond = 1;
ud.cax = [-1 1];
if iscell(eventLabels)
    ud.condXvals = 1:nConditions;
else
    ud.condXvals = eLabels;
end
ud.initialized = false;

f = figure; 

set(f, 'UserData', ud);
set(f, 'KeyPressFcn', @(f,k)tcViewerCallback(f, k, allData));

showTC(allData, f);



function tcViewerCallback(f, keydata, allData)

ud = get(f, 'UserData');


switch keydata.Key
    case 'rightarrow'
        ud.thisTimePoint = ud.thisTimePoint+1; 
        if ud.thisTimePoint>ud.nTimePoints; ud.thisTimePoint = ud.nTimePoints; end;
    case 'leftarrow'
        ud.thisTimePoint = ud.thisTimePoint-1;
        if ud.thisTimePoint<1; ud.thisTimePoint = 1; end;
    case 'uparrow'
    	ud.thisCond = ud.thisCond+1;
        if ud.thisCond>ud.nConditions; ud.thisCond = 1; end
    case 'downarrow'
        ud.thisCond = ud.thisCond-1;    
        if ud.thisCond<1; ud.thisCond = ud.nConditions; end
    case 'i'
        ud.thisPixel(1) = ud.thisPixel(1)+5;
        if ud.thisPixel(1)>ud.yPix; ud.thisPixel(1) = ud.yPix; end
    case 'k'
        ud.thisPixel(1) = ud.thisPixel(1)-5;
        if ud.thisPixel(1)<1; ud.thisPixel(1) = 1; end
    case 'j'
        ud.thisPixel(2) = ud.thisPixel(2)-5;
        if ud.thisPixel(2)<1; ud.thisPixel(2) = 1; end
    case 'l'
        ud.thisPixel(2) = ud.thisPixel(2)+5;
        if ud.thisPixel(2)>ud.xPix; ud.thisPixel(2) = ud.xPix; end
    case 'hyphen' % scale cax down
        ud.cax = ud.cax*0.75;
        caxis(ud.brainAx, ud.cax);
        ylim(ud.tcAx, ud.cax);
        ylim(ud.traceAx, ud.cax);

    case 'equal' % scale cax up
        ud.cax = ud.cax*1.25;
        caxis(ud.brainAx, ud.cax);
        ylim(ud.tcAx, ud.cax);
        ylim(ud.traceAx, ud.cax);

end
set(f, 'UserData', ud);
showTC(allData, f);

function tcViewerCallbackClick(f, keydata, allData)
f
keydata
allData
figHand = get(f, 'Parent');
ud = get(figHand, 'UserData');


clickX = keydata.IntersectionPoint(1);
clickY = keydata.IntersectionPoint(2);

switch get(f, 'Tag')
    case 'brainImage'
        ud.thisPixel = round([clickY clickX]);
    case 'traces'
        ud.thisTimePoint = min(length(ud.nTimePoints), find(ud.nTimePoints>clickX,1));
    case 'tuningCurves'
        dists = abs(clickX-ud.condXvals);
        ud.thisCond = find(dists==min(dists),1);
        
end

set(figHand, 'UserData', ud);
showTC(allData, figHand);



function showTC(allData, figHand)
ud = get(figHand, 'UserData');
nConditions = ud.nConditions;
nTimePoints = ud.nTimePoints;
thisTimePoint = ud.thisTimePoint;
thisCond = ud.thisCond;
thisPixel = ud.thisPixel;
cax = ud.cax;

% V here is nConditions x nSV x nTimePoints
thisBrainImage = svdFrameReconstruct(allData.U, squeeze(allData.V(thisCond,:,thisTimePoint))');

thisPixelU = squeeze(allData.U(thisPixel(1),thisPixel(2),:));
theseTraces = zeros(nConditions, nTimePoints);
for c = 1:nConditions
    theseTraces(c,:) = thisPixelU'*squeeze(allData.V(thisCond,:,:));
end

thisTC = theseTraces(:,thisTimePoint);

colors = copper(nConditions); colors = colors(:, [3 2 1]);

if ~ud.initialized
    % plot the brain image with a marker where the selected pixel is
    ud.brainAx = subplot(1,4,1:2); 
    ud.brainIm = imagesc(thisBrainImage); set(ud.brainIm, 'HitTest', 'off');
    hold on;
    ud.brainPixelHand = plot(thisPixel(2), thisPixel(1), 'go'); set(ud.brainPixelHand, 'HitTest', 'off');
    hold off;
    colormap(colormap_blueblackred);
    caxis(ud.cax);
    colorbar
    title(sprintf('pixel %d, %d selected', thisPixel(1), thisPixel(2)));
    set(ud.brainAx, 'ButtonDownFcn', @(f,k)tcViewerCallbackClick(f, k, allData));
    set(ud.brainAx, 'Tag', 'brainImage');

    % plot the traces across time for each condition for the selected pixel,
    % along with a marker for zero and for the selected time point
    ud.traceAx = subplot(1,4,3); 
    
    for c = 1:nConditions
        ud.traceHands(c) = plot(allData.winSamps, theseTraces(c,:), 'Color', colors(c,:));  set(ud.traceHands(c), 'HitTest', 'off');
        if c==thisCond
            set(ud.traceHands(c), 'LineWidth', 2.0);
        end
        hold on;
    end
    ud.traceThisTimeLine = plot([allData.winSamps(thisTimePoint) allData.winSamps(thisTimePoint)], [cax(1) cax(2)], 'k'); set(ud.traceThisTimeLine, 'HitTest', 'off');
    ud.traceZeroTimeLine = plot([0 0], [cax(1) cax(2)], 'k--'); set(ud.traceZeroTimeLine, 'HitTest', 'off');
    hold off;
    ylim(cax);
    title(sprintf('time = %.2fsec selected', allData.winSamps(thisTimePoint)));
    xlim([allData.winSamps(1) allData.winSamps(end)]);
    xlabel('time (sec)');
    set(ud.traceAx, 'ButtonDownFcn', @(f,k)tcViewerCallbackClick(f, k, allData));
    set(ud.traceAx, 'Tag', 'traces');

    % plot the "tuning curve" - the value at the pixel at this time point for
    % each condition
    ud.tcAx = subplot(1,4,4);     

    ud.tcHand = plot(ud.condXvals, thisTC, 'ko-'); hold on; set(ud.tcHand, 'HitTest', 'off');
    ud.tcMarkHand = plot(ud.condXvals(thisCond), thisTC(thisCond), 'k*'); set(ud.tcMarkHand, 'HitTest', 'off');
    hold off;
    ylim(cax);
    if numel(ud.condXvals)>1
        midC = (ud.condXvals(end)+ud.condXvals(1))/2; cRange = [ud.condXvals(end)-ud.condXvals(1)]*1.1;
        xlim([midC-cRange/2 midC+cRange/2]);
    end
    if iscell(allData.eLabels)
        set(ud.tcHand, 'XLabel', allData.eLabels);
        title(sprintf('value %.2f selected', allData.eLabels{thisCond}));
    else
        title(sprintf('value %.2f selected', allData.eLabels(thisCond)));
    end
    xlabel('condition value');    
    
    ylim(cax);
    set(ud.tcAx, 'ButtonDownFcn', @(f,k)tcViewerCallbackClick(f, k, allData));
    set(ud.tcAx, 'Tag', 'tuningCurves');
    
    ud.initialized = true;
    set(figHand, 'UserData', ud);
end

% update the already-initialized plots

% brain image
set(ud.brainIm, 'CData', thisBrainImage);
set(get(ud.brainAx, 'Title'), 'String', sprintf('pixel %d, %d selected', thisPixel(1), thisPixel(2)));

set(ud.brainPixelHand, 'XData', thisPixel(2), 'YData', thisPixel(1));


% traces
for c = 1:nConditions
    set(ud.traceHands(c), 'YData', theseTraces(c,:))
    if c==thisCond
        set(ud.traceHands(c), 'LineWidth', 2.0);
    else
        set(ud.traceHands(c), 'LineWidth', 1.0);
    end
end
set(ud.traceThisTimeLine, 'XData', [allData.winSamps(thisTimePoint) allData.winSamps(thisTimePoint)], 'YData', [cax(1) cax(2)]);
set(get(ud.traceAx, 'Title'), 'String', sprintf('time = %.2fsec selected', allData.winSamps(thisTimePoint)));


% tuning curve
set(ud.tcHand, 'YData', thisTC);
set(ud.tcMarkHand, 'XData', ud.condXvals(thisCond), 'YData', thisTC(thisCond));

if iscell(allData.eLabels)
    set(get(ud.tcAx, 'Title'), 'String', sprintf('value %.2f selected', allData.eLabels{thisCond}));
else
    set(get(ud.tcAx, 'Title'), 'String', sprintf('value %.2f selected', allData.eLabels(thisCond)));
end


