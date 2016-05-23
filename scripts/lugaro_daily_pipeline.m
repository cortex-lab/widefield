% AP 160518 - run all extant pipelineHere scripts in lugaro/svdinput

%% Add relevant paths
addpath(genpath('/mnt/zserver/Code/Rigging/main'));
addpath(genpath('/mnt/zserver/Code/Rigging/cb-tools')); % for some dat package helper functions
addpath('/mnt/data/svdinput'); % for the local override of dat.paths
addpath(genpath('/mnt/data/svdinput/npy-matlab'));
addpath(genpath('/apps/widefield'));

%% Open and timestamp log file
log_file = ['/mnt/data/svdinput/svd_pipeline/svd_pipeline_logs/' datestr(now,'yyyy-mm-dd') '_svd_pipelines.txt'];
log_fid = fopen(log_file,'w+t');
fprintf(log_fid,['Started - ' datestr(now,'yyyy-mm-dd HH:MM')]);

%% Find all pipelines to run
% pipelines for each experiment are created in "pipelineHere" scripts
% the directory tree of this folder can be varied, so just search through
% all subdirectories for instances of that script

[~,pipeline_files] = system('find ''/mnt/data/svdinput'' -print | grep -i ''pipelineHere.m''');
pipeline_filenames_cell = textscan(pipeline_files,'%s','delimiter',' ');
pipeline_filenames = pipeline_filenames_cell{1};


%% Copy all data to process from zamera(s) to lugaro

for curr_pipeline = 1:length(pipeline_filenames)
    
    [pipeline_path, pipeline_name, pipeline_ext] = fileparts(pipeline_filenames{curr_pipeline});
    
    % Move to current dataset path
    cd(pipeline_path)
    fprintf(log_fid,['\n' pipeline_filenames{curr_pipeline}]);
    
    try 

        % Load options
        load ops.mat;
        
        % Copy files from zamera(s) to lugaro
        remoteDataSource = ops.remoteDataSource;
        for d = 1:length(remoteDataSource)
            r = remoteDataSource{d};
            loc = ops.localDataDest{d};
            if ops.verbose
                fprintf(1, 'copying files for data source %d from: \n   %s \nto: \n   %s\n', d, r, loc);
            end
            [success, message, messageID] = copyfile(pathForThisOS(fullfile(r, '*.tif')), pathForThisOS(loc));
            if ops.verbose && success
                % TEMPORARY FOR NICK: don't delete files from zamera
                fprintf(1, 'success. NOT deleting files from remote (temporary for Nick).\n');
                %fprintf(1, 'success. deleting files from remote.\n');
                %delete(fullfile(r, '*.tif'));
            elseif success
                % TEMPORARY FOR NICK: don't delete files from zamera
                %delete(fullfile(r, '*.tif'));
            elseif ops.verbose
                fprintf(1, 'error copying: %s.\n', message);
            end
        end
               
        % Write sucess to log
        fprintf(log_fid,[' - ' datestr(now,'HH:MM') ' copying succeeded' ]);
        
    catch me
        
        % If error, write failure and message to log
        fprintf(log_fid,[' - ' datestr(now,'HH:MM') ' copying failed (' me.message ')']);
        
    end
    
    
end

%% Run all pipelines, write successes and failures to log

for curr_pipeline = 1:length(pipeline_filenames)
    
    [pipeline_path, pipeline_name, pipeline_ext] = fileparts(pipeline_filenames{curr_pipeline});
    
    % Move to current dataset path
    cd(pipeline_path)
    fprintf(log_fid,['\n' pipeline_filenames{curr_pipeline}]);
    
    try 
        % Run pipeline
        % (in old cases where pipelineHere was script: clear results)
        clear results
        pipelineHere;
        % Write success to log
        fprintf(log_fid,[' - ' datestr(now,'HH:MM') ' succeeded' ]);
    catch me
        % If error, write failure and error to log
        fprintf(log_fid,[' - ' datestr(now,'HH:MM') ' failed (' me.message ')']);
    end
    
end


%% Timestamp and close log file

fprintf(log_fid,['\nFinished - ' datestr(now,'yyyy-mm-dd HH:MM')]);
fclose(log_fid);
















