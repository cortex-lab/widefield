

function theseFiles = generateFileList(ops, vidNum)

theseFiles = {};

if isfield(ops, 'theseFiles') && ~isempty(ops.theseFiles)
    % user has provided a specific list of files to use
    theseFiles = ops.theseFiles;
    
elseif isfield(ops, 'inclExpList') && ~isempty(ops.inclExpList)
    % user has specified specific experiments to include. In this case
    % we're going to look for files in subdirectories corresponding to
    % those experiments
    
    if ops.verbose
        fprintf(ops.statusDestination, 'found subdirectories in fileBase, will look for files there\n');
    end
    for subd = ops.inclExpList
        subFileBase = fullfile(ops.fileBase, num2str(subd));
        if exist(subFileBase)
            subDTheseFiles = directoryFileList(subFileBase, ops.rawDataType);
            theseFiles = [theseFiles subDTheseFiles];
        else
            fprintf(ops.statusDestination, 'warning! Looked for files in %s but that directory did not exist.\n', subFileBase);
        end
    end
    
    
else
    
    % first check if there are subdirectories here. If so we're going to
    % use all the images in them. If not we use the images that are in this
    % folder itself.
    d = dir(fullfile(ops.vids(vidNum).fileBase)); 
    if length(d)>2
        d = d(3:end); % first two are . and ..
        isdir = [d.isdir];
        if sum(isdir)>0
            % has subdirectories
            if ops.verbose 
                fprintf(ops.statusDestination, 'found subdirectories in fileBase, will look for files there\n');
            end
            
            for subd = 1:sum(isdir)
                subFileBase = fullfile(ops.fileBase, d(subd).name);
                subDTheseFiles = directoryFileList(subFileBase, ops.rawDataType);
                theseFiles = [theseFiles subDTheseFiles];
            end
        else
            % no subdirectories, so use files that are here directly
            theseFiles = directoryFileList(ops.vids(vidNum).fileBase, ops.rawDataType);
        end
    end
end


            
function theseFiles = directoryFileList(fileBase, rawDataType)
                
switch rawDataType
    case 'tif'
        theseFilesDir = dir(fullfile(fileBase, '*.tif'));
        [~,ii] = sort([theseFilesDir.datenum]);
        theseFilesDir = theseFilesDir(ii);
    case 'customPCO'
        theseFilesDir = dir(fullfile(fileBase, '*.mat'));
        [~,ii] = sort([theseFilesDir.datenum]);
        theseFilesDir = theseFilesDir(ii);
    case 'StackSet'
        theseFilesDir = dir(fullfile(ops.fileBase, '*.bin'));
end
theseFiles = cellfun(@(x)fullfile(fileBase,x),{theseFilesDir.name},'UniformOutput', false);