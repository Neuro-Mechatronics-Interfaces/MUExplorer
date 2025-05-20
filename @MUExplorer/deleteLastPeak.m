function deleteLastPeak(obj, idx)
%DELETELASTPEAK Deletes the last peak that was manually added to the plot.
if nargin < 2
    idx = numel(obj.Spikes{obj.CurrentTemplateIndex});
end
if numel(obj.MarkerHandles.XData) > 1
    x = obj.MarkerHandles(1).XData;
    x(idx) = [];
    for iCh = 1:size(obj.Data,1)
        y = obj.MarkerHandles(iCh).YData;
        y(idx) = [];
        set(obj.MarkerHandles(iCh),'XData',x,'YData',y);
    end
else
    for iCh = 1:size(obj.Data,1)
        set(obj.MarkerHandles(iCh),'XData',nan,'YData',nan);
    end
end

drawnow();
obj.SelectedPeaks{obj.CurrentTemplateIndex}(idx,:) = [];

end