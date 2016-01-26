

function strobeTimes = getStrobeTimes(Timeline, rigName)

switch rigName
    case 'bigrig'
        strobeName = 'cam2';
        strobeThresh = 2;
    otherwise
        error('getStrobeTimes doesn''t recognize rig name %s', rigName);
end

strobesNum = find(strcmp({Timeline.hw.inputs.name}, strobeName));

ts = Timeline.rawDAQTimestamps;
strobes = Timeline.rawDAQData(:,strobesNum);

strobeSamps = find(strobes(1:end-1)<strobeThresh & strobes(2:end)>=strobeThresh);

strobeTimes = ts(strobeSamps);