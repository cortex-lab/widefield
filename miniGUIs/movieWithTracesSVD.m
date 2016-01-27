

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
end

figHandle = figure; 

ud.currentFrame = 1;
ud.rate = 1;
ud.playing = true;
ud.figInitialized = false;

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

if ~ud.figInitialized
%     ax = subtightplot(1,2,1, 0.01, 0.01, 0.01);    
    ax = axes();
    ud.ImageAxisHandle = ax;
    myIm = imagesc(svdFrameReconstruct(allData.U, allData.V(:, ud.currentFrame)));     
    ud.ImageHandle = myIm;
    caxis([-0.15 0.15]);
    colormap(colormap_blueblackred);
    axis equal tight;
    colorbar
    axis off        
    
    % initialize any trace plots here. Use subtightplot and axis off except
    % the bottom one. 
    
    
    
    ud.figInitialized = true;
end

if ud.playing
    set(ud.ImageHandle, 'CData', svdFrameReconstruct(allData.U, allData.V(:, ud.currentFrame)));    
    
    set(get(ud.ImageAxisHandle, 'Title'), 'String', sprintf('frame %d, rate %d', ud.currentFrame, ud.rate));              
    
    drawnow;
    ud.currentFrame = ud.currentFrame+ud.rate;
    
    if ~isempty(ud.WriterObj) && ud.recording
        frame = getframe;
        writeVideo(ud.WriterObj,frame);
    end
end

set(figHandle, 'UserData', ud);




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

function closeFigure(s,c,myTimer)
stop(myTimer)
delete(myTimer);
delete(s);