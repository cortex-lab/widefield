
function p = makeContPredictor(sig, Fs, win)

if win(1)<0
    negWinSamps = -round(win(1)*Fs);
end
if win(2)>0
    posWinSamps = round(win(2)*Fs);
end

% pad sig with NaN for amount of samples that will shift around
sig = [zeros(posWinSamps,1); sig; zeros(negWinSamps,1)];

q = arrayfun(@(x)circshift(sig, [x, 0]), -negWinSamps:posWinSamps, 'UniformOutput', false);
p = horzcat(q{:});

% cut back out the invalid parts
p = p(posWinSamps+1:end-negWinSamps,:);