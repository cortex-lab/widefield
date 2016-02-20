
% Script to rotate one image to match the other

%% 

baseImage = U(:,:,1);
inputImage = U2(:,:,1);

doFlipVert = true;

if doFlipVert
    inputImage = flipud(inputImage);
end

%% click matching points
figure; 

subplot(1, 2,1);
imagesc(baseImage);
title('click first a point here')

subplot(1,2,2); 
imagesc(inputImage);
title('then the matching point here (ctrl-c when finished)'); 


%%
basePoints = [];
inputPoints = [];
thisIm = 1;
while 1
    [x,y] = ginput(1);
    
    if thisIm==1
        basePoints(end+1,1) = x;
        basePoints(end,2) = y;
        thisIm= 2;
        subplot(1,2,1);
        hold on; 
        plot(x,y,'ro');
    else
        inputPoints(end+1,1) = x;
        inputPoints(end,2) = y;
        thisIm= 1;
        subplot(1,2,2);
        hold on; 
        plot(x,y,'ro');
    end
end

%% 

method = 'nonreflective similarity';

t_concord = cp2tform(inputPoints,basePoints, method);

if strcmp(method, 'nonreflective similarity')
    Tinv = t_concord.tdata.Tinv;%is this ok?
    ss = Tinv(2,1);
    sc = Tinv(1,1);
    scale_recovered = sqrt(ss*ss + sc*sc);%<1: fitted map is smaller than original anderman's map
    theta_recovered = atan2(ss,sc)*180/pi;
end


[inputPointsRX, inputPointsRY] = tformfwd(t_concord, inputPoints(:,1),inputPoints(:,2));
figure; 
plot(basePoints(:,1), basePoints(:,2), '.')
hold on; 
plot(inputPoints(:,1), inputPoints(:,2), 'o')
plot(inputPointsRX, inputPointsRY, 'x')
%Transform  Image
newInputImage = imtransform(inputImage, t_concord,'XData',[1 size(baseImage,2)], 'YData',[1 size(baseImage,1)]);


figure; imagesc(newInputImage)
    

%% rotate everything

newU = zeros(size(baseImage,1),size(baseImage,2),size(U,3), 'like', U);
for uInd = 1:size(U,3)
    msg = sprintf('%d... ', uInd);
    fprintf(1, msg);
    
    if doFlipVert
        thisIm = flipud(U(:,:,uInd));
    else
        thisIm = U(:,:,uInd);
    end
    
    newU(:,:,uInd) = imtransform(thisIm, t_concord,'XData',[1 size(baseImage,2)], 'YData',[1 size(baseImage,1)]);
    
    fprintf(repmat('\b', 1, numel(msg)));
end
fprintf(1, 'done\n');
    