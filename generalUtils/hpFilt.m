
function [filtV, vars] = hpFilt(V, Fs, cutoffFreq)
% function [filtV, vars] = hpFilt(V, Fs, cutoffFreq)
% recommended cutoffFreq = 0.01 (Hz). 

order = 3;
Wn = cutoffFreq/Fs/2;
[b,a]=butter(order, Wn, 'high');

filtV = single(filtfilt(b,a,double(V')))';
vars = [];