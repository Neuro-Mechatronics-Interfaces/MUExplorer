function handleConvAxesClick(obj)

k = obj.CurrentTemplateIndex;
selType = get(obj.Figure, 'SelectionType');
cp = get(obj.ConvAxes, 'CurrentPoint');
yClick = cp(1,2);  % voltage offset
switch selType
    case 'alt'  % Right-click = modify UPPER bound
        yClick = max(yClick, obj.ConvMatchLim(k,1)+0.05);
        obj.ConvMatchUbLine.Value = yClick;
        obj.ConvMatchLim(k,2) = yClick;
    otherwise
        yClick = min(yClick, obj.ConvMatchLim(k,2)-0.05);
        obj.ConvMatchLbLine.Value = yClick;
        obj.ConvMatchLim(k,1) = yClick;
end
drawnow();
obj.runConvolution();
drawnow();

end