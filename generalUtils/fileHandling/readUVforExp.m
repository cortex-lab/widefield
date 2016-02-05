
function [U, V, t] = readUVforExp(mouseName, thisDate, expNum, varargin)
% function [U, V, t] = readUVforExp(mouseName, thisDate, expNum[, nSVtoRead])
% Returns the U, V, and t (the time indices in Timeline coordinates for a 
% given mouse, date, and expNum. Optionally reads only a subset of SVs.


filePath = dat.expPath(mouseName, thisDate, 1, 'widefield', 'master');
Upath = fileparts(filePath);

U = readUfromNPY(fullfile(Upath, 'SVD_Results_U.npy'), varargin{:});

vFilePath = fullfile([dat.expFilePath(mouseName, thisDate, expNum, 'calcium-widefield-svd', 'master') '_V.npy']);
tFilePath = fullfile([dat.expFilePath(mouseName, thisDate, expNum, 'calcium-widefield-svd', 'master') '_t.npy']);

V = readVfromNPY(vFilePath, varargin{:});
t = readNPY(tFilePath);