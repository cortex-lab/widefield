

% New pipeline script. 
% As before, first set options variable "ops". 

load ops.mat; % this must be present in the current directory
diaryFilename = sprintf('svdLog_%s_%s.txt', ops.mouseName, ops.thisDate);
diary(diaryFilename);

if ~exist(ops.localSavePath, 'dir')
    mkdir(ops.localSavePath);
end
save(fullfile(ops.localSavePath, 'ops.mat'), 'ops');

%% load all movies into flat binary files

for v = 1:length(ops.vids)
    
    ops.theseFiles = [];
    theseFiles = generateFileList(ops, v);
    
    ops.vids(v).theseFiles = theseFiles;
    ops.theseFiles = theseFiles;
    
    ops.vids(v).thisDatPath = fullfile(ops.localSavePath, ['vid' num2str(v) 'raw.dat']);
    
    dataSummary = loadRawToDat(ops, v);
    
    fn = fieldnames(dataSummary);
    for f = 1:length(fn)
        results.vids(v).(fn{f}) = dataSummary.(fn{f});
    end
    
    save(fullfile(ops.localSavePath, 'results.mat'), 'results');
end

%% do image registration? 
% Register the blue image and apply the registration to the other movies
if ops.doRegistration
    % if you want to do registration, we need to first determine the
    % target image.
    tic
    if ops.verbose
        fprintf(ops.statusDestination, 'determining target image\n');
    end
    [targetFrame, nFr] = generateRegistrationTarget(ops.fileBase, ops);
    ops.Nframes = nFr;
    toc
else
    targetFrame = [];
end

%% do hemodynamic correction?



%% perform SVD
for v = 1:length(ops.vids)
    fprintf(ops.statusDestination, ['svd on ' ops.vids(v).name]);
    
    ops.Ly = results.vids(v).imageSize(1); ops.Lx = results.vids(v).imageSize(2); % not actually used in SVD function, just locally here

    if ops.doRegistration
        minDs = min(dataSummary.regDs, [], 1);
        maxDs = max(dataSummary.regDs, [], 1);

        ops.yrange = ceil(maxDs(1)):floor(ops.Ly+minDs(1));
        ops.xrange = ceil(maxDs(2)):floor(ops.Lx+minDs(2));    
    else
        ops.yrange = 1:ops.Ly; % subselection/ROI of image to use
        ops.xrange = 1:ops.Lx;
    end
    ops.Nframes = numel(results.vids(v).timeStamps); % number of frames in whole movie

    ops.mimg = results.vids(v).meanImage;

    ops.ResultsSaveFilename = [];
    ops.theseFiles = ops.vids(v).theseFiles;
    ops.RegFile = ops.vids(v).thisDatPath;
    
    tic
    [ops, U, Sv, V, totalVar] = get_svdcomps(ops);
    toc
    
    results.vids(v).U = U;
    results.vids(v).V = V;
    results.vids(v).Sv = Sv;
    results.vids(v).totalVar = totalVar;
    
    % what to do about this? Need to save all "vids" - where?
    % fprintf(1, 'attempting to save to server\n')
    % saveSVD(ops, U, V, dataSummary)
    
end

%% save

fprintf(1, 'saving locally\n');
save(fullfile(ops.localSavePath, 'results.mat'), 'results', '-v7.3');



fprintf(1, 'done\n');
diary off;

if isfield(ops, 'emailAddress') && ~isempty(ops.emailAddress)
    mail = 'lugaro.svd@gmail.com'; %Your GMail email address
    password = 'xpr!mnt1'; %Your GMail password
    
    % Then this code will set up the preferences properly:
    setpref('Internet','E_mail',mail);
    setpref('Internet','SMTP_Server','smtp.gmail.com');
    setpref('Internet','SMTP_Username',mail);
    setpref('Internet','SMTP_Password',password);
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','465');    
                                                                                                                                                                         messages = {'I am the SVD master.', 'But I can''t help the fact that your data sucks.', 'Decomposing all day, decomposing all night.', 'You''re welcome.', 'Now you owe me a beer.'};    
    % Send the email
    sendmail(ops.emailAddress,[ops.mouseName '_' ops.thisDate ' finished.'], ...
        messages{randi(numel(messages),1)}, diaryFilename);

end

% save(fullfile(ops.localSavePath, 'done.mat'), []);
% Instead, copy the folder of raw files into the /mnt/data/toArchive folder
destFolder = fullfile('/mnt/data/toArchive/', ops.mouseName, ops.thisDate);
mkdir(destFolder);
movefile(fullfile('/mnt/data/svdinput/', ops.mouseName, ops.thisDate, '*'), destFolder);
