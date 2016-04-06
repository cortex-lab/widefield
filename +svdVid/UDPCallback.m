

function UDPCallback(myUDP, evt, svdVidObj)

ip=myUDP.DatagramAddress;
port=myUDP.DatagramPort;
% % these are needed for proper echo
myUDP.RemoteHost=ip;
myUDP.RemotePort=port;
dataReceived = fread(myUDP);
dataReceivedStr = char(dataReceived');
% [instr, animal, iseries, iexp, irepeat, istim, dur] = textscan( dataReceived, '%s %s %d %d %d %d %d' )
expDat = dat.mpepMessageParse(dataReceivedStr);





switch expDat.instruction
    case 'hello'
        fprintf(1, 'SVD video object received ''%s'' from %s:%d\n', dataReceivedStr, ip, port);
        fprintf(1, 'attempting to echo\n')
        fwrite(myUDP, dataReceived); % echo for like, no reason
    case 'ExpStart'    
        fprintf(1, 'SVD video object received ''%s'' from %s:%d\n', dataReceivedStr, ip, port);
        fprintf(1, 'attempting to echo\n')
        fwrite(myUDP, dataReceived); % echo after completing required actions
        
        fprintf(1, 'adding this experiment to svd object\n')   
        try            
            svdVidObj.addExpDat(expDat);
        catch me
            me
        end
        
    otherwise
        %fprintf('Unknown instruction : %s, echoing anyway\n', expDat.instruction);
        fwrite(myUDP, dataReceived);    
end


        