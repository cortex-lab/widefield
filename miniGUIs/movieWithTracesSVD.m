

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

% TODO
% - Test ctrl+click
% - Plot the positions of chosen pixels
% - Set colors of pixel markers and traces
% - Add clear functionality
%
% - Add trace labels


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
ud.pixel = {[1 1]};
ud.pixelTrace = (squeeze(allData.U(ud.pixel{1}(1), ud.pixel{1}(2), :))' * allData.V)';

ud.nColors = 5;
% pixColors = hsv(nColors);
ud.pixColors =  ... % default color order
    [0    0.4470    0.7410
    0.8500    0.3250    0.0980
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840];


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

nColors = ud.nColors; pixColors = ud.pixColors;

cax = [-0.4 0.4];

if ~ud.figInitialized
    ax = subtightplot(1,2,1, 0.01, 0.01, 0.01);    
%     ax = axes();
    ud.ImageAxisHandle = ax;
    myIm = imagesc(svdFrameReconstruct(allData.U, allData.V(:, ud.currentFrame)));     
    ud.ImageHandle = myIm;
    caxis(cax);
    colormap(colormap_blueblackred);
    axis equal tight;
    colorbar    
%     set(myIm, 'HitTest', 'off');
    set(myIm, 'ButtonDownFcn', @(f,k)movieCallbackClick(f, k, allData, figHandle));
    hold on;
    q = plot(ax, ud.pixel{1}(2), ud.pixel{1}(1), 'ko', 'MarkerFaceColor', pixColors(1,:));
    ud.pixMarkerHandles(1) = q;        
    axis off 
    
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
        ud.traceHandles{tInd} = q;
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
    q = plot(thisT(inclT), ud.pixelTrace(inclT), 'Color', pixColors(1,:)); 
    ud.traceHandles{nSP} = q;
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
    
    if length(ud.pixel)>length(ud.pixMarkerHandles)
        ud = get(figHandle, 'UserData');
        for newPix = length(ud.pixMarkerHandles)+1:length(ud.pixel)
            q = plot(ud.ImageAxisHandle, ud.pixel{newPix}(2), ud.pixel{newPix}(1), 'ko', 'MarkerFaceColor', pixColors(mod(newPix-1,nColors)+1,:));
            ud.pixMarkerHandles(newPix) = q;
        end
        set(figHandle, 'UserData', ud);
    end
    
    currTime = allData.t(ud.currentFrame);
    set(get(ud.ImageAxisHandle, 'Title'), 'String', sprintf('time %.2f, rate %d', currTime, ud.rate));              
    
    nSP = length(allData.tracesT)+1;
    for n = 1:nSP
        ax = ud.traceAxes(n);        
        set(ud.traceZeroBars(n), 'XData', [currTime currTime]);
        
        if n<nSP
            thisT = allData.tracesT{n};
            inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');
            set(ud.traceHandles{n}, 'XData', thisT(inclT), 'YData', allData.tracesV{n}(inclT));
        elseif n==nSP            
            % last plot is the pixels. It'll be a cell array with multiple
            % pixels
            thisT = allData.t;
            inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');                                    
            
            if length(ud.pixel)>length(ud.traceHandles{n}) 
                ud = get(figHandle, 'UserData');
                % there are new pixels, need to initialize
                for newPix = length(ud.traceHandles{n})+1:length(ud.pixel)
                    q = plot(ax, thisT(inclT), ud.pixelTrace(inclT,newPix), 'Color', pixColors(mod(newPix-1,nColors)+1,:), 'LineWidth', 2.0);
                    ud.traceHandles{n}(newPix) = q;
                end
                set(figHandle, 'UserData', ud);
            end
            
            
            for tr = 1:length(ud.traceHandles{n})
                thisHand = ud.traceHandles{n}(tr);
                set(thisHand, 'XData', thisT(inclT), 'YData', ud.pixelTrace(inclT,tr));
            end
            ylim(ax, cax);
%             mx =  max(ud.pixelTrace(inclT));
%             mn = min(ud.pixelTrace(inclT));
%             if mx>mn
%                 ylim(ud.traceAxes(n), [mn mx]);
%             end
                
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

ud = get(figHandle, 'UserData');
switch lower(keydata.Key)
    case 'rightarrow'
        
    case 'leftarrow'
        
    case 'uparrow'
        ud.rate = ud.rate*2;
    case 'downarrow'
        ud.rate = max(1, ud.rate/2);
    case 'p' % play/pause
        ud.playing = ~ud.playing;
    case 'r' %start/stop recording
        ud.recording = ~ud.recording;
        if ud.recording
            set(figHandle, 'Name', 'RECORDING');
        else
            set(figHandle, 'Name', 'Not recording.');
        end
    case 'c' % clear pixels
        ud.pixel = {ud.pixel{end}};
        ud.pixelTrace = ud.pixelTrace(:,end);
        oldHands = ud.traceHandles{end};
        ud.traceHandles{end} = oldHands(end);
        delete(oldHands(1:end-1));
        oldHands = ud.pixMarkerHandles;
        ud.pixMarkerHandles = oldHands(end);
        delete(oldHands(1:end-1));
        set(ud.pixMarkerHandles, 'MarkerFaceColor', ud.pixColors(1,:));
        set(ud.traceHandles{end}, 'Color', ud.pixColors(1,:));
        
end
set(figHandle, 'UserData', ud);

function movieCallbackClick(f, keydata, allData, figHandle)

clickX = keydata.IntersectionPoint(1);
clickY = keydata.IntersectionPoint(2);

pixel = round([clickY clickX]);

% fprintf(1, 'new pixel %d, %d\n', pixel(1), pixel(2));

thisPixelTrace = squeeze(allData.U(pixel(1), pixel(2), :))' * allData.V;

ud = get(figHandle, 'UserData');
if keydata.Button == 3
    % new pixel, leave the old one
    ud.pixel{end+1} = pixel;
    ud.pixelTrace(:,end+1) = thisPixelTrace;
elseif keydata.Button == 1
    ud.pixel{end} = pixel;
    ud.pixelTrace(:,end) = thisPixelTrace;
    % update the plotted spot
    set(ud.pixMarkerHandles(end), 'XData', pixel(2), 'YData', pixel(1));
end
set(figHandle, 'UserData', ud);


function closeFigure(s,c,myTimer)
stop(myTimer)
delete(myTimer);
delete(s);