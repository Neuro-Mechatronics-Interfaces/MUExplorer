function loadResultsDEMUSE(obj)
%LOADRESULTSDEMUSE Load DEMUSE-compatible MU decomposition results

if isempty(obj.SessionName) || isempty(obj.ExperimentNum)
    warning('SessionName and ExperimentNum must be set before loading DEMUSE results.');
    return;
end

% Construct load path
loadPath = fullfile(obj.DataRoot, obj.SessionName, obj.OutputSubfolder, ...
    sprintf('%s_%d_DEMUSE.mat', obj.SessionName, obj.ExperimentNum));

if ~isfile(loadPath)
    fprintf('[Load] No DEMUSE result found at:\n  %s\n', loadPath);
    return;
end

fprintf('[Load] Reading DEMUSE-compatible result:\n  %s\n', loadPath);
S = load(loadPath);

% Restore key fields
obj.Spikes = S.MUPulses;
obj.ConfirmedSpikes = horzcat(S.MUPulses{:})';  % Optional: merge into single list
obj.Templates = {};  % Not included in DEMUSE format by default
obj.Residuals = {};  % Optional: clear or regenerate
obj.SelectedPeaks = cell(size(obj.Spikes));
obj.ConvMatchLim = repmat(obj.ConvMatchLim(1,:), numel(obj.Spikes), 1);  % fallback

% Generate default SelectedPeaks = [channelIdx, timeIdx] if unknown
for k = 1:numel(obj.Spikes)
    if ~isempty(obj.Spikes{k})
        obj.SelectedPeaks{k} = [ones(numel(obj.Spikes{k}), 1), obj.Spikes{k}(:)];
    else
        obj.SelectedPeaks{k} = [];
    end
end

% Set current template index to last
obj.CurrentTemplateIndex = numel(obj.Spikes);

% Attempt metadata recovery
if isfield(S, 'description')
    obj.Description = S.description;
end

% Update GUI
obj.updateTemplateMetadata();
obj.runConvolution();             % Recompute convolution from templates (if any)
obj.displaySelectedPeaks();      % Optional visual update
obj.updateTemplateWaveforms();   % Show blank or reconstructed
for k = 1:numel(obj.Spikes)
    obj.CurrentTemplateIndex = k;
    obj.generateTemplate();
end
obj.CurrentTemplateIndex = numel(obj.Spikes);
fprintf('[Load] Restored %d spike trains from DEMUSE.\n', obj.CurrentTemplateIndex);
end
