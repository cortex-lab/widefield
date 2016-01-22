

function UDPCallback(myUDP, evt, svdVidObj)

ip=myUDP.DatagramAddress;
port=myUDP.DatagramPort;
% % these are needed for proper echo
% myUDP.RemoteHost=ip;
% myUDP.RemotePort=port;
dataReceived = fread(myUDP));
dataReceivedStr = char(dataReceived');
% [instr, animal, iseries, iexp, irepeat, istim, dur] = textscan( dataReceived, '%s %s %d %d %d %d %d' )
expDat = dat.mpepMessageParse(dataReceivedStr);

fprintf(1, 'Received ''%s'' from %s:%d\n', dataReceivedStr, ip, port);



switch info.instruction
    case 'hello'
        fwrite(myUDP, dataReceivedStr); % echo for like, no reason
    case 'ExpStart'    
        
        svdVidObj.addExpDat(expDat);
        
end


        