

function fit_kernels = kernelRegression(inSignal, t, eventTimes, eventValues, windows)
% function fit_kernels = kernelRegression(inSignal, t, eventTimes, eventValues, windows)
%
% Fits the "toeplitz regression" from Kenneth. 
%
% -- inSignal is nS by nTimePoints, any number of signals to be fit
% -- t is 1 by nTimePoints
% -- eventTimes is a cell array of times of each event
% -- eventValues is a cell array of "values" for each event, like if you want
% different instances of the event to be fit with a scaled version of the
% kernel. E.g. contrast of stimulus or velocity of wheel movement.
% -- windows is a cell array of 2 by 1 windows, [startOffset endOffset]
%
% fit_kernels is a cell array of nS by nW fit kernels
%
% Some future version of this function could allow uneven sampling of the
% input signal, but this one doesn't. 
%
% TODO: 
% - implement ridge regression with added data at the end
%
% Some future version could also allow for fitting as a sum of basis
% functions rather than this simplified "1's" method

Fs = 1/mean(diff(t));
nT = length(t);


for w = 1:length(windows)
    startOffset(w) = round(windows{w}(1)*Fs);
    nWinSamps(w) = round(diff(windows{w})*Fs);
end
nWinSampsTotal = sum(nWinSamps);
csWins = cumsum([0 nWinSamps]);


A = zeros(nT,nWinSampsTotal);

for ev = 1:length(eventTimes)
    [tp, ii] = findNearestPoint(eventTimes{ev}, t);
    eventFrames = ii+startOffset(ev);
    
    if isempty(eventValues{ev})
        theseEventValues = ones(size(eventFrames));
    else
        theseEventValues = eventValues{ev};
    end
    
    for w = 1:nWinSamps(ev)
        theseSamps = eventFrames+w;
        inRange = theseSamps>0&theseSamps<=size(A,1);
        A(theseSamps(inRange),csWins(ev)+w) = theseEventValues(inRange);
    end
end

B = A\inSignal'; % B becomes nWinSampsTotal by nS

for ev = 1:length(eventTimes)
    fit_kernels{ev} = B(csWins(ev)+1:csWins(ev+1),:);
end


