

classdef svdVideoObj < handle
    
    % Keeps track of experiments that are going on and will perform
    % appropriate cleanup afterwards, including making an SVD
    % representation of the data for putting on the server
    %
    
    properties
        ops 
        myUDP
    end
    
    methods (Static)
        function s = svdVideoObj(a)
            % constructor 
            if nargin>0
                s = svdVideoObj;
                
                %s.ops = setSVDParams(); % defaults
                s.ops.mouseName = 'unknownMouse';
                s.ops.thisDate = 'unknownDate';
            end
            
            fprintf(1, 'svdVid object initialized\n');
            
        end
        
    end
    
    methods                
        
        function addExpDat(this, expDat)      
            fprintf(1, 'adding expDat w/in svd obj\n')
            if ~isfield(this.ops, 'expRefs') || isempty(this.ops.expRefs)
                this.ops.expRefs = {expDat.expRef};
                [subjectRef, expDate, ~] = dat.parseExpRef(expDat.expRef);
                this.ops.mouseName = subjectRef;
                this.ops.thisDate = datestr(expDate, 'yyyy-mm-dd');
                this.ops.localSavePath = fullfile('/mnt/fastssd/', this.ops.mouseName, this.ops.thisDate);
            else
                this.ops.expRefs{end+1} = expDat.expRef;
            end
        end  
        
        function describe(this)
            fprintf(1, 'SVD Video Object for %s %s\n', this.ops.mouseName, this.ops.thisDate);
        end
        
        function wizard(this)
            this.describe();
            
            nCams = input('How many cameras are you using? [1] ');
            if isempty(nCams); nCams = 1; end
            this.ops.nCams = nCams;
            this.ops.camIDNums = [];
            
            vidNum = 1;
            for n = 1:nCams
                fprintf(1, '  For camera %d:\n', n);
                
                camIDNum = input('  What is the ID number of this camera? [2] ');
                if isempty(camIDNum); camIDNum = 2; end
                this.ops.camIDNums(end+1) = camIDNum;
                
                Fs = input('  What is the total frame rate of this camera? [50] ');
                if isempty(Fs); Fs = 50; end
                
                exposureDur = input('  What is the exposure duration of this camera? [19] ');
                if isempty(exposureDur); exposureDur = 19; end
                
                flipudVid = input('  Flip up/down? [0] ');
                if isempty(flipudVid); flipudVid = 0; end
                
                nColors = input('  How many colors on this camera? [1] ');
                if isempty(nColors); nColors = 1; end
                
                if nColors>1
                    
%                     pattern = input(sprintf('    What is the pattern of colors? [] ', 1:nColors));
%                     if isempty(pattern); pattern = 1:nColors; end
                    
                    for c = 1:nColors
                        thisName = input(sprintf('    Name of color %d? [cam%dcolor%d] ', c, camIDNum, c), 's');
                        if isempty(thisName); thisName = sprintf('cam%dcolor%d', camIDNum, c); end                        
                        
                        this.ops.vids(vidNum).name = thisName;
                        this.ops.vids(vidNum).fileBase = fullfile('/mnt/data/svdinput/', this.ops.mouseName, this.ops.thisDate, sprintf('cam%d', camIDNum));
                        this.ops.vids(vidNum).frameMod = [nColors,mod(c,nColors)]; % specifies which frames are these. mod(frameNums,frameMod(1))==frameMod(2);
                        this.ops.vids(vidNum).rigName = sprintf('bigrig%d', camIDNum);
                        this.ops.vids(vidNum).Fs = Fs/nColors;
                        this.ops.vids(vidNum).exposureDur = exposureDur;
                        this.ops.vids(vidNum).flipudVid = flipudVid;
                        vidNum = vidNum+1;
                    end
                    
                else
                    
                    this.ops.vids(vidNum).name = sprintf('cam%d', camIDNum);
                    this.ops.vids(vidNum).fileBase = fullfile('/mnt/data/svdinput/', this.ops.mouseName, this.ops.thisDate, sprintf('cam%d', camIDNum));
                    this.ops.vids(vidNum).frameMod = [1,0]; % specifies which frames are these. mod(frameNums,frameMod(1))==frameMod(2);
                    this.ops.vids(vidNum).rigName = sprintf('bigrig%d', camIDNum);
                    this.ops.vids(vidNum).Fs = Fs;
                    this.ops.vids(vidNum).exposureDur = exposureDur;
                    this.ops.vids(vidNum).flipudVid = flipudVid;
                    vidNum = vidNum+1;
                    
                end                                
                
            end
            
            fprintf(1, 'You entered videos: \n');
            for v = 1:numel(this.ops.vids)
                fprintf(1, '%d: %s\n', v, this.ops.vids(v).name);
            end
            
            masterVid = input('For registration, which is the master? [1] ');
            if isempty(masterVid); masterVid = 1; end
            this.ops.masterVid = masterVid;
            
            objectiveType = input('Camera objective? [1] ', 's');
            if isempty(objectiveType); objectiveType = 1; end
            this.ops.objectiveType = objectiveType;        
            
            hasASCIIstamp = input('Using ASCII stamps? [1] ');
            if isempty(hasASCIIstamp); hasASCIIstamp = true; end
            this.ops.hasASCIIstamp = logical(hasASCIIstamp);
        
            binning = input('Binning to use (2 means 2x2, etc)? [1] ');
            if isempty(binning); binning = 1; end
            this.ops.binning = binning;
            
            userName = input('Your name? [] ', 's');
            if isempty(userName); userName = 'unknownUser'; end
            this.ops.userName = userName;
            
            switch lower(userName)
                case 'daisuke'
                    this.ops.emailAddress = 'd.shimaoka@ucl.ac.uk';
                case 'elina'
                    this.ops.emailAddress = 'elina.jacobs.13@ucl.ac.uk';
                case 'mika'
                    this.ops.emailAddress = 'efthymia.diamanti.11@ucl.ac.uk';
                case 'nick'
                    this.ops.emailAddress = 'nick.steinmetz@gmail.com';    
                otherwise
                    this.ops.emailAddress = [];
            end
            
            this.ops = svdConfig(this.ops, userName); % apply defaults to unspecified fields
            
        end
        
        function go(this)
            
            mkdir(fullfile('\\lugaro.cortexlab.net\svdinput\', this.ops.mouseName, this.ops.thisDate));
            
            for n = 1:this.ops.nCams
                mkdir(fullfile('\\lugaro.cortexlab.net\svdinput\', this.ops.mouseName, this.ops.thisDate, sprintf('cam%d', this.ops.camIDNums(n))));
            end
            
            
            ops = this.ops;
            save(fullfile('\\lugaro.cortexlab.net\svdinput\', this.ops.mouseName, this.ops.thisDate, 'ops.mat'), 'ops');
            
            fprintf(1, 'Made directories for you at %s, go copy your files there\n', fullfile('\\lugaro.cortexlab.net\svdinput\', this.ops.mouseName, this.ops.thisDate));                        
            
        end
        
        function delete(this)
            fprintf(1, 'closing udp connection\n');
            fclose(this.myUDP);
            delete(this.myUDP);
            
        end
    end
end

                
                
                