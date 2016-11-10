

function [A, winSamps, dummyEvents] = makeKernelRegPredictor(eventTimes, eventValues, windows, t)
%function [A, winSamps, dummyEvents] = makeKernelRegPredictor(eventTimes, eventValues, windows, t)
%
% winSamps is a cell array giving the time-axis labels for each event
%
% dummyEvents is a cell array that gives the predictor matrix for each
% event if it happened alone.

Fs = 1/mean(diff(t));
nT = length(t);

startOffset = zeros(1,length(windows));
nWinSamps = zeros(1,length(windows));
for w = 1:length(windows)
    startOffset(w) = round(windows{w}(1)*Fs);
    nWinSamps(w) = round(diff(windows{w})*Fs);
    winSamps{w} = ((1:nWinSamps(w))+startOffset(w))/Fs;
end
nWinSampsTotal = sum(nWinSamps);
csWins = cumsum([0 nWinSamps]);


% A = zeros(nT,nWinSampsTotal+1); %+1 for column of ones, intercept
A = zeros(nT,nWinSampsTotal);

for ev = 1:length(eventTimes)
    [theseET, sortI] = sort(eventTimes{ev}(:)');
    [tp, ii] = findNearestPoint(theseET, t);
    eventFrames = ii+startOffset(ev); % the "frames", i.e. indices of t, at which the start of each event's window occurs
    
    if isempty(eventValues{ev})
        theseEventValues = ones(size(eventFrames));
    else
        theseEventValues = eventValues{ev}(sortI);
    end
    
    % populate the toeplitz matrix with appropriate event values
    d = zeros(nWinSamps(ev), nWinSampsTotal);
    for w = 1:nWinSamps(ev)
        theseSamps = eventFrames+w;
        inRange = theseSamps>0&theseSamps<=size(A,1);
        A(theseSamps(inRange),csWins(ev)+w) = theseEventValues(inRange);
        
        if nargout>2
            d(w, csWins(ev)+w) = 1;
        end
    end
    
    if nargout>2
        
        dummyEvents{ev} = d;
        
    end
    
    
end

% finally, add a column of ones
% A(:,end) = 1;