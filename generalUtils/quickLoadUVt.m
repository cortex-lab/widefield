
function [U, V, t, mimg] = quickLoadUVt(expPath, nSV, varargin)
% [U, V, t, mimg] = quickLoadUVt(expPath, nSV[, params])

movieSuffix = 'blue';
if ~isempty(varargin)
    params = varargin{1};
    if isfield(params, 'movieSuffix')
        movieSuffix = params.movieSuffix;
    end
end


expRoot = fileparts(expPath);

fprintf(1, 'loading spatial components\n')
U = readUfromNPY(fullfile(expRoot, ['svdSpatialComponents_' movieSuffix '.npy']), nSV);
mimg = readNPY(fullfile(expRoot, ['meanImage_' movieSuffix '.npy']));

corrPath = fullfile(expPath, 'svdTemporalComponents_corr.npy');
if exist(corrPath, 'file')
    fprintf(1, 'loading corrected temporal components\n');
    V = readVfromNPY(corrPath, nSV);
    t = readNPY(fullfile(expPath, ['svdTemporalComponents_' movieSuffix '.timestamps.npy']));
    Fs = 1/mean(diff(t));

else
    fprintf(1, 'corrected file not found; loading uncorrected temporal components\n');
    V = readVfromNPY(fullfile(expPath, ['svdTemporalComponents_' movieSuffix '.npy']), nSV);
    t = readNPY(fullfile(expPath, ['svdTemporalComponents_' movieSuffix '.timestamps.npy']));
    Fs = 1/mean(diff(t));

    V = detrendAndFilt(V, Fs);
end

if length(t)==size(V,2)+1 % happens if there was an extra blue frame at the end
    t = t(1:end-1);
end