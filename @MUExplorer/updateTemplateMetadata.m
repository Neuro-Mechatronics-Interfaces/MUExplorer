function updateTemplateMetadata(obj)
%UPDATETEMPLATEMETADATA Utility function to update HUD metadata on template index change.
k = obj.CurrentTemplateIndex;
nT = numel(obj.Templates);
if isfield(obj.MetaTextHandles, 'TemplateInfo')
    obj.MetaTextHandles.TemplateInfo.String = ...
        sprintf('Template: %d / %d', k, nT);
end
if isfield(obj.MetaTextHandles, 'SpikeCount')
    if k <= numel(obj.Spikes) && ~isempty(obj.Spikes{k})
        obj.MetaTextHandles.SpikeCount.String = ...
            sprintf('Spikes: %d', numel(obj.Spikes{k}));
    else
        obj.MetaTextHandles.SpikeCount.String = 'Spikes: 0';
    end
end

updateTemplateInsetWaveforms(obj);
if ~isempty(obj.Templates{k})
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

end
