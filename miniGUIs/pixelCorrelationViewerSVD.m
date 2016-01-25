
function pixelCorrelationViewerSVD(U, V)
% U is Ysize x Xsize x S
% V is S x T

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

pixel = [1 1];

f = figure; 
corrData.f = f;

set(f, 'UserData', pixel);
set(f, 'KeyPressFcn', @(f,k)pixelCorrCallback(f, k, corrData, ySize, xSize));

showCorrMat(corrData, ySize, xSize, pixel);


function showCorrMat(corrData, ySize, xSize, pixel)

% this is not the fastest way to get the pixel index, but it's the fastest
% for me to think about...
rshpInds = reshape(1:numel(corrData.varP), ySize, xSize);
pixelInd = rshpInds(pixel(2),xSize-pixel(1));

Ur = corrData.Ur;
covV = corrData.covV;
varP = corrData.varP;

covP = Ur(pixelInd,:)*covV*Ur'; % 1 x P
stdPxPy = varP(pixelInd).^0.5 * varP.^0.5; % 1 x P
corrMat = covP./stdPxPy; % 1 x P


thisAx = subplot(1,1,1);
h = imagesc(flipud(reshape(corrMat, ySize, xSize)')); set(h, 'HitTest', 'off');
hold on; 
plot(pixel(2), pixel(1), 'ro');
hold off;
caxis([-1 1]); 
% cax = caxis();
% caxis([-max(abs(cax)) max(abs(cax))]);
colorbar
colormap(colormap_blueblackred);
% set(gca, 'YDir', 'normal');
set(thisAx, 'ButtonDownFcn', @(f,k)pixelCorrCallbackClick(f, k, corrData, ySize, xSize));
% p = get(corrData.f, 'Position'); UL = p(2)+p(3);
% truesize(corrData.f, [ySize xSize]);
% pnew = get(corrData.f, 'Position');
% set(corrData.f, 'Position', [p(1) UL-pnew(4) pnew(3) pnew(4)]); 
axis equal;
title(sprintf('pixel %d, %d selected', pixel(1), pixel(2)));

function pixelCorrCallbackClick(f, keydata, corrData, ySize, xSize)
figHand = get(f, 'Parent');

clickX = keydata.IntersectionPoint(1);
clickY = keydata.IntersectionPoint(2);

pixel = round([clickY clickX]);

set(figHand, 'UserData', pixel);
showCorrMat(corrData, ySize, xSize, pixel);


function pixelCorrCallback(f, keydata, corrData, ySize, xSize)
pixel = get(f, 'UserData');
switch keydata.Key
    case 'rightarrow'
        pixel(2) = pixel(2)+5;
    case 'leftarrow'
        pixel(2) = pixel(2)-5;
    case 'uparrow'
    	pixel(1) = pixel(1)-5;
    case 'downarrow'
        pixel(1) = pixel(1)+5;    
end
set(f, 'UserData', pixel);
showCorrMat(corrData, ySize, xSize, pixel);