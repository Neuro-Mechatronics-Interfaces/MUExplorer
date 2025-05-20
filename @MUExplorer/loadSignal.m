function loadSignal(obj, SessionName, ExperimentNum)
%LOADSIGNAL Load EMG and Sync Data from a TMSi session

arguments
    obj
    SessionName (1,1) string
    ExperimentNum (1,1) double {mustBeInteger}
end

baseDir = fullfile(obj.DataRoot, SessionName);
inputDir = fullfile(baseDir, obj.InputSubfolder);
expBase = sprintf('%s_%d', SessionName, ExperimentNum);
dataPath = fullfile(inputDir, sprintf("%s%s", expBase, obj.InputSuffix)); 
if ~isfile(dataPath)
    error('File not found: %s', dataPath);
end

S = load(dataPath);
if isfield(S,'sample_rate')
    fs = S.sample_rate;
elseif isfield(S, 'fs')
    fs = S.fs;
elseif isfield(S, 'fsamp')
    fs = S.fsamp;
else
    error("Must include sample rate (sample_rate, fs, or fsamp variable name) in loaded data file.");
end
obj.SampleRate = fs;

layoutPath = fullfile(baseDir, obj.LayoutFile);
if exist(layoutPath,'file')
    layout = load(layoutPath, 'REMAP');
    REMAP = layout.REMAP;
else
    REMAP = 1:size(S.uni,1);
    warning("No %s (layout file) detected in session folder. No channel remap applied.", obj.LayoutFile);
end

if isfield(S,'uni')
    uni = S.uni(REMAP, :);
elseif isfield(S, 'SIG')
    uni = S.SIG(REMAP);
    if iscell(uni)
        uni = vertcat(uni{:});
    end
elseif isfield(S, 'data')
    uni = S.data(REMAP,:);
end
if isfield(S,'sync')
    sync = S.sync;
elseif isfield(S,'ref_signal')
    sync = S.ref_signal;
elseif isfield(S, 'aux')
    sync = S.aux;
else
    sync = zeros(1,size(uni,2));
end

% Add lowpass envelope estimate for path
[ref_signal, coordinatesPlateau] = obj.parseTargetPlateaus(sync);
[b, a] = butter(1, obj.EnvelopePathSmoothingLowCut / (obj.SampleRate/2), 'low');
env = zeros(size(uni));
for iCh = 1:size(uni,1)
    env(iCh,:) = filtfilt(b, a, abs(uni(iCh,:)));
end
env = mean(env,1);
mu_rest = mean(env(~ref_signal & ((1:numel(env)) > 6000) & ((1:numel(env)) < (numel(env)-6000))));
env = env - mu_rest;
env([1:6000, (end-6000):end]) = 0;
env_sort = sort(env(logical(ref_signal)),'ascend');
env = env ./ env_sort(round(0.95*numel(env_sort)));
% Store everything into class properties
obj.Data = uni;
obj.SampleRate = S.sample_rate;
obj.Time = (0:size(uni,2)-1) / obj.SampleRate;
obj.Sync = sync;
obj.RefSignal = ref_signal;
obj.CoordinatesPlateau = coordinatesPlateau;
obj.PathTrace = env;
obj.Description = S.description;
obj.SessionName = SessionName;
obj.ExperimentNum = ExperimentNum;

% Flag ready
obj.Ready = true;
end