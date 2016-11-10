



function [A, winSamps, dummyEvents] = makeKernelRegPredictorCos(eventTimes, eventValues, windows, t, nCos)
%function [A, winSamps, dummyEvents] = makeKernelRegPredictor(eventTimes, eventValues, windows, t, nTau)
%
% nTau is the number of exponentials to use to fill the window (largest
% will be the extent of the window, from zero, others will be exponentially
% distributed). If window goes negative, will also put them in the negative
% direction
%
% winSamps is a cell array giving the time-axis labels for each event
%
% dummyEvents is a cell array that gives the predictor matrix for each
% event if it happened alone.

Fs = 1/mean(diff(t));
nT = length(t);

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
    eventFrames = ii; % the "frames", i.e. indices of t, at which the start of each event's window occurs
    
    if isempty(eventValues{ev})
        theseEventValues = ones(size(eventFrames));
    else
        theseEventValues = eventValues{ev}(sortI);
    end
    
    
        
    % populate the matrix with appropriate event values at the time of events.    
    for e = 1:length(eventFrames)
        A(eventFrames(e), csWins(ev)+(1:nWinSamps(ev))) = theseEventValues(e);
    end
    
    tt = winSamps{ev};
    if nargout>1
        
        d=zeros(nWinSamps(ev),nWinSampsTotal);
        d(1,csWins(ev)+(1:nWinSamps(ev))) = 1;
        
    end

    % specify that there are nCos raised cosines, that they tile the window
    % of interest, that they have width such that they are separated by
    % pi/2 radians of phase.
    cosSep = pi/2;
%     cosT =  
    
    for n = 1:nTau(w)
        c = conv(A(:,csWins(ev)+n), exp(-tExp/taus(n)));
        A(:,csWins(ev)+n) = c(1:nT);
        
        if nargout>1
            c = conv(d(:,csWins(ev)+n), exp(-tExp/taus(n)));
            d(:,csWins(ev)+n) = c(1:size(d,1));
        end
    end
    
    % convolve each column with the appropriate exponentials
    if min(windows{ev})<0 % include negative ones        
        taus = logspace(log10(1/Fs), log10(-windows{ev}(1)), nTau(ev));
        
        for n = 1:nTau(w)
            colInd = n+nTau(w);
            c = conv(A(end:-1:1,csWins(ev)+colInd), exp(-tExpM/taus(n)));
            c = c(1:nT);
            A(:,csWins(ev)+colInd) = c(end:-1:1);
            
            if nargout>1
                c = conv(d(end:-1:1,csWins(ev)+colInd), exp(-tExpM/taus(n)));
                c = c(1:size(d,1));
                d(:,csWins(ev)+colInd) = c(end:-1:1);
            end
            
        end
    end
    
    if nargout>1
        
        dummyEvents{ev} = d;
        
    end
    
    
end

% finally, add a column of ones
% A(:,end+1) = 1;
% if nargout>1
%     for ev = 1:length(eventTimes)
%         dummyEvents{ev}(:,end+1) = 1;
%     end
% end