
function [Ub, Vcorr, tb, mimgB] = quickHemoCorrect(expPath, nSV)

expRoot = fileparts(expPath);
fprintf(1, 'loading blue\n')
Ub = readUfromNPY(fullfile(expRoot, 'svdSpatialComponents_blue.npy'), nSV);
Vb = readVfromNPY(fullfile(expPath, 'svdTemporalComponents_blue.npy'), nSV);
tb = readNPY(fullfile(expPath, 'svdTemporalComponents_blue.timestamps.npy'));
mimgB = readNPY(fullfile(expRoot, 'meanImage_blue.npy'));

fprintf(1, 'loading purple\n')
Up = readUfromNPY(fullfile(expRoot, 'svdSpatialComponents_purple.npy'), nSV);
Vp = readVfromNPY(fullfile(expPath, 'svdTemporalComponents_purple.npy'), nSV);
tp = readNPY(fullfile(expPath, 'svdTemporalComponents_purple.timestamps.npy'));
mimgP = readNPY(fullfile(expRoot, 'meanImage_purple.npy'));

if size(Vb,2)>size(Vp,2)
    % can be an extra blue frame - need same number
    Vb = Vb(:,1:end-1);
end

Fs = 1/mean(diff(tb));

load(fullfile(expRoot, 'dataSummary_blue.mat'));
DSb = dataSummary;
load(fullfile(expRoot, 'dataSummary_purple.mat'));
DSp = dataSummary;

% svdviewer
svdViewer(Ub, DSb.Sv, Vb, Fs)

svdViewer(Up, DSp.Sv, Vp, Fs)


% align blue/purple in time, apply correction
Vbs = SubSampleShift(Vb,1,2); tb = tp;

VpNewU = ChangeU(Up, Vp, Ub); % puts hemo-color V into signal-color U space
% hemoFreq = [0.2,3]; % frequency to look for hemo signals, can also be heartbeat [9,13]
hemoFreq = [10 13]; % frequency to look for hemo signals, can also be heartbeat [9,13]
pixSpace = 3; % Something about subsampling the image to correct hemo
Vcorr = HemoCorrectLocal(Ub, Vbs, VpNewU, Fs, hemoFreq, pixSpace); % correct for hemodynamics

Vcorr = detrendAndFilt(Vcorr, Fs);

writeUVtoNPY([], Vcorr, [], fullfile(expPath, 'svdTemporalComponents_corr'));
writeNPY(tb,  fullfile(expPath, 'svdTemporalComponents_corr.timestamps.npy'));