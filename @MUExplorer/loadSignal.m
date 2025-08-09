function loadSignal(obj, SessionName, ExperimentNum, options)
%LOADSIGNAL Load EMG and Sync Data from a TMSi session

arguments
    obj
    SessionName (1,1) string
    ExperimentNum (1,1) double {mustBeInteger}
    options.Prefix {mustBeTextScalar} = "";
    options.Suffix {mustBeTextScalar} = "";
end

baseDir = fullfile(obj.DataRoot, SessionName);
inputDir = fullfile(baseDir, obj.InputSubfolder);
expBase = sprintf('%s%s_%d%s', options.Prefix, SessionName, ExperimentNum, options.Suffix);
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
obj.processSignal(uni, sync);

obj.Description = S.description;
obj.SessionName = SessionName;
obj.ExperimentNum = ExperimentNum;

% Flag ready
obj.Ready = true;
end