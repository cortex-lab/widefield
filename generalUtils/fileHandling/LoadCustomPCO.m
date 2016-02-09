function [nRows, nCols, TimeStamps, Stack] = LoadCustomPCO(FileName, doDisplay, doCorrect)
% Loads a PCO file and returns either basic info or the whole stack
%
% [nRows, nCols, TimeStamps] = LoadPCO(FileName)
% returns only the basic info (very quick).
%
% [nRows, nCols, TimeStamps, Stack] = LoadPCO(FileName)
% returns the whole stack of data (can be slow).
%
% [] = LoadPCO(FileName, doDisplay)
% if doDisplay = true, display message (default: false)
%
% [] = LoadPCO(FileName, doDisplay, doCorrect)
% if doCorrect = true, can eliminate the first and/or last frame by referreing
% TimeStamps (default: true)
%
% 2013-10-03 Matteo Carandini
% 2014-01-04 DS added doDisplay input
% 2014-03-02 DS added doCorrect option
% 2014-11-05 DS modified. Return empty TimeStamps & Stack if mmap if
% collapsed

if nargin < 3
    doCorrect = true;
end
if nargin < 2
    doDisplay = false;
end

[~, ShortFileName, ~] = fileparts(FileName);

if nargout < 4
    GetInfoOnly = true;
    if doDisplay
        fprintf('Getting basic info on PCO file %s. ', ShortFileName)
    end
else
    GetInfoOnly = false;
    if doDisplay
        fprintf('Loading stack from PCO file %s. ', ShortFileName)
    end
end


fid = fopen(FileName, 'r');
if fid == -1, error(['Unable to open file: ' FileName]); end
nRows   = fread(fid, 1, 'uint32'); % spatial resolution, n rows
nCols   = fread(fid, 1, 'uint32'); % spatial resolution, n columns
nFrames = fread(fid, 1, 'uint32');
fclose(fid);

format = { ...
    'uint32' 1 'nRows';...                % Number of rows.
    'uint32' 1 'nCows';...                % Number of columns.
    'uint32' 1 'nFrames';...              % Number of frames.
    'double' 1 'startTime';...            % Time of first frame in UNIX format.
    'uint16' [nRows nCols nFrames] 'imagedata';... % Image data.
    'double', [nFrames 1], 't'};           % Time of each frame in seconds.
m = memmapfile(FileName, 'Format', format);

try
    
    TimeStamps = m.Data(1).t;
    
    FrameInterval = median(diff(TimeStamps));
    
    
    if doCorrect
        % if there is long gap between first two frames, drop the 1st
        if diff(TimeStamps(1:2)) > 2.0 *FrameInterval
            if doDisplay
                fprintf('Correcting first frame. ');
            end
            TimeStamps = TimeStamps(2:end) - TimeStamps(2);
            
            if ~GetInfoOnly
                Stack = m.Data(1).imagedata(:,:,2:end); %14.1.13 - DS
            end
        elseif ~GetInfoOnly
            Stack = m.Data(1).imagedata; %14.1.13 - DS
            
        end
        % if there is zero gap between last two frames, drop the last
        if diff(TimeStamps(end-1:end)) < 0.5 *FrameInterval
            if doDisplay
                fprintf('Correcting last frame. ');
            end
            TimeStamps = TimeStamps(1:end-1);
            
            if ~GetInfoOnly
                Stack = Stack(:,:,1:end-1); %14.1.13 - DS
            end
        end
        % interpolate if there is a missing frame
        if max(diff(TimeStamps)) > 1.5*FrameInterval
            new_tt = TimeStamps;
            
            th = 1.5 * median(diff(new_tt)); %DS on 8/4/14...assuming outliers are double of 1/framerate
            if (th-median(diff(new_tt)))<median(diff(new_tt))/100,
                th = median(diff(new_tt))+median(diff(new_tt))/100; %AP to avoid infinite loop
            end
            [r c v] = find(diff(new_tt)>th);
            if ~isempty(r), fprintf('Fixing missing frames (mmap)\n'); end
            
            
            while ~isempty(r)
                % find how many frames are missing in that gap
                gapSize  = round( (new_tt(r(1)+1) - new_tt(r(1)))/median(diff(new_tt)) )-1;
                % create a vector of missing times
                missVect = new_tt(r(1)) + [1:gapSize].*median(diff(new_tt));
                % add the time vector
                new_tt   = [new_tt(1:r(1)); missVect(:); new_tt(r(1)+1:end)];
                
                if ~GetInfoOnly
                    ss = double(Stack);
                    %Use this for tensor interpolation
                    [xi yi zi] = meshgrid(1:nCols,1:nRows,linspace(1,2,length(missVect)+2));
                    iT = interp3(single(ss(:,:,r(1):r(1)+1)),xi,yi,zi);%28/5/14 DS changed to single
                    iT = iT(:,:,2:end-1); % take only the interpolated ones
                    Stack = cat(3,cat(3,ss(:,:,1:r(1)), iT), ss(:,:,r(1)+1:end));
                    display('Missed Frames were interpolated with interp3  (mmap)');
                                     
                end
                % check if there are still gaps with missing frames
                [r c v]  = find(diff(new_tt) > th);
            end
            
            TimeStamps = new_tt;
            if ~GetInfoOnly
                Stack = uint16(Stack);
            end
        end
    end
    
    if doDisplay
        fprintf('\n');
    end
    
    if GetInfoOnly, return;
    elseif ~doCorrect
        Stack  = m.Data(1).imagedata; %14.3.3 - DS
        
    end
    
catch err
    TimeStamps = [];
    Stack = [];
    disp([FileName ' is empty. ']);
end

