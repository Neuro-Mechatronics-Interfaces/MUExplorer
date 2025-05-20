function displaySelectedPeaks(obj)
nCh = size(obj.Data,1);
if numel(obj.SelectedPeaks) < obj.CurrentTemplateIndex
    obj.SelectedPeaks{obj.CurrentTemplateIndex} = {};
    for iCh = 1:nCh
        set(obj.MarkerHandles(iCh),'XData', nan, 'YData', nan);
    end
    return;
elseif isempty(obj.SelectedPeaks{obj.CurrentTemplateIndex})
    for iCh = 1:nCh
        set(obj.MarkerHandles(iCh),'XData', nan, 'YData', nan);
    end
    return;
end
offsetVec = obj.Spacing * (nCh:-1:1);

% Update markers
tIdx = obj.SelectedPeaks{obj.CurrentTemplateIndex}(:,2);
xn = obj.Time(tIdx);
for iCh = 1:nCh
    yn = obj.Data(iCh,tIdx) + offsetVec(iCh);
    set(obj.MarkerHandles(iCh),'XData', xn, 'YData', yn);
end
drawnow;

end