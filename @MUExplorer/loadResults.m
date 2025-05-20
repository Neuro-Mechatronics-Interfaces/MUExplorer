function loadResults(obj)
if isempty(obj.SessionName) || isempty(obj.ExperimentNum)
    warning('Cannot load results: SessionName or ExperimentNum not set.');
    return;
end

loadPath = fullfile(obj.DataRoot, obj.SessionName, obj.OutputSubfolder, ...
    sprintf('%s_%d_muresults.mat', obj.SessionName, obj.ExperimentNum));

if ~isfile(loadPath)
    fprintf('[Load] No existing results found at:\n  %s\n', loadPath);
    return;
end

fprintf('[Load] Loading results from:\n  %s\n', loadPath);
R = load(loadPath);

% Populate class properties
obj.ConfirmedSpikes = R.ConfirmedSpikes;
obj.Template = R.Template;
obj.Templates = R.Templates;
obj.Spikes = R.Spikes;
if isfield(R, 'Residuals')
    obj.Residuals = R.Residuals;
end
if isfield(R, 'SelectedPeaks')
    obj.SelectedPeaks = R.SelectedPeaks;
else
    obj.SelectedPeaks = cell(size(obj.Spikes)); 
    for ii = 1:numel(obj.Spikes)
        obj.SelectedPeaks{ii} = [ones(numel(obj.Spikes{ii}),1), reshape(obj.Spikes{ii},[],1)];
    end
end
if isfield(R, 'Bounds')
    obj.ConvMatchLim = R.Bounds;
else
    obj.ConvMatchLim = repmat(obj.ConvMatchLim(1,:),numel(R.Templates),1);
end

% Set current template index to latest
if iscell(R.Templates)
    obj.CurrentTemplateIndex = numel(R.Templates);
    obj.updateTemplateMetadata();
    obj.runConvolution();
    obj.displaySelectedPeaks();
else
    obj.CurrentTemplateIndex = 1;
end

fprintf('[Load] Restored %d template(s).\n', obj.CurrentTemplateIndex);
end
