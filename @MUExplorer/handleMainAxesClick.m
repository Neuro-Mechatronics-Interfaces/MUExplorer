function handleMainAxesClick(obj)
%HANDLEMAINAXESCLICK Callback handler for main-axes mouse-button interactions.
cp = get(obj.MainAxes, 'CurrentPoint');
xClick = cp(1,1);  % Time
yClick = cp(1,2);  % voltage offset

if obj.IsCtrlDown
    % Begin zoom box
    obj.ZoomStartPos = [xClick, yClick];
    obj.IsDraggingZoom = true;

    % Create zoom rectangle
    obj.ZoomRect = plot(obj.MainAxes, xClick, yClick, 'k--', 'LineWidth', 1.5, 'HitTest','off');
    return;
end

selType = get(obj.Figure, 'SelectionType');
switch selType
    case 'alt'  % Right-click
        [~, tIdx] = min(abs(obj.Time - xClick));
        allPeaks = obj.SelectedPeaks{obj.CurrentTemplateIndex};
        if isempty(allPeaks), return; end

        [~, idx] = min(abs(allPeaks(:,2) - tIdx));
        obj.deleteLastPeak(idx);
        return;
    case 'extend'  % Middle-click → start pan
        obj.IsPanning = true;
        obj.LastMousePos = [xClick, yClick];
        return;

    otherwise
        obj.addPeakSnippet(xClick, yClick);
end

end