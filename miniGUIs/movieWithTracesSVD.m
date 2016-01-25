

function movieWithTracesSVD(U, V, meanImage, t, tracesT, tracesV)

allData.U = U;
allData.V = V;
allData.t = t;
if ~isempty(tracesT)
    allData.tracesT = tracesT;
    allData.tracesV = tracesV;
end

if ~isempty(meanImage)
    allData.meanImage = meanImage;
else
    allData.meanImage = ones(size(U,1), size(U,2));
end

figHandle = figure; 

ud.currentFrame = 1;
ud.rate = 1;
ud.playing = true;

set(figHandle, 'UserData', ud);

myTimer = timer(...
    'Period',0.1,...
    'ExecutionMode','fixedRate',...
    'TimerFcn',@(h,eventdata)showNextFrame(h,eventdata, figHandle, allData, false));

set(figHandle, 'CloseRequestFcn', @(s,c)closeFigure(s,c,myTimer));

set(figHandle, 'KeyPressFcn', @(f,k)movieKeyCallback(f, k));

showNextFrame(1, 1,figHandle, allData, true)

start(myTimer);

function showNextFrame(h,e,figHandle, allData, init)

ud = get(figHandle, 'UserData');

if ud.playing
    imagesc(svdFrameReconstruct(allData.U, allData.V(:, ud.currentFrame))./allData.meanImage);
%     imagesc(svdFrameReconstruct(allData.U, allData.V(:, ud.currentFrame)));
    caxis([-0.15 0.15]);
    title(sprintf('frame %d, rate %d', ud.currentFrame, ud.rate));
    if init
        colormap(colormap_blueblackred);
        axis equal;
        colorbar
    end
    drawnow;
    ud.currentFrame = ud.currentFrame+ud.rate;
end

set(figHandle, 'UserData', ud);


function movieKeyCallback(figHandle, keydata)
ud = get(figHandle, 'UserData');
switch keydata.Key
    case 'rightarrow'
        
    case 'leftarrow'
        
    case 'uparrow'
    	ud.rate = ud.rate*2;
    case 'downarrow'
        ud.rate = max(1, ud.rate/2);
    case 'p'
        ud.playing = ~ud.playing;

end

set(figHandle, 'UserData', ud);

function closeFigure(s,c,myTimer)
stop(myTimer)
delete(myTimer);
delete(s);