

function movieWithTracesSVDmulti(U, V, t, traces, movieSaveFilePath, frameGenFunc)
% function movieWithTracesSVD(U, V, t, traces, movieSaveFilePath)
% - U is yPix x xPix x nSV
% - V is nSV x nTimePoints
% - t is 1 x nTimePoints, the labels of V
% - traces is a struct array with three fields:
%   - t is 1 x nTimePoints
%   - v is 1 x nTimePoints
%   - name is a string
% - frameGenFunc is a handle to a function that takes U and V and returns
% the frames or pixel traces. It is called like this:
%   frameGenFunc(U, V, thisData, mode) 
% where mode is 'frames' or 'pixel'. If mode is pixel, thisData should be 
% the pixel coordinates; if frames it should be the frame number.
% If frameGenFunc is left empty the default is defaultFrameGen, at the 
% bottom of this file
%
% Usage:
% - 'p' plays/pauses
% - 'r' starts/stops recording, if playing
% - up/down arrow keys increase/decrease playback rate
% - alt+arrowkeys changes view
% - click to change the location of the plotted point. 
%   - right click to add a new point
%   - 'c' to clear the plotted points, leaving only the last one
% - '-' and '=' change the caxis, scaling up and down. It will stay
% centered around zero though. 
%
% NOTE! The caxis is set like it's a DF/F movie. 


allData.U = U;
allData.V = V;
allData.t = t;
if ~isempty(traces)
    allData.traces = traces;
else
    allData.traces = [];
end

if ~isempty(frameGenFunc)
    ud.frameGen = frameGenFunc;
else
    ud.frameGen = @defaultFrameGen;
end

figHandle = figure; 

ud.currentFrame = 1;
ud.rate = 1;
ud.playing = true;
ud.figInitialized = false;
ud.pixel = [1 1];
% ud.pixelTrace = (squeeze(allData.U(ud.pixel{1}(1), ud.pixel{1}(2), :))' * allData.V)';
[ud.pixelTrace, ud.frameNames] = ud.frameGen(U, V, ud.pixel, 'pixel');

ud.cax = [-0.4 0.4];

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


if ~isempty(movieSaveFilePath) && exist('movieSaveFilePath')
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

cax = ud.cax;

if ~ud.figInitialized
    
    firstFrames = ud.frameGen(allData.U, allData.V, 1, 'frames'); % firstFrames will be a cell array
    nFrames = length(firstFrames);
    
    for fr = 1:nFrames
        ax = subtightplot(2,nFrames,fr, 0.01, 0.01, 0.01);    
        ud.ImageAxisHandle(fr) = ax;
        myIm = imagesc(firstFrames{fr});     
        ud.ImageHandle(fr) = myIm;
        caxis(cax);
        colormap(colormap_blueblackred);
        axis equal tight;
        colorbar    
    %     set(myIm, 'HitTest', 'off');
        set(myIm, 'ButtonDownFcn', @(f,k)movieCallbackClick(f, k, allData, figHandle));
        hold on;
        q = plot(ax, ud.pixel(2), ud.pixel(1), 'ko', 'MarkerFaceColor', pixColors(fr,:));
        ud.pixMarkerHandles(fr) = q;        
        axis off 
    end
    
    % initialize any trace plots here. Use subtightplot and axis off (except
    % the bottom one?)     
    nSP = length(allData.traces)+1;
    currTime = allData.t(ud.currentFrame);    
    for tInd = 1:nSP-1
        ax = subtightplot(nSP*2,1,nSP+tInd, 0.01, 0.01, 0.01);
        ud.traceAxes(tInd) = ax;
        thisT = allData.traces(tInd).t;
        inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');
        q = plot(thisT(inclT), allData.traces(tInd).v(inclT));
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
        
        annotation('textbox', get(ax, 'Position'), 'String', allData.traces(tInd).name, ...
            'EdgeColor', 'none', 'FontSize', 14);
    end
    
    % one more for the selected pixel
    ax = subtightplot(nSP*2,1,nSP*2, 0.01, 0.01, 0.01);
    ud.traceAxes(nSP) = ax;
    thisT = allData.t;
    inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');
    for trInd = 1:length(ud.pixelTrace)
        q = plot(thisT(inclT), ud.pixelTrace{trInd}(inclT), 'Color', pixColors(trInd,:)); 
        ud.traceHandles{nSP}(trInd) = q;        
        hold on;
    end
    yl = ylim();
    axis off
    legend(ud.frameNames); legend boxoff;
    q = plot([currTime currTime], yl, 'k--');    
    ud.traceZeroBars(nSP) = q;
    xlim([currTime-5 currTime+5]);
    makepretty;
    
    ud.figInitialized = true;
    set(figHandle, 'UserData', ud);
end

if ud.playing
    
    newFrameData = ud.frameGen(allData.U, allData.V, ud.currentFrame, 'frames');
    
    for fr = 1:length(newFrameData)
        set(ud.ImageHandle(fr), 'CData', newFrameData{fr});                
    end    
    
    currTime = allData.t(ud.currentFrame);
    set(get(ud.ImageAxisHandle(1), 'Title'), 'String', sprintf('time %.2f, rate %d', currTime, ud.rate));              
    
    nSP = length(allData.traces)+1;
    for n = 1:nSP
        ax = ud.traceAxes(n);        
        set(ud.traceZeroBars(n), 'XData', [currTime currTime]);
        
        if n<nSP
            thisT = allData.traces(n).t;
            inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');
            set(ud.traceHandles{n}, 'XData', thisT(inclT), 'YData', allData.traces(n).v(inclT));
        elseif n==nSP            
            % last plot is the pixel traces
            thisT = allData.t;
            inclT = find(thisT>currTime-windowSize/2,1):find(thisT<currTime+windowSize/2,1,'last');                                                            
            
            for tr = 1:length(ud.traceHandles{n})
                thisHand = ud.traceHandles{n}(tr);
                set(thisHand, 'XData', thisT(inclT), 'YData', ud.pixelTrace{tr}(inclT));
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



% rotating the view (this property is now obsolete in Matlab, but still
% works)
if isequal(keydata.Modifier, {'alt'})
    ax = ud.ImageAxisHandle;
    currentView = get(ax(1), 'View');
    
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
    for axInd = 1:length(ax)
        set(ax{axInd}, 'View', newView);
    end
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
    case 'hyphen' % scale cax down
        ud.cax = ud.cax*0.75;
        for axInd = 1:length(ud.ImageAxisHandle)
            caxis(ud.ImageAxisHandle(axInd), ud.cax);
        end
    case 'equal' % scale cax up
        ud.cax = ud.cax*1.25;
        for axInd = 1:length(ud.ImageAxisHandle)
            caxis(ud.ImageAxisHandle(axInd), ud.cax);
        end
        
end
set(figHandle, 'UserData', ud);

function movieCallbackClick(f, keydata, allData, figHandle)

clickX = keydata.IntersectionPoint(1);
clickY = keydata.IntersectionPoint(2);

pixel = round([clickY clickX]);

ud = get(figHandle, 'UserData');
thisPixelTrace = ud.frameGen(allData.U, allData.V, pixel, 'pixel');

ud.pixel = pixel;
ud.pixelTrace = thisPixelTrace;
set(figHandle, 'UserData', ud);

% update the plotted spots
for ind = 1:length(ud.pixMarkerHandles)
    set(ud.pixMarkerHandles(ind), 'XData', pixel(2), 'YData', pixel(1));
end


function closeFigure(s,c,myTimer)
stop(myTimer)
delete(myTimer);

ud = get(s, 'UserData');
if ~isempty(ud.WriterObj)
    close(ud.WriterObj);
end

delete(s);


function [outData, frNames] = defaultFrameGen(U, V, thisData, mode)
% default assumes V is a cell array, and you want one frame per V

switch mode
    case 'frames'
        % here, thisData is the current frame number
        
        for fr = 1:length(V)
            outData{fr} = svdFrameReconstruct(U, V{fr}(:,thisData));
        end
        
    case 'pixel'        
        % here, thisData is the pixel coordinates
        
        for fr = 1:length(V)
            outData{fr} = squeeze(U(thisData(1), thisData(2), :))' * V{fr};
        end
end

if nargout>1
    frNames = cellfun(@num2str, num2cell(1:length(V)), 'UniformOutput', false);
end
