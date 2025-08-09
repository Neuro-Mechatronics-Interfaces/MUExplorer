function ensureParamServer(serverDir, options)
%ENSUREPARAMSERVER  Ensure MUConnector Node server is running.
%
% Usage:
%   MUExplorer.ensureParamServer(serverDir, 'Port', 8080, 'LogFile', fullfile(tempdir,'MUConnector.log'))
%
% Behavior:
%   - If something is already listening on Port, return.
%   - Else try to start via `npm start` from serverDir.
%     * If npm not found, fall back to `node server.js`.
%     * If node_modules missing, auto-run `npm install` (or `npm ci`).
%   - Wait briefly and re-check the port; print helpful diagnostics if it fails.
%
% Args (Name-Value):
%   Port      : HTTP port to probe for liveness (required; your cfg.MUConnectorPort)
%   LogFile   : Where to dump nohup/stdout on POSIX or when using fallback
%   TimeoutS  : How long to wait for the server to be ready (default 5)
%   UseCI     : Use `npm ci` instead of `npm install` if lockfile exists (default true)

arguments
    serverDir {mustBeTextScalar, mustBeFolder}
    options.Address {mustBeTextScalar} = "127.0.0.1"; % MUConnector Address
    options.Port (1,1) double {mustBePositive, mustBeInteger} = 55556; % MUConnector Port
    options.LogFile (1,:) char = fullfile(tempdir, 'MUConnector.log')
    options.TimeoutS (1,1) double = 5
    options.UseCI (1,1) logical = true
end

address = options.Address;
port     = options.Port;
logFile  = options.LogFile;
timeoutS = options.TimeoutS;
useCI    = options.UseCI;

% 0) If already up, bail early
if iIsListening(address, port)
    fprintf('[ParamServer] Already running on %s:%d\n', address, port);
    return;
end

% 1) Check tool availability
[hasNode, nodeVer] = iHasCmd('node');
[hasNpm,  npmVer ] = iHasCmd('npm');

if ~hasNode
    warning(['[ParamServer] Node.js is not in PATH. Please install Node >= 18 ', ...
             'or add it to PATH. MUConnector parameter interface launch canceled.']);
    return;
end

% 2) Ensure dependencies
nodeModulesDir = fullfile(serverDir, 'node_modules');
lockJson       = fullfile(serverDir, 'package-lock.json');

needInstall = ~exist(nodeModulesDir,'dir');
if ~needInstall
    % cheap sanity check: if node_modules exists but is empty, treat as missing
    d = dir(nodeModulesDir);
    needInstall = numel(d) <= 2;
end

if hasNpm && needInstall
    fprintf('[ParamServer] Installing dependencies in %s (npm %s, node %s)...\n', serverDir, npmVer, nodeVer);
    if useCI && exist(lockJson,'file')
        iRunInDir(serverDir, sprintf('npm ci --silent'));
    else
        iRunInDir(serverDir, sprintf('npm install --silent'));
    end
end

% 3) Start the server
fprintf('[ParamServer] Launching server from %s\n', serverDir);
if hasNpm
    % We have npm, use the script from package.json
    iStartDetached(serverDir, 'npm start', logFile);

else
    % No npm — check if dependencies are present
    nodeModulesDir = fullfile(serverDir, 'node_modules');
    if ~exist(nodeModulesDir, 'dir')
        error(['[ParamServer] npm is not installed or not on PATH, ' ...
               'and no "node_modules" folder was found in %s.\n' ...
               'Please install Node.js and run "npm install" in that folder.'], serverDir);
    end

    % At this point, npm is missing but node_modules exists — run directly
    serverJs = fullfile(serverDir, 'server.js');
    if ~exist(serverJs, 'file')
        error('[ParamServer] server.js not found at %s', serverJs);
    end
    iStartDetached(serverDir, sprintf('node "%s"', serverJs), logFile);
end

% 4) Wait for readiness
ready = false;
pause(20); % Hopefully this is excessive
t0 = tic;
while toc(t0) < timeoutS
    if iIsListening(port)
        ready = true; break;
    end
    pause(0.3);
end

if ready
    fprintf('[ParamServer] Launch confirmed on %s:%d\n', address, port);
else
    warning('[ParamServer] Failed to detect server at %s on port %d after %.1fs.', address, port, timeoutS);
    % try to print last few lines of log on POSIX
    if ~ispc && exist(logFile,'file')
        try
            fprintf('--- %s tail ---\n', logFile);
            system(sprintf('tail -n 50 "%s"', logFile));
            fprintf('--- end tail ---\n');
        catch
        end
    end
end
end

% ===== helpers =====
function tf = iIsListening(addr,port)
try
    t = tcpclient(addr, port);
    delete(t);
    tf = true;
catch
    tf = false;
end
end

function [ok, ver] = iHasCmd(cmd)
if ispc
    [status, ~] = system(sprintf('where %s', cmd));
else
    [status, ~] = system(sprintf('which %s', cmd));
end
ok = (status == 0);
if ok
    [~, verOut] = system(sprintf('%s -v', cmd));
    ver = strtrim(verOut);
else
    ver = '';
end
end

function iRunInDir(dirPath, cmd)
if ispc
    full = sprintf('cmd /c "cd /d "%s" && %s"', dirPath, cmd);
else
    full = sprintf('bash -lc ''cd "%s" && %s''', dirPath, cmd);
end
status = system(full);
if status ~= 0
    warning('[ParamServer] Command failed: %s', cmd);
end
end

function iStartDetached(dirPath, startCmd, logFile)
if ispc
    % start a minimized window; route output to NUL
    full = sprintf('start "" /MIN cmd /c "cd /d "%s" && %s"', dirPath, startCmd);
    system(full);
else
    % nohup in background with logs
    full = sprintf('cd "%s"; nohup %s > "%s" 2>&1 &', dirPath, startCmd, logFile);
    system(full);
end
end
