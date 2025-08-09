function onParamDatagram(obj)
rcv_tic = tic();
try
    data = read(obj.ParamUdp, 1, "string");
    msg  = strtrim(data.Data);
    j    = jsondecode(msg);
catch ME
    warning(ME.identifier, '[ParamBridge] JSON decode error: %s', ME.message);
    for ii = numel(ME.stack):-1:1
        disp(ME.stack(ii));
    end
    return;
end

% Defaults for ACK routing (can be overridden by JSON)
replyHost = "127.0.0.1";
replyPort = 55555;
txid      = "";

if isfield(j,'reply_host'), replyHost = string(j.reply_host); end
if isfield(j,'reply_port'), replyPort = double(j.reply_port); end
if isfield(j,'txid'),       txid      = string(j.txid);       end

cmd = "";
if isfield(j,'cmd'), cmd = string(j.cmd); end

ok = false;
err = "";

try
    switch cmd
        case "set_params"
            fprintf(1,'[ParamBridge] JSON parameters received: %s\n', msg);
            if isfield(j,'options') && isstruct(j.options)
                obj.applyOptionsStruct(j.options);
                fprintf(1,'[ParamBridge] Options updated from UDP.\n');

                if obj.ParamOnUpdateReprocess && ~isempty(obj.Raw)
                    obj.processSignal(obj.Raw, obj.Sync, ...
                        'AbsoluteEpsilon', j.options.AbsoluteEpsilon, ...
                        'ApplyPostLowpass', j.options.ApplyPostLowpass, ...
                        'CenterFrom',       j.options.CenterFrom, ...
                        'LowpassCutoff',    j.options.LowpassCutoff, ...
                        'RegularizationMode', j.options.RegularizationMode, ...
                        'ScaleFrom',        j.options.ScaleFrom, ...
                        'TikhonovEpsilon',  j.options.TikhonovEpsilon, ...
                        'UseRobustScale',   j.options.UseRobustScale);
                    obj.refreshLineData();
                    fprintf(1,'[ParamBridge] Reprocessed with new parameters.\n');
                end
                ok = true;
            else
                err = "Missing or invalid 'options'";
            end

        case "reprocess"
            fprintf(1,'[ParamBridge] JSON parameters received: %s\n', msg);
            if ~isempty(obj.Raw)
                obj.processSignal(obj.Raw, obj.Sync, ...
                        'AbsoluteEpsilon', j.options.AbsoluteEpsilon, ...
                        'ApplyPostLowpass', j.options.ApplyPostLowpass, ...
                        'CenterFrom',       j.options.CenterFrom, ...
                        'LowpassCutoff',    j.options.LowpassCutoff, ...
                        'RegularizationMode', j.options.RegularizationMode, ...
                        'ScaleFrom',        j.options.ScaleFrom, ...
                        'TikhonovEpsilon',  j.options.TikhonovEpsilon, ...
                        'UseRobustScale',   j.options.UseRobustScale);
                obj.refreshLineData();
                fprintf(1,'[ParamBridge] Reprocessed on request.\n');
                ok = true;
            else
                err = "No Raw data loaded";
            end
        case "ping"
            ok = true;
            err = "";
            txid = "";
        otherwise
            fprintf(1,'[ParamBridge] Unknown cmd.\n');
            err = "Unknown cmd";
    end
catch ME
    ok  = false;
    err = sprintf('%s: %s', ME.identifier, ME.message);
    for ii = numel(ME.stack):-1:1
        disp(ME.stack(ii));
    end
end

% --- Send ACK back to Node/UI ---
ack = struct( ...
    'ok', ok, ...
    'cmd', cmd, ...
    'txid', txid, ...
    'timestamp', string(datetime('now','Format','uuuu-MM-dd''T''HH:mm:ss.SSSSSS')), ...
    'error', err);

try
    payload = jsonencode(ack);
    write(obj.ParamUdp, string(payload), "string", replyHost, replyPort);
    if ~strcmpi(cmd,"ping")
        fprintf(1,'[ParamBridge] Sent ACK to %s:%d (%.2f sec elapsed)\n\t->\t%s\n', replyHost, replyPort, round(toc(rcv_tic),2),string(payload));
    end
catch ME
    warning(ME.identifier, '[ParamBridge] Failed to send ACK: %s', ME.message);
end
end
