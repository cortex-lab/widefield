

function fV = detrendAndFilt(V, Fs)

highpassCutoff = 0.01; % Hz
heartbeatBandStop = [9 14];

[b100s, a100s] = butter(2, highpassCutoff/(Fs/2), 'high');
[bHeart, aHeart] = butter(2, heartbeatBandStop/(Fs/2), 'stop');

dV = detrend(V', 'linear')';
fVHeart = filter(bHeart,aHeart,dV,[],2);
fV = filter(b100s,a100s,fVHeart,[],2);