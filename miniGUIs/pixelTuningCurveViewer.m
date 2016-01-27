

function pixelTuningCurveViewer(allFrames, cLabels, timePoints)
% function pixelTuningCurveViewer(allFrames, cLabels, timePoints)
%
% Displays: A) the image of the brain for a certain time point and
% condition; B) the traces across time for a certain pixel and all
% conditions; C) the value at that pixel and time point across conditions
%
% Allows the user to modify which pixel, time point, and condition are
% shown through simple click actions or keyboard shortcuts. 
%
% Inputs: 
% - allFrames: Ypix x Xpix x nTimePoints x nConditions; the data
% - cLabels: 1 x nConditions, the "value" for each condition, e.g. the
% contrast of the stimulus. Default is 1:nConditions. 
% - timePoints: 1 x nTimePoints; the vector of time points
%
% Controls:
% - click in the three plots to change pixel, time point, and condition
% respectively
% - Use left/right arrow keys to change time point (hold down to play)
% - Use up/down arrow keys to change condition
% - Use i/j/k/l to navigate pixels
% - Use c to reset display limits
% - Use mouse scroll wheel to zoom/recenter display limits


Ypix = size(allFrames,1);
Xpix = size(allFrames,2);
nTimePoints = size(allFrames,3);
nConditions = size(allFrames,4);

if isempty(cLabels)
    cLabels = 1:nConditions;
end
if isempty(timePoints)
    timePoints = 1:nTimePoints;
end

thisTimePoint = 1; 
thisPixel = [round(Ypix/2) round(Xpix/2)];
thisCond = 1;


cax = autoCax(allFrames, thisPixel);

f = figure; 

set(f, 'UserData', [thisTimePoint thisPixel thisCond cax]);
set(f, 'KeyPressFcn', @(f,k)tcViewerCallback(f, k, allFrames, cLabels, timePoints));
set(f, 'WindowScrollWheelFcn', @(f,k)tcViewerCallbackWheel(f,k, allFrames, cLabels, timePoints));

showTC(allFrames, cLabels, timePoints, thisPixel, thisTimePoint, thisCond, cax);

function tcViewerCallbackWheel(f, keydata, allFrames, cLabels, timePoints)

ud = get(f, 'UserData');
thisTimePoint = ud(1); thisPixel = ud(2:3); thisCond = ud(4); cax = ud(5:6);

scroll = keydata.VerticalScrollCount; % -1 for down, 1 for up
q = get(gca, 'CurrentPoint');
yVal = q(1,2);

currentRange = cax(2)-cax(1);
if scroll>0
    newRange = currentRange*1.2;
else
    newRange = currentRange/1.2;
end

cax = [yVal-newRange/2 yVal+newRange/2];

set(f, 'UserData', [thisTimePoint thisPixel thisCond cax]);
showTC(allFrames, cLabels, timePoints, thisPixel, thisTimePoint, thisCond, cax);

function tcViewerCallback(f, keydata, allFrames, cLabels, timePoints)

Ypix = size(allFrames,1);
Xpix = size(allFrames,2);
nTimePoints = size(allFrames,3);
nConditions = size(allFrames,4);

ud = get(f, 'UserData');
thisTimePoint = ud(1); thisPixel = ud(2:3); thisCond = ud(4); cax = ud(5:6);
switch keydata.Key
    case 'rightarrow'
        thisTimePoint = thisTimePoint+1; 
        if thisTimePoint>nTimePoints; thisTimePoint = nTimePoints; end;
    case 'leftarrow'
        thisTimePoint = thisTimePoint-1;
        if thisTimePoint<1; thisTimePoint = 1; end;
    case 'uparrow'
    	thisCond = thisCond+1;
        if thisCond>nConditions; thisCond = 1; end
    case 'downarrow'
        thisCond = thisCond-1;    
        if thisCond<1; thisCond = nConditions; end
    case 'i'
        thisPixel(1) = thisPixel(1)+5;
        if thisPixel(1)>yPix; thisPixel(1) = yPix; end
    case 'k'
        thisPixel(1) = thisPixel(1)-5;
        if thisPixel(1)<1; thisPixel(1) = 1; end
    case 'j'
        thisPixel(2) = thisPixel(2)-5;
        if thisPixel(2)<1; thisPixel(2) = 0; end
    case 'l'
        thisPixel(2) = thisPixel(2)+5;
        if thisPixel(2)>xPix; thisPixel(2) = xPix; end
    case 'c'
        cax = autoCax(allFrames, thisPixel);
end
set(f, 'UserData', [thisTimePoint thisPixel thisCond cax]);
showTC(allFrames, cLabels, timePoints, thisPixel, thisTimePoint, thisCond, cax);

function tcViewerCallbackClick(f, keydata, allFrames, cLabels, timePoints)


figHand = get(f, 'Parent');
ud = get(figHand, 'UserData');
thisTimePoint = ud(1); thisPixel = ud(2:3); thisCond = ud(4); cax = ud(5:6);

clickX = keydata.IntersectionPoint(1);
clickY = keydata.IntersectionPoint(2);

switch get(f, 'Tag')
    case 'brainImage'
        thisPixel = round([clickY clickX]);
    case 'traces'
        thisTimePoint = min(length(timePoints), find(timePoints>clickX,1));
    case 'tuningCurves'
%         tc = squeeze(allFrames(thisPixel(1), thisPixel(2), thisTimePoint, :));
%         dists = ((clickX-cLabels).^2 + (clickY-tc).^2).^(0.5);
        dists = abs(clickX-cLabels);
        thisCond = find(dists==min(dists),1);
        
end

set(figHand, 'UserData', [thisTimePoint thisPixel thisCond cax]);
showTC(allFrames, cLabels, timePoints, thisPixel, thisTimePoint, thisCond, cax);



function showTC(allFrames, cLabels, timePoints, thisPixel, thisTimePoint, thisCond, cax)

nConditions = size(allFrames,4);

% plot the brain image with a marker where the selected pixel is
thisAx = subplot(1,4,1:2); 
q = imagesc(allFrames(:,:,thisTimePoint,thisCond)); set(q, 'HitTest', 'off');
hold on;
q = plot(thisPixel(2), thisPixel(1), 'ro'); set(q, 'HitTest', 'off');
hold off;
% set(gca, 'YDir', 'normal');
caxis(cax);
colorbar
title(sprintf('pixel %d, %d selected', thisPixel(1), thisPixel(2)));
set(thisAx, 'ButtonDownFcn', @(f,k)tcViewerCallbackClick(f, k, allFrames, cLabels, timePoints));
set(thisAx, 'Tag', 'brainImage');

% plot the traces across time for each condition for the selected pixel,
% along with a marker for zero and for the selected time point
thisAx = subplot(1,4,3); 
% colors = [0 0 1; 0 0 0.8; 0 0 0.6; 0 0 0.4; 0.4 0 0; 0.6 0 0; 0.8 0 0; 1 0 0];
colors = copper(nConditions); colors = colors(:, [3 2 1]);
for f = 1:nConditions
    q = plot(timePoints, squeeze(allFrames(thisPixel(1), thisPixel(2), :, f)), 'Color', colors(f,:));  set(q, 'HitTest', 'off');
    if f==thisCond
        set(q, 'LineWidth', 2.0);
    end
    hold on;
end
yl = ylim();
q = plot([timePoints(thisTimePoint) timePoints(thisTimePoint)], [cax(1) cax(2)], 'k'); set(q, 'HitTest', 'off');
q = plot([0 0], [cax(1) cax(2)], 'k--'); set(q, 'HitTest', 'off');
hold off;
ylim(cax);
title(sprintf('time = %.2fsec selected', timePoints(thisTimePoint)));
xlim([timePoints(1) timePoints(end)]);
xlabel('time (sec)');
set(thisAx, 'ButtonDownFcn', @(f,k)tcViewerCallbackClick(f, k, allFrames, cLabels, timePoints));
set(thisAx, 'Tag', 'traces');

% plot the "tuning curve" - the value at the pixel at this time point for
% each condition
thisAx = subplot(1,4,4); 

tc = squeeze(allFrames(thisPixel(1), thisPixel(2), thisTimePoint, :));
% q = plot(cLabels(1:4), tc(1:4), 'o-');hold on; set(q, 'HitTest', 'off');
% q = plot(cLabels(5:8), tc(5:8), 'o-'); set(q, 'HitTest', 'off');
q = plot(cLabels, tc, 'ko-'); hold on; set(q, 'HitTest', 'off');
q = plot(cLabels(thisCond), tc(thisCond), 'k*'); set(q, 'HitTest', 'off');
hold off;
ylim(cax);
if numel(cLabels)>1
    midC = (cLabels(end)+cLabels(1))/2; cRange = [cLabels(end)-cLabels(1)]*1.1;
    xlim([midC-cRange/2 midC+cRange/2]);
end
xlabel('condition value');
title(sprintf('value %.2f selected', cLabels(thisCond)));
ylim(cax);
set(thisAx, 'ButtonDownFcn', @(f,k)tcViewerCallbackClick(f, k, allFrames, cLabels, timePoints));
set(thisAx, 'Tag', 'tuningCurves');


function cax = autoCax(allFrames, thisPixel)

minVal = min(min(allFrames(thisPixel(1), thisPixel(2), :,:)));
maxVal = max(max(allFrames(thisPixel(1), thisPixel(2), :,:)));

midVal = (maxVal+minVal)/2; range = (maxVal-minVal)*1.1;
cax = [midVal-range/2 midVal+range/2];

