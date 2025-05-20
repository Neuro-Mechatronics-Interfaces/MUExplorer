function updateTemplateMetadata(obj)
%UPDATETEMPLATEMETADATA Utility function to update HUD metadata on template index change.
k = obj.CurrentTemplateIndex;
nT = numel(obj.Templates);
if isfield(obj.MetaTextHandles, 'TemplateInfo')
    obj.MetaTextHandles.TemplateInfo.String = ...
        sprintf('Template: %d / %d', k, nT);
end
if isfield(obj.MetaTextHandles, 'SpikeCount')
    if k <= numel(obj.SelectedPeaks) && ~isempty(obj.SelectedPeaks{k})
        obj.MetaTextHandles.SpikeCount.String = ...
            sprintf('Spikes: %d', size(obj.SelectedPeaks{k},1));
    else
        obj.MetaTextHandles.SpikeCount.String = 'Spikes: 0';
    end
end

updateTemplateInsetWaveforms(obj);
if ~isempty(obj.Templates) && ~isempty(obj.Templates{k})
    obj.runConvolution();
    obj.displaySelectedPeaks();
elseif ~isempty(obj.ConvolutionTraceHandle)
    set(obj.ConvolutionTraceHandle,'XData',[],'YData',[]);
    if ~isempty(obj.ConvPeakMarkers)
        set(obj.ConvPeakMarkers,'XData',[],'YData',[]);
    end
end
obj.ConvMatchLbLine.Value = obj.ConvMatchLim(k,1);
obj.ConvMatchUbLine.Value = obj.ConvMatchLim(k,2);
drawnow();

% --- Compute synchronization with other units
if nT > 1
    ios = MUExplorer.estimate_ios(obj.Spikes, obj.SampleRate);
    other_idx = setdiff(1:nT, k);
    ios_from_other = ios(:,k)';
    ios_with_current = ios(k, other_idx);  % safe index
    ios_with_current(isnan(ios_with_current)) = ios_from_other(isnan(ios_with_current));
    syncStrs = arrayfun(@(j, s) sprintf('\n#%d: %.2f', j, s), ...
        other_idx, ios_with_current(:)', ...
        'UniformOutput', false);
    obj.MetaTextHandles.SyncStats.String = ['Synchronization (IoS): ', strjoin(syncStrs, ', ')];
    drawnow();
else
    obj.MetaTextHandles.SyncStats.String = 'Synchronization: N/A';
    drawnow();
end

end
