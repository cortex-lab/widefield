
function svdViewer(U, Sv, V, Fs, varargin)
% function svdViewer(U, Sv, V, Fs[, totalVariance])
% SVD viewer. Use left/right arrow keys to go forward/back through the
% components. Click on the spatial map or press p to show reconstructions
% of a particular pixel. You can zoom with the zoom tool on the trace
% plots (and you should, if you are looking at pixel reconstructions, for 
% speed), but you have to go out of zoom mode to use the hotkeys again. If
% zoom gets stuck zoomed-in, use z to reset it. 
%
% TODO: add spatial power spectrum

f = figure;

myData.U = U;
myData.Sv = Sv;
myData.V = V;
myData.Fs = Fs;
if isempty(varargin)
    myData.totalVariance = sum(Sv);
else
    myData.totalVariance = varargin{1};
end
myData.thisComponentIndex = 1;
myData.nComponents = length(Sv);
% myData.zoomNSamps = 1500; %half-width of zoom
% myData.zoomCenter = myData.zoomNSamps+1;
pY = round(size(U,1)/2); pX = round(size(U,2)/2);
myData.pixelY = pY;
myData.pixelX = pX;
myData.pixelMode = false;
myData.traceXLim = [1 size(V,2)]/Fs;
 

set(f, 'UserData', myData);

showSVD(f);

set(f, 'KeyPressFcn', @(f,v)svdViewerCallback(f,v));


function [pixFull, pixCumul, xl] = computePixelData(myData)
pY = myData.pixelY; pX = myData.pixelX;
xl = round(myData.traceXLim*myData.Fs);
U = myData.U; V = myData.V;
xl(1) = max(1, xl(1)); xl(2) = min(size(V,2), xl(2));
compInd = myData.thisComponentIndex;
pixFull = squeeze(U(pY, pX, :))'*V(:,xl(1):xl(2)); 
pixCumul = squeeze(U(pY, pX, 1:compInd))'*V(1:compInd,xl(1):xl(2));

function [Pxx, F] = myTimePowerSpectrum(V, Fs)
L = length(V);
NFFT = 2^nextpow2(L);
[Pxx,F] = pwelch(V,[],[],NFFT,Fs);

function svdViewerCallback(f, keydata)
myData = get(f, 'UserData');
compInd = myData.thisComponentIndex;
nComp = myData.nComponents;
% zoomN = myData.zoomNSamps;
switch keydata.Key
    case 'rightarrow'
        compInd = compInd+1;
        if compInd > nComp; compInd = 1; end; % wraparound
    case 'leftarrow'
        compInd = compInd-1;
        if compInd<=0; compInd = nComp; end % wraparound
%     case 'uparrow'
%         zoomN = round(zoomN*1.25);
%     case 'downarrow'
%         zoomN = round(zoomN/1.25);
    case 'p'
        myData.pixelMode = ~myData.pixelMode; 
    case 'z' % reset zoom
        myData.traceXLim = [1 size(myData.V,2)]/myData.Fs;
end
if compInd~=myData.thisComponentIndex
    myData.thisComponentIndex = compInd;
end
% myData.zoomNSamps = zoomN;
set(f, 'UserData', myData);
showSVD(f);

function varPlotClickCallback(s, e)
% fprintf(1, 'var click\n');
f = get(s, 'Parent');
myData = get(f, 'UserData');
myData.thisComponentIndex = round(e.IntersectionPoint(1));
set(f, 'UserData', myData);
showSVD(f);

function spatialMapClickCallback(s, e)
% fprintf(1, 'var click\n');
f = get(s, 'Parent');
myData = get(f, 'UserData');
myData.pixelY = round(e.IntersectionPoint(1));
myData.pixelX = round(e.IntersectionPoint(2));
myData.pixelMode = true;
set(f, 'UserData', myData);
showSVD(f);

% function tracePlotClickCallback(s, e)
% % fprintf(1, 'trace click\n');
% f = get(s, 'Parent');
% myData = get(f, 'UserData');
% myData.zoomCenter = round(e.IntersectionPoint(1));
% set(f, 'UserData', myData);
% showSVD(f);

function zoomCallback(f, e)
thisAxisTag = get(e.Axes, 'Tag');
if strcmp(thisAxisTag, 'pixelPlot') || strcmp(thisAxisTag, 'componentTracePlot')
    newLim = get(e.Axes, 'XLim');
    myData = get(f, 'UserData');
    myData.traceXLim = newLim;
    set(f, 'UserData', myData);
    % showSVD(f);
end

function showSVD(f)

myData = get(f, 'UserData');
thisComponentIndex = myData.thisComponentIndex;
nComp = myData.nComponents;
if thisComponentIndex<1; thisComponentIndex = 1; end;
if thisComponentIndex>nComp; thisComponentIndex = nComp; end;
pX = myData.pixelX; pY = myData.pixelY;
Fs = myData.Fs;
Sv = myData.Sv;
totalVar = myData.totalVariance;
thisCompVarPct = Sv(thisComponentIndex)/totalVar*100;
upToThisCompVarPct1 = sum(Sv(1:thisComponentIndex))/totalVar*100;
% upToThisCompVarPct2 = sum(Sv(2:thisComponentIndex))/sum(Sv(2:end))*100;

% zoomN = myData.zoomNSamps;
% zoomC = myData.zoomCenter;
% zoomRange = [max(1, zoomC-zoomN):min(size(myData.V,2), zoomC+zoomN)];

ax1 = subplot(4,4,1:2);
hold off;
q = plot((1:size(myData.V,2))/Fs, myData.V(thisComponentIndex,:)); set(q, 'HitTest', 'off');
hold on; 
yl = ylim();
% q = plot(zoomRange(1)*[1 1], yl, 'k');set(q, 'HitTest', 'off');
% q = plot(zoomRange(end)*[1 1], yl, 'k');set(q, 'HitTest', 'off');
title(sprintf('component %d', thisComponentIndex));
xlabel('time (seconds)'); ylabel('component value');
xlim(myData.traceXLim);
hZoom = zoom(ax1);
set(hZoom,'ActionPostCallback',@zoomCallback);
set(ax1, 'Tag', 'componentTracePlot');

% set(ax1, 'ButtonDownFcn', @tracePlotClickCallback);

% subplot(4,4,5:6)
% plot(zoomRange, myData.V(thisComponentIndex,zoomRange));
% xlim([zoomRange(1) zoomRange(end)]);
% xlabel('time (samples)'); ylabel('component value');

if myData.pixelMode    
    [pixFull, pixCumul, xl] = computePixelData(myData);
else
    pixFull = 0; pixCumul = 0; xl = [1 1];
end
ax2 = subplot(4, 4, 5:6);
hold off;
plot((xl(1):xl(2))/Fs, pixFull);
hold on;
plot((xl(1):xl(2))/Fs, pixCumul);
xlabel('time (seconds)'); ylabel('reconstructed value')
legend({'with all SVs', sprintf('with up to %d', thisComponentIndex)});
xlim(myData.traceXLim);
hZoom = zoom(ax2);
set(hZoom,'ActionPostCallback',@zoomCallback);
set(ax2, 'Tag', 'pixelPlot');


linkaxes([ax1 ax2], 'x');


ax = subplot(4,4,[9 10]);
hold off;
q = semilogy(Sv./totalVar, '.-'); set(q, 'HitTest', 'off');
hold on;
q = semilogy(cumsum(Sv./totalVar), '.-'); set(q, 'HitTest', 'off');
% semilogy(7:nComp, cumsum(svVar(7:nComp)./sum(svVar(7:nComp))), '.-')
yl = ylim();
q = plot(thisComponentIndex*[1 1], yl, 'k'); set(q, 'HitTest', 'off');
xlabel('component number');
ylabel('log(%var explained)')
legend({'pct var per component', 'cumulative'}, 'Location', 'Best');
set(ax, 'ButtonDownFcn', @varPlotClickCallback);

ax = subplot(4,4,[13 14]);
[Pxx, F] = myTimePowerSpectrum(myData.V(thisComponentIndex,:), Fs);
plot(F, 10*log10(Pxx));
xlabel('freq (hz)');
ylabel('power');

ax = subplot(4,4,[3 4 7 8 11 12 15 16]);
hold off;
q = imagesc(myData.U(:,:,thisComponentIndex));set(q, 'HitTest', 'off');
hold on; 
if myData.pixelMode
    plot(pY, pX, 'ro'); set(q, 'HitTest', 'off');
end
% title(sprintf('%.3f%% this component, %.3f/%.3f cumulative', thisCompVarPct, upToThisCompVarPct1, upToThisCompVarPct2));
title(sprintf('%.3f%% this component, %.3f cumulative', thisCompVarPct, upToThisCompVarPct1));
set(ax, 'ButtonDownFcn', @spatialMapClickCallback);



