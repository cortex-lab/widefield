

function auxVid = prepareAuxVids(mouseName, thisDate, expNum)

movieDir = fileparts(dat.expFilePath(mouseName, thisDate, expNum, 'eyetracking', 'master'));

vidNum = 1;
auxVid = [];

facePath = fullfile(movieDir, 'face.mj2');
if exist(facePath, 'file')
    faceT = fullfile(movieDir, 'face_timeStamps.mat');
    if ~exist(faceT, 'file')
        alignVideo(mouseName, thisDate, expNum, 'face');
    end
    vr = VideoReader(facePath);
    load(faceT);
    auxVid(vidNum).data = {vr, tVid};
    auxVid(vidNum).f = @plotMJ2frame;
    auxVid(vidNum).name = 'face';
    vidNum = vidNum+1;
end

eyePath = fullfile(movieDir, 'eye.mj2');
if exist(eyePath, 'file')
    eyeT = fullfile(movieDir, 'eye_timeStamps.mat');
    if ~exist(eyeT, 'file')
        alignVideo(mouseName, thisDate, expNum, 'eye');
    end
    load(eyeT);
    vr = VideoReader(eyePath);
    auxVid(vidNum).data = {vr, tVid};
    auxVid(vidNum).f = @plotMJ2frame;
    auxVid(vidNum).name = 'eye';
end