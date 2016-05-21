

function strobeTimes = getStrobeTimes(Timeline, rigName)
% function strobeTimes = getStrobeTimes(Timeline, rigName)
%
% Returns the times in Timeline coordinates of every camera exposure 
%
% The rigName argument is a special parameter that identifies which
% Timeline data object should be used for this, and what threshold to apply
% to detect events. See the switch/case block below. 

switch rigName
    case 'bigrig'
        strobeName = 'cam2';
        strobeThresh = 2;
    case 'bigrig2'
        strobeName = 'cam2';
        strobeThresh = 2;    
    case 'bigrig1'
        strobeName = 'cam1';
        strobeThresh = 2;
    otherwise
        error('getStrobeTimes doesn''t recognize rig name %s', rigName);
end

strobesNum = find(strcmp({Timeline.hw.inputs.name}, strobeName));

ts = Timeline.rawDAQTimestamps;
strobes = Timeline.rawDAQData(:,strobesNum);

strobeSamps = find(strobes(1:end-1)<strobeThresh & strobes(2:end)>=strobeThresh);

strobeTimes = ts(strobeSamps);