

function s = listen()

% start the svdVid object
s = svdVid('-');

% Now setup the UDP communication - code from +et, Krumin

% The Remote Host IP doesn't really matter here, it is just a placeholder
% For bidirectional communication echo will be sent to the IP the command
% was received from
fakeIP = '1.1.1.1';
myUDP = udp(fakeIP, 1103, 'LocalPort', 1001);
fopen(myUDP);
set(myUDP, 'DatagramReceivedFcn', @(src, evt)svdVid.UDPCallback(src, evt, s));
