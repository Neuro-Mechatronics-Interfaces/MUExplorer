function startParamBridge(obj, options)
%STARTPARAMBRIDGE  Begin listening for JSON params on UDP loopback.
%
% Name-Value:
%   'ReprocessOnUpdate' : logical (default true)

arguments
    obj
    options.ReprocessOnUpdate (1,1) logical = true;
end

obj.ParamOnUpdateReprocess = options.ReprocessOnUpdate;

if ~isempty(obj.ParamUdp) && isvalid(obj.ParamUdp)
    return; % already running
end

test = udpportfind();
curPort =  [];
for ii = 1:numel(test)
    if test(ii).LocalPort == obj.ParamUdpLocalPort
        curPort = test(ii);
        break;
    end
end
if isempty(curPort)
    obj.ParamUdp = udpport("datagram","IPV4","LocalPort",obj.ParamUdpLocalPort);
else
    obj.ParamUdp = curPort;
end
configureCallback(obj.ParamUdp,"datagram",1,@(~,~)obj.onParamDatagram());

fprintf(1,'[ParamBridge] Listening for parameter UDP datagram packets on port %d\n', obj.ParamUdpLocalPort);
end

