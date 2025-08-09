function stopParamBridge(obj)
%STOPPARAMBRIDGE  Stop listening / release UDP port.
if ~isempty(obj.ParamUdp)
    try
        configureCallback(obj.ParamUdp,"off");
        clear obj.ParamUdp; % releases port
    catch
    end
    obj.ParamUdp = [];
    fprintf(1,'[ParamBridge] Stopped.\n');
end
end