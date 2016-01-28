

function movieWithTracesSVD(U, V, t, tracesT, tracesV, movieSaveFilePath)
% function movieWithTracesSVD(U, V, t, tracesT, tracesV, movieSaveFilePath)
%
% Usage:
% - 'p' plays/pauses
% - 'r' starts/stops recording, if playing
% - up/down arrow keys increase/decrease playback rate
% - alt+arrowkeys changes view
%
% NOTE! The caxis is set like it's a DF/F movie. If you want a DF/F movie, 
% divide U by the mean image before passing it in, like this:
% >> U = bsxfun(@rdivide, U, meanImage);

allData.U = U;
allData.V = V;
allData.t = t;
if ~isempty(tracesT)
    allData.tracesT = tracesT;
    allData.tracesV = tracesV;
else
    allData.tracesT = {};
    allData.tracesV = {};
end

figHandle = figure; 

ud.currentFrame = 1;
ud.rate = 1;
ud.playing = true;
ud.figInitialized = false;
ud.pixel = [1 1];
ud.pixelTrace = squeeze(allData.U(ud.pixel(1), ud.pixel(2), :))' * allData.V;

if exist('movieSaveFilePath')
    WriterObj = VideoWriter(movieSaveFilePath);
    WriterObj.FrameRate=50;
    open(WriterObj);
    ud.WriterObj = WriterObj;
    ud.recording = false;
    set(figHandle, 'Name', 'NOT RECORDING');
else
    ud.WriterObj = [];
    ud.recording = false;
end

set(figHandle, 'UserData', ud);

myTimer = timer(...
    'Period',0.1,...
    'ExecutionMode','fixedRate',...
    'TimerFcn',@(h,eventdata)showNextFrame(h,eventdata, figHandle, allData));

set(figHandle, 'CloseRequestFcn', @(s,c)closeFigure(s,c,myTimer));

set(figHandle, 'KeyPressFcn', @(f,k)movieKeyCallback(f, k));

showNextFrame(1, 1,figHandle, allData)

start(myTimer);

function showNextFrame(h,e,figHandle, allData)

ud = get(figHandle, 'UserData');
windowSize = 10;

if ~ud.figInitialized
    ax = subtightplot(1,2,1, 0.01, 0.01, 0.01);    
%     ax = axes();
    ud.ImageAxisHandle = ax;
    myIm = imagesc(svdFrameReconstruct(allData.U, allData.V(:, ud.currentFrame)));     
    ud.ImageHandle = myIm;
    caxis([-0.15 0.15]);
    colormap(colormap_blueblackred);
    axis equal tight;
    colorbar
    axis off     
%     set(myIm, 'HitTest', 'off');
    set(myIm, 'ButtonDownFcn', @(f,k)movieCallbackClick(f, k, allData, figHandle));

    
    % initialize any trace plots here. Use subtightplot and axis off (except
    % the bottom one?)     
    nSP = length(allData.tracesT)+1;
    currTime = allData.t(ud.currentFrame);    
    for tInd = 1:nSP-1
        ax = subtightplot(nSP,2,(tInd-1)*2+2, 0.01, 0.01, 0.01);
        ud.traceAxes(tInd) = ax;
        thisT = allData.tracesT{tInd};
        inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');
        q = plot(thisT(inclT), allData.tracesV{tInd}(inclT));
        if isempty(q)
            q = plot(0,0);
        end
        ud.traceHandles(tInd) = q;
        axis off
        xlim([currTime-windowSize/2 currTime+windowSize/2]);
        yl = ylim();
        hold on;
        q = plot([currTime currTime], yl, 'k--');
        ud.traceZeroBars(tInd) = q;
        makepretty;
    end
    
    % one more for the selected pixel
    ax = subtightplot(nSP,2,(nSP-1)*2+2, 0.01, 0.01, 0.01);
    ud.traceAxes(nSP) = ax;
    thisT = allData.t;
    inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');
    q = plot(thisT(inclT), ud.pixelTrace(inclT)); 
    ud.traceHandles(nSP) = q;
    hold on;
    yl = ylim();
    axis off
    q = plot([currTime currTime], yl, 'k--');    
    ud.traceZeroBars(nSP) = q;
    xlim([currTime-5 currTime+5]);
    makepretty;
    
    ud.figInitialized = true;
    set(figHandle, 'UserData', ud);
end

if ud.playing
    set(ud.ImageHandle, 'CData', svdFrameReconstruct(allData.U, allData.V(:, ud.currentFrame)));    
        
    currTime = allData.t(ud.currentFrame);
    set(get(ud.ImageAxisHandle, 'Title'), 'String', sprintf('time %.2f, rate %d', currTime, ud.rate));              
    
    nSP = length(allData.tracesT)+1;
    for n = 1:nSP
        ax = ud.traceAxes(n);        
        set(ud.traceZeroBars(n), 'XData', [currTime currTime]);
        
        if n<nSP
            thisT = allData.tracesT{n};
            inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');
            set(ud.traceHandles(n), 'XData', thisT(inclT), 'YData', allData.tracesV{n}(inclT));
        elseif n==nSP
            thisT = allData.t;
            inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');
            set(ud.traceHandles(n), 'XData', thisT(inclT), 'YData', ud.pixelTrace(inclT));
            mx =  max(ud.pixelTrace(inclT));
            mn = min(ud.pixelTrace(inclT));
            if mx>mn
                ylim(ud.traceAxes(n), [mn mx]);
            end
        end
        xlim(ax, [currTime-windowSize/2 currTime+windowSize/2]);
        
    end
    
    drawnow;
    
    ud = get(figHandle, 'UserData');
    ud.currentFrame = ud.currentFrame+ud.rate;
    set(figHandle, 'UserData', ud);
    
    if ~isempty(ud.WriterObj) && ud.recording
        frame = getframe(figHandle);
        writeVideo(ud.WriterObj,frame);
    end
end






function movieKeyCallback(figHandle, keydata)
ud = get(figHandle, 'UserData');


if ismember(lower(keydata.Key), {'control', 'alt', 'shift'})
    % this happens on the initial press of these keys, so both the Modifier
    % and the Key are one of {'control', 'alt', 'shift'}
    return;
end

ax = ud.ImageAxisHandle;
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

switch lower(keydata.Key)
    case 'rightarrow'
        
    case 'leftarrow'
        
    case 'uparrow'
        ud.rate = ud.rate*2;
    case 'downarrow'
        ud.rate = max(1, ud.rate/2);
    case 'p'
        ud.playing = ~ud.playing;
    case 'r'
        ud.recording = ~ud.recording;
        if ud.recording
            set(figHandle, 'Name', 'RECORDING');
        else
            set(figHandle, 'Name', 'Not recording.');
        end
end


set(figHandle, 'UserData', ud);

function movieCallbackClick(f, keydata, allData, figHandle)

clickX = keydata.IntersectionPoint(1);
clickY = keydata.IntersectionPoint(2);

pixel = round([clickY clickX]);

fprintf(1, 'new pixel %d, %d\n', pixel(1), pixel(2));

ud = get(figHandle, 'UserData');
ud.pixel = pixel;
ud.pixelTrace = squeeze(allData.U(pixel(1), pixel(2), :))' * allData.V;
set(figHandle, 'UserData', ud);


function closeFigure(s,c,myTimer)
stop(myTimer)
delete(myTimer);
delete(s);