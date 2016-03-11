

function [frameNums, timestampsAsDatenum] = timeFromPCOBinaryMulti(records)
% records is 14xN for N frames

nfr = size(records,2);

dic = zeros(14,nfr,2, 'like', records);

dic(:,:,2) = mod(records,16);
dic(:,:,1) = (records-dic(:,:,2))/16;

dicd = dic(:,:,1)*10+dic(:,:,2);

frameNums = dicd(1,:)*1000000 + dicd(2,:)*10000 + dicd(3,:)*100 + dicd(4,:);

year = dicd(5,:)*100+dicd(6,:);
mo = dicd(7,:);
day = dicd(8,:);
hr = dicd(9,:);
min = dicd(10,:);
sec = dicd(11,:) + dicd(12,:)/100 + dicd(13,:)/10000 + dicd(14,:)/1000000;
timestampsAsDatenum = datenum(year, mo, day, hr, min, sec);