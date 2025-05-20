function addPeakSnippet(obj, x, y)
%ADDPEAKSNIPPET Adds the snippet near the snapped-to peak to the template waveforms list for the current template group.

% Snap to closest Time sample
[~, tIdx] = min(abs(obj.Time - x));

% Estimate clicked channel from vertical offset
nCh = size(obj.Data,1);
offsetVec = obj.Spacing * (nCh:-1:1);
[~, chIdx] = min(abs(y - (obj.Data(:,tIdx) + offsetVec')));

% Decide if user clicked above or below the signal
clickedVal = y;
signalVal = obj.Data(chIdx, tIdx) + offsetVec(chIdx);
isPositive = (clickedVal > signalVal);

% Search ±4 samples around tIdx
idxSearch = max(1, tIdx - obj.PeakSearchRadius):min(size(obj.Data,2), tIdx + obj.PeakSearchRadius);
segment = obj.Data(chIdx, idxSearch);

if isPositive
    [pks, locs] = findpeaks(segment);
else
    [pks, locs] = findpeaks(-segment);
    pks = -pks;
end

if ~isempty(pks)
    [~, peakIdx] = max(abs(pks));
    tIdx = idxSearch(locs(peakIdx));
end

% Add to selected peaks list
if numel(obj.SelectedPeaks) < obj.CurrentTemplateIndex || isempty(obj.SelectedPeaks{obj.CurrentTemplateIndex})
    obj.SelectedPeaks{obj.CurrentTemplateIndex} = [chIdx, tIdx];
else
    obj.SelectedPeaks{obj.CurrentTemplateIndex}(end+1,:) = [chIdx, tIdx];
end

% Update markers
xn = [obj.MarkerHandles(1).XData, obj.Time(tIdx)];
for iCh = 1:nCh
    yn = [obj.MarkerHandles(iCh).YData, obj.Data(iCh,tIdx) + offsetVec(iCh)];
    set(obj.MarkerHandles(iCh),'XData', xn, 'YData', yn);
end
drawnow;

end