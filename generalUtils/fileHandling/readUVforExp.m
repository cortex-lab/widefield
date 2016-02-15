
function [U, V, t] = readUVforExp(mouseName, thisDate, expNum, varargin)
% function [U, V, t] = readUVforExp(mouseName, thisDate, expNum[, nSVtoRead])
% Returns the U, V, and t (the time indices in Timeline coordinates for a 
% given mouse, date, and expNum. Optionally reads only a subset of SVs.


filePath = dat.expPath(mouseName, thisDate, 1, 'widefield', 'master');
Upath = fileparts(filePath);

U = readUfromNPY(fullfile(Upath, 'SVD_Results_U.npy'), varargin{:});

vFilePath = fullfile([dat.expFilePath(mouseName, thisDate, expNum, 'calcium-widefield-svd', 'master') '_V.npy']);

vReadFromExp = false;
if exist(vFilePath)
    V = readVfromNPY(vFilePath, varargin{:});
    vReadFromExp = true;
else    
    vFilePath = fullfile(Upath, 'SVD_Results_V.npy');
    if exist(vFilePath)
        fprintf(1, 'note: reading V from root rather than requested expNum.\n');
        V = readVfromNPY(vFilePath, varargin{:});
    else
        fprintf(1, 'could not find V.\n');
    end
end
        

if nargout>2 && vReadFromExp
    tFilePath = fullfile([dat.expFilePath(mouseName, thisDate, expNum, 'calcium-widefield-svd', 'master') '_t.npy']);
    t = readNPY(tFilePath);
elseif nargout>2
    tFilePath = fullfile(Upath, 'SVD_Results_t.npy');
    if exist(tFilePath)
        t = readNPY(tFilePath);
    else
        fprintf(1, 'could not find t.\n');
        t = [];
    end
end
