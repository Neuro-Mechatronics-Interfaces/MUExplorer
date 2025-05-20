function confirmSpikes(obj)
%CONFIRMSPIKES  Confirm spikes associated with the current template.
k = obj.CurrentTemplateIndex;
if isempty(obj.Spikes) || numel(obj.Spikes) < k || isempty(obj.Spikes{k})
    warning('No detected spikes for Template %d to confirm.', k);
    return;
end

% Merge into global confirmed spike list
obj.ConfirmedSpikes = [obj.ConfirmedSpikes; obj.Spikes{k}(:)];
obj.Template = obj.Templates{k};  % Save most recent template
fprintf('Confirmed %d spikes from Template group %d.\n', numel(obj.Spikes{k}), k);

end