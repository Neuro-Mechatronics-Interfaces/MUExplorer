function saveResultsDEMUSE(obj)
%SAVERESULTSDEMUSE Save manual MU decomposition results in DEMUSE-compatible format

LAYOUT_MAP = {reshape(1:32,8,4); ...
              reshape((1:32)+32,8,4); ...
              reshape((1:32)+64,8,4); ...
              reshape((1:32)+96,8,4)};
LAYOUT_H_OFFSET = [0, 0, 8, 8];
LAYOUT_V_OFFSET = [0, 12, 0, 12];

if isempty(obj.Spikes) || isempty(obj.Templates)
    warning('Nothing to save: missing Spikes or Templates.');
    return;
end

% Determine save path
if obj.ManualFileSelection || isempty(obj.SessionName)
    [file, path] = uiputfile('*.mat', 'Save MUExplorer (DEMUSE-Compatible)');
    if isequal(file, 0)
        disp('Save canceled.');
        return;
    end
    savePath = fullfile(path, file);
else
    saveFolder = fullfile(obj.DataRoot, obj.SessionName, 'MUExplorer');
    if ~exist(saveFolder, 'dir')
        mkdir(saveFolder);
    end
    savePath = fullfile(saveFolder, sprintf('%s_%d_DEMUSE.mat', ...
        obj.SessionName, obj.ExperimentNum));
end

fprintf('[Save] Exporting DEMUSE-compatible .mat file:\n  %s\n', savePath);

%% Prepare DEMUSE-compatible fields

% MUPulses: cell of spike index vectors
MUPulses = obj.Spikes;

extensionFactor = round(obj.PeakWidth * obj.SampleRate)+1;

fprintf(1,'Extending data and computing covariance...\n');
eSIG = MUExplorer.extend(obj.Data, extensionFactor);
Ry = eSIG * eSIG';
iRy = pinv(Ry);
fprintf(1,'\bcomplete.\n');

nMU = numel(obj.Spikes);
T = size(eSIG, 2);
IPTs = nan(nMU, T);
PNR = nan(1, nMU);
fprintf(1,'\b Projecting IPTs and reorganizing...\n');
for m = 1:nMU
    spikes = obj.Spikes{m};
    if isempty(spikes), continue; end

    % Compute projection
    w = sum(eSIG(:, spikes), 2);  % unnormalized MU filter
    IPTm = (w' * iRy * eSIG);

    % Clean edges
    IPTm(1:extensionFactor*2) = 0;
    IPTm(end-extensionFactor*2:end) = 0;

    % Normalize and square
    IPTm = IPTm / max(IPTm);
    IPTs(m,:) = IPTm.^2;

    % Estimate PNR
    PNR(m) = MUExplorer.estimatePNR(spikes, IPTm, obj.SampleRate);
end

% MUIDs: optional text labels
MUIDs = cellfun(@(i) sprintf('MU_%02d', i), num2cell(1:numel(MUPulses)), 'UniformOutput', false);

% PNR, Cost, ProcTime, DecompStat: placeholder fields for compatibility
Cost = repmat({0}, 1, numel(MUPulses));
ProcTime = zeros(1, numel(MUPulses));
DecompStat = zeros(1, numel(MUPulses));

% SIG: raw signals. This organizes in the desired format
SIG = cell(20,12);
for iLayout = 1:numel(LAYOUT_MAP)
    h0 = LAYOUT_H_OFFSET(iLayout);
    v0 = LAYOUT_V_OFFSET(iLayout);
    for iRow = 1:size(LAYOUT_MAP{iLayout},1)
        for iCol = 1:size(LAYOUT_MAP{iLayout},2)
            iSelect = LAYOUT_MAP{iLayout}(iRow,iCol);
            rowOut = iRow + v0;
            colOut = iCol + h0;
            SIG{rowOut, colOut} = obj.Data(iSelect,:);
        end
    end
end
fprintf(1,'\bcomplete.\n');

% ref_signal
ref_signal = obj.RefSignal;

% fsamp
fsamp = obj.SampleRate;

% description
description = obj.Description;

% IED (Inter-electrode distance)
IED = 8.75;  % use default or pull from options if saved

% SIGFileName and SIGFilePath
SIGFileName = sprintf('%s_%d_DEMUSE.mat', obj.SessionName, obj.ExperimentNum);
SIGFilePath = fullfile(obj.DataRoot, obj.SessionName);

% DecompRuns
DecompRuns = 1;
SIGlength = size(obj.Data,2) / fsamp;
startSIGInt = 0;
stopSIGInt = SIGlength;
origRecMode = 'MONO';
discardChannelsVec = zeros(size(SIG));
MUExplorerVersion = obj.Version;
fprintf(1,'\b Saving...\n');

%% Save
save(savePath, ...
    'MUPulses', 'IPTs', 'MUIDs', ...
    'PNR', 'Cost', 'ProcTime', 'DecompStat', ...
    'SIG', 'ref_signal', ...
    'fsamp', 'IED', 'description', ...
    'startSIGInt', 'stopSIGInt', ...
    'origRecMode', 'discardChannelsVec', ...
    'SIGlength', 'SIGFileName', 'SIGFilePath', ...
    'DecompRuns', 'MUExplorerVersion', ...
    '-v7.3');

fprintf('[Save] DEMUSE-compatible data saved successfully.\n');
end
