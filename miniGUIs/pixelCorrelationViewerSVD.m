
function pixelCorrelationViewerSVD(U, V)
% U is Ysize x Xsize x S
% V is S x T
%
% Usage:
% - Click any pixel to select it and see its correlation matrix
% - Use the arrow keys to move around little by little
% - Press "V" to change the way the variance is calculated, to emphasize
% areas with large signals.

% to compute correlation matrix from SVD, all at once:
% Ur = reshape(U, size(U,1)*size(U,2),[]); % P x S
% covV = cov(V'); % S x S
% covP = Ur*covV*Ur'; % P x P
% varP = dot((Ur*covV)', Ur'); % 1 x P
% stdPxPy = (varP').^0.5 * varP.^0.5; % P x P
% corrP = covP./stdPxPy; % P x P

% to compute just the correlation with one pixel and the rest:
% 1) ahead of time:
fprintf(1, 'pre-computation...\n');
Ur = reshape(U, size(U,1)*size(U,2),[]); % P x S
covV = cov(V'); % S x S % this is the only one that takes some time really
varP = dot((Ur*covV)', Ur'); % 1 x P
fprintf(1, 'done.\n');

% 2) at computation time:
% covP = Ur(thisP,:)*covV*Ur'; % 1 x P
% stdPxPy = varP(thisP).^0.5 * varP.^0.5; % 1 x P
% corrP = covP./stdPxPy; % 1 x P

ySize = size(U,1); xSize = size(U,2);
corrData.Ur = Ur;
corrData.covV = covV;
corrData.varP = varP;

ud.pixel = [1 1];
ud.varCalcMax = false;

f = figure;
corrData.f = f;

set(f, 'UserData', ud);
set(f, 'KeyPressFcn', @(f,k)pixelCorrCallback(f, k, corrData, ySize, xSize));

showCorrMat(corrData, ySize, xSize, ud);


function showCorrMat(corrData, ySize, xSize, ud)

pixel = ud.pixel;
varCalcMax = ud.varCalcMax;

pixelInd = sub2ind([ySize, xSize], pixel(1), pixel(2));

Ur = corrData.Ur;
covV = corrData.covV;
varP = corrData.varP;

covP = Ur(pixelInd,:)*covV*Ur'; % 1 x P
if varCalcMax
    stdPxPy = varP(pixelInd).^0.5 * max(varP(:)).^0.5; % 1 x P
else
    stdPxPy = varP(pixelInd).^0.5 * varP.^0.5; % 1 x P
end
corrMat = covP./stdPxPy; % 1 x P


thisAx = subplot(1,1,1);
ch = get(thisAx, 'Children');
[imageExists, ind] = ismember('image', get(ch, 'Type'));
if imageExists
    h = ch(ind);
    set(h, 'CData', reshape(corrMat, ySize, xSize));
    % BIG assumption here - if an image exists, then a circle marker exists, 
    % and only one marker
    [~, ind] = ismember('line', get(ch, 'Type'));
    set(ch(ind), 'XData', pixel(2), 'YData', pixel(1))
else
    % this will happen on the first run
    h = imagesc(reshape(corrMat, ySize, xSize));
    axis equal tight;
    hold on;
    % green circle should be better, because does not belong to the colormap
    plot(pixel(2), pixel(1), 'o', 'Color', [0 0.8 0]);
    hold off;
    caxis([-1 1]);
    % cax = caxis();
    % caxis([-max(abs(cax)) max(abs(cax))]);
    colorbar
    colormap(colormap_blueblackred);
    set(h, 'HitTest', 'off');
end
% set(gca, 'YDir', 'normal');
set(thisAx, 'ButtonDownFcn', @(f,k)pixelCorrCallbackClick(f, k, corrData, ySize, xSize));
% p = get(corrData.f, 'Position'); UL = p(2)+p(3);
% truesize(corrData.f, [ySize xSize]);
% pnew = get(corrData.f, 'Position');
% set(corrData.f, 'Position', [p(1) UL-pnew(4) pnew(3) pnew(4)]);
title(sprintf('pixel %d, %d selected', pixel(1), pixel(2)));

function pixelCorrCallbackClick(f, keydata, corrData, ySize, xSize)
figHand = get(f, 'Parent');

clickX = keydata.IntersectionPoint(1);
clickY = keydata.IntersectionPoint(2);

pixel = round([clickY clickX]);

ud = get(figHand, 'UserData');
ud.pixel = pixel;
set(figHand, 'UserData', ud);
showCorrMat(corrData, ySize, xSize, ud);


function pixelCorrCallback(f, keydata, corrData, ySize, xSize)
ud = get(f, 'UserData');
pixel = ud.pixel;
varCalcMax = ud.varCalcMax;

if ismember(lower(keydata.Key), {'control', 'alt', 'shift'})
    % this happens on the initial press of these keys, so both the Modifier
    % and the Key are one of {'control', 'alt', 'shift'}
    return;
end

ch = get(f, 'Children');
% assuming there is exactly one axes
[~, ind] = ismember('axes', get(ch, 'Type'));
ax = ch(ind);
currentView = get(ax, 'View');

% rotating the view (this property is now obsolete in Matlab, but still
% works)
if isequal(keydata.Modifier, {'alt'})
    switch lower(keydata.Key)
        case 'rightarrow'
            newView = currentView + [90 0];
        case 'leftarrow'
            newView = currentView + [-90 0];
        case {'uparrow', 'downarrow'}
            newView = currentView.*[1 -1];
        otherwise
            newView = currentView;
    end
    newView(1) = mod(newView(1), 360);
    set(ax, 'View', newView);
    return;
end

% Press Ctrl if you want to move pixel-by-pixel
increment = 5;
if isequal(keydata.Modifier, {'control'})
    increment = 1;
end

% based on the currentView of the axes we need to know where to move
original = {'uparrow'; 'leftarrow'; 'downarrow'; 'rightarrow'};
new = circshift(original, -currentView(1)/90);
if currentView(2)<0
    new = new([3, 2, 1, 4]);
end;
[~, ind] = ismember(lower(keydata.Key), original);
if ind
    newKey = new{ind};
else
    newKey = lower(keydata.Key);
end

% the xSize and ySize limits below are confusing, but these are because of
% the transpose during imagesc() in showCorrMat()
% switch lower(keydata.Key)
switch newKey
    case 'rightarrow'
        pixel(2) = min(xSize, pixel(2)+increment);
    case 'leftarrow'
        pixel(2) = max(1, pixel(2)-increment);
    case 'uparrow'
        pixel(1) = max(1, pixel(1)-increment);
    case 'downarrow'
        pixel(1) = min(ySize, pixel(1)+increment);
    case 'v'
        varCalcMax = ~varCalcMax;
end

ud.pixel = pixel;
ud.varCalcMax = varCalcMax;
set(f, 'UserData', ud);
showCorrMat(corrData, ySize, xSize, ud);