function shiftSpikesDialog(obj)
%SHIFTSPIKESDIALOG Prompt user to shift spike times for current template

k = obj.CurrentTemplateIndex;
if k > numel(obj.Spikes) || isempty(obj.Spikes{k})
    errordlg('No spikes found for this template.', 'Shift Spikes');
    return;
end

answer = inputdlg( ...
    {'Shift spike sample indices by how many samples? (positive = right, negative = left)'}, ...
    'Shift Spikes', ...
    [1 50], ...
    {"0"});

if isempty(answer)
    return;  % user cancelled
end

delta = str2double(answer{1});
if isnan(delta) || mod(delta,1) ~= 0
    errordlg('Shift must be an integer.', 'Invalid Input');
    return;
end

% Apply shift to both Spikes and SelectedPeaks
originalSpikes = obj.Spikes{k};
shiftedSpikes = originalSpikes - delta;
validSpikes = shiftedSpikes(shiftedSpikes >= 1 & shiftedSpikes <= size(obj.Data,2));
obj.Spikes{k} = validSpikes;

if numel(obj.SelectedPeaks) >= k && ~isempty(obj.SelectedPeaks{k})
    obj.SelectedPeaks{k}(:,2) = obj.SelectedPeaks{k}(:,2) - delta;
    obj.SelectedPeaks{k} = obj.SelectedPeaks{k}( ...
        obj.SelectedPeaks{k}(:,2) >= 1 & obj.SelectedPeaks{k}(:,2) <= size(obj.Data,2), :);
end

fprintf('[Shift] Shifted spikes for Template %d by %+d samples.\n', k, delta);

% Regenerate template and update GUI
obj.generateTemplate();
obj.runConvolution();
obj.displaySelectedPeaks();
obj.updateTemplateInsetWaveforms();
obj.updateTemplateMetadata();
end
