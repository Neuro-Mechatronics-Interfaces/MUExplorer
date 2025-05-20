function loadSignalDEMUSE(obj, SessionName, ExperimentNum)
%LOADSIGNALDEMUSE Load EMG signal + metadata from a DEMUSE-style mat file

arguments
    obj
    SessionName (1,1) string
    ExperimentNum (1,1) double {mustBeInteger}
end

% Construct path to DEMUSE-style .mat file
filename = sprintf('%s_%d_DEMUSE.mat', SessionName, ExperimentNum);
filepath = fullfile(obj.DataRoot, SessionName, 'MUExplorer', filename);

if ~isfile(filepath)
    error('DEMUSE signal file not found: %s', filepath);
end

fprintf('[Load] Loading DEMUSE signal file:\n  %s\n', filepath);

% Load core fields
S = load(filepath);

% Check signal shape
if ~isfield(S, 'SIG') || isempty(S.SIG)
    error('Missing SIG field in DEMUSE file.');
end

sig = S.SIG;
if iscell(sig)
    [nRow, nCol] = size(sig);
    uni = cell2mat(sig(:));  % assume SIG was stored as cell array of row vectors
else
    uni = S.SIG;  % fallback if already numeric
end

% Restore signal fields
obj.Data = uni;
obj.SampleRate = S.fsamp;
obj.RefSignal = S.ref_signal;
obj.Time = (0:size(uni,2)-1) / S.fsamp;
obj.Description = S.description;

% Optional fields
if isfield(S, 'SIGFileName')
    obj.SessionName = erase(S.SIGFileName, "_DEMU[SE]*.mat");
else
    obj.SessionName = SessionName;
end

obj.ExperimentNum = ExperimentNum;
obj.Sync = double(S.ref_signal > 0);  % Use ref_signal as proxy for sync
[obj.RefSignal, obj.CoordinatesPlateau] = obj.parseTargetPlateaus(obj.Sync);

% Path trace: smoothed, normalized signal path estimate
[b, a] = butter(1, obj.EnvelopePathSmoothingLowCut / (obj.SampleRate/2), 'low');
env = zeros(size(uni));
for iCh = 1:size(uni,1)
    env(iCh,:) = filtfilt(b, a, abs(uni(iCh,:)));
end
env = mean(env,1);
mu_rest = mean(env(~obj.RefSignal & ((1:numel(env)) > 6000) & ((1:numel(env)) < (numel(env)-6000))));
env = env - mu_rest;
env([1:6000, (end-6000):end]) = 0;
env_sort = sort(env(logical(obj.RefSignal)), 'ascend');
env = env ./ env_sort(round(0.95*numel(env_sort)));
obj.PathTrace = env;

% Set session flags
obj.Ready = true;
obj.SessionName = SessionName;
obj.ExperimentNum = ExperimentNum;

% Show updated GUI
obj.initGUI();
fprintf('[Load] Signal loaded and GUI initialized.\n');
end
