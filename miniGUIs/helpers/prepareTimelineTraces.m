
function traces = prepareTimelineTraces(Timeline)

tt = Timeline.rawDAQTimestamps;
tInd = 0;

if sum(strcmp({Timeline.hw.inputs.name}, 'rotaryEncoder'))>0
    wheelRaw = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, 'rotaryEncoder'));
    wheelRaw = wheel.correctCounterDiscont(wheelRaw);
    wheelFs = 200;
    wt = 0:1/wheelFs:tt(end);
    w = interp1(tt, wheelRaw, wt);
    [vel, ~] = wheel.computeVelocity(w, 50, wheelFs);
    tInd = tInd+1;
    traces(tInd).t = wt;
    traces(tInd).v = vel;
    traces(tInd).name = 'wheelVelocity';
    traces(tInd).lims = [-1 1]*max(abs(vel))*0.75;
end

tlName = 'rewardEcho';
if sum(strcmp({Timeline.hw.inputs.name}, tlName))>0
    rew = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, tlName));
    rewEvents = schmittTimes(tt, rew, [2 3]); 
    if ~isempty(rewEvents) % there's at least one reward so include behavior things
        tInd = tInd+1;
        traces(tInd).t = tt;
        traces(tInd).v = rew;
        traces(tInd).name = 'reward';
        traces(tInd).lims = [-0.1 5.1];

        tInd = tInd+1;
        tlName = 'audioMonitor';
        traces(tInd).t = tt;
        traces(tInd).v = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, tlName));
        traces(tInd).name = 'audio';
        traces(tInd).lims = [-1 1];

        tInd = tInd+1;
        tlName = 'piezoLickDetector';
        traces(tInd).t = tt;
        lickSig = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, tlName));
        traces(tInd).v = lickSig;
        traces(tInd).name = 'licks';
        traces(tInd).lims = [min(lickSig) max(lickSig)];
    end
end

tInd = tInd+1;
tlName = 'photoDiode';
traces(tInd).t = tt;
traces(tInd).v = Timeline.rawDAQData(:,strcmp({Timeline.hw.inputs.name}, tlName));
traces(tInd).name = 'photodiode';
traces(tInd).lims = [0 max(traces(tInd).v)];