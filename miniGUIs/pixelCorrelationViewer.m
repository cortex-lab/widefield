function pixelCorrelationViewer(corrMat, ySize, xSize)
% corrMat is nPix x nPix; ySize and xSize are the image size for
% reconstructing for plotting

% to compute correlation matrix from SVD:
Ur = reshape(U, size(U,1)*size(U,2),[]); % P x S
covV = cov(V'); % S x S
covP = Ur*covV*Ur'; % P x P
varP = dot((Ur*covV)', Ur'); % 1 x P
stdPxPy = (varP').^0.5 * varP.^0.5; % P x P
corrP = covP./stdPxPy; % P x P

pixel = [1 1];

f = figure; 

set(f, 'UserData', pixel);
set(f, 'KeyPressFcn', @(f,k)pixelCorrCallback(f, k, corrMat, ySize, xSize));

showCorrMat(corrMat, ySize, xSize, pixel);


function showCorrMat(corrMat, ySize, xSize, pixel)

% this is not the fastest way to get the pixel index, but it's the fastest
% for me to think about...
rshpInds = reshape(1:size(corrMat,1), ySize, xSize);
pixelInd = rshpInds(pixel(1),pixel(2));

thisAx = subplot(1,1,1);
h = imagesc(reshape(corrMat(pixelInd,:), ySize, xSize)); set(h, 'HitTest', 'off');
hold on; 
plot(pixel(2), pixel(1), 'ro');
hold off;
caxis([-1 1]); 
% cax = caxis();
% caxis([-max(abs(cax)) max(abs(cax))]);
colorbar
colormap(colormap_blueblackred);
% set(gca, 'YDir', 'normal');
set(thisAx, 'ButtonDownFcn', @(f,k)pixelCorrCallbackClick(f, k, corrMat, ySize, xSize));


function pixelCorrCallbackClick(f, keydata, corrMat, ySize, xSize)
figHand = get(f, 'Parent');

clickX = keydata.IntersectionPoint(1);
clickY = keydata.IntersectionPoint(2);

pixel = round([clickY clickX]);

set(figHand, 'UserData', pixel);
showCorrMat(corrMat, ySize, xSize, pixel);


function pixelCorrCallback(f, keydata, corrMat, ySize, xSize)
pixel = get(f, 'UserData');
switch keydata.Key
    case 'rightarrow'
        pixel(2) = pixel(2)+1;
    case 'leftarrow'
        pixel(2) = pixel(2)-1;
    case 'uparrow'
    	pixel(1) = pixel(1)+1;
    case 'downarrow'
        pixel(1) = pixel(1)-1;    
end
set(f, 'UserData', pixel);
showCorrMat(corrMat, ySize, xSize, pixel);