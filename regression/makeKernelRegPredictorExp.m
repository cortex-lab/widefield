



function [A, winSamps, dummyEvents] = makeKernelRegPredictorExp(eventTimes, eventValues, windows, t, nTau, lambda)
%function [A, winSamps, dummyEvents] = makeKernelRegPredictor(eventTimes, eventValues, windows, t, nTau, lambda)
%
% nTau is the number of exponentials to use to fill the window (largest
% will be the extent of the window, from zero, others will be exponentially
% distributed). If window goes negative, will also put them in the negative
% direction
%
% lambda is regularization parameter for ridge regression
%
% winSamps is a cell array giving the time-axis labels for each event
%
% dummyEvents is a cell array that gives the predictor matrix for each
% event if it happened alone.

Fs = 1/mean(diff(t));
nT = length(t);

nWinSamps = zeros(1,length(windows));
for w = 1:length(windows)    
    if min(windows{w})<0 && max(windows{w})>0
        nWinSamps(w) = 2*nTau(w);
    else
        nWinSamps(w) = nTau(w);
    end
end
nWinSampsTotal = sum(nWinSamps);
csWins = cumsum([0 nWinSamps]);


A = zeros(nT,nWinSampsTotal+1); %+1 for column of ones, intercept
% A = zeros(nT,nWinSampsTotal);

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
    
    tExp = 0:1/Fs:windows{ev}(2)*3;
    tExpM = 0:1/Fs:-windows{ev}(1)*3;
    if nargout>1
        
        if min(windows{ev})<0 && max(windows{ev})>0
            d=zeros(length(tExp)+length(tExpM)-1,nWinSampsTotal);
            d(length(tExpM),csWins(ev)+(1:nWinSamps(ev))) = 1;
            winSamps{ev} = [-tExpM(end:-1:1) tExp(2:end)];
        elseif max(windows{ev})>0
            d=zeros(length(tExp),nWinSampsTotal);
            d(1,csWins(ev)+(1:nWinSamps(ev))) = 1;
            winSamps{ev} = tExp;
        else
            d=zeros(length(tExpM),nWinSampsTotal);
            d(end,csWins(ev)+(1:nWinSamps(ev))) = 1;
            winSamps{ev} = -tExpM(end:-1:1);
        end
        
    end
    
    if max(windows{ev})>0
        taus = logspace(log10(1/Fs), log10(windows{ev}(2)), nTau(ev));

        for n = 1:nTau(w)
            c = conv(A(:,csWins(ev)+n), exp(-tExp/taus(n)));
            A(:,csWins(ev)+n) = c(1:nT);

            if nargout>1
                c = conv(d(:,csWins(ev)+n), exp(-tExp/taus(n)));
                d(:,csWins(ev)+n) = c(1:size(d,1));
            end
        end
    end
    
    % convolve each column with the appropriate exponentials
    % * a better system here would be to evaluate the functions at the time
    % points in question... possibly a lot better for sharp events. But an
    % easier solution to that problem is probably just to use smaller bins.
    % 
    if min(windows{ev})<0 % include negative ones        
        taus = logspace(log10(1/Fs), log10(-windows{ev}(1)), nTau(ev));
        
        for n = 1:nTau(w)
            colInd = n+nTau(w)*(max(windows{ev})>0);
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
A(:,end) = 1;

% and the regularization
if lambda>0
    % should have pre-made A to be the right size...
    A(end+1:end+nWinSampsTotal,1:end-1) = diag(lambda*ones(1,nWinSampsTotal));
end