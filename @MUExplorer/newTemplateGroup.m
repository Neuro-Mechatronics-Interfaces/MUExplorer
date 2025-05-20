function newTemplateGroup(obj)
%NEWTEMPLATEGROUP Update the current template index so we are adding waveforms to a new template group.
obj.CurrentTemplateIndex = numel(obj.Templates) + 1;
obj.SelectedPeaks{obj.CurrentTemplateIndex} = [];
obj.Templates{obj.CurrentTemplateIndex} = [];
obj.Spikes{obj.CurrentTemplateIndex} = [];
for iCh = 1:size(obj.Data,1)
    set(obj.MarkerHandles(iCh),'XData',[],'YData',[]);
end
drawnow();
while size(obj.ConvMatchLim,1) < obj.CurrentTemplateIndex
    obj.ConvMatchLim(end+1,:) = [0.15, 0.5];
end
fprintf('Switched to new Template group #%d.\n', obj.CurrentTemplateIndex);
updateTemplateMetadata(obj);
obj.runConvolution();
obj.displaySelectedPeaks();
end