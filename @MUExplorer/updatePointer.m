function updatePointer(obj)
%UPDATEPOINTER Updates the pointer to have correct icon / zoom indicator depending on keyboard modifiers.
if isempty(obj.Figure) || ~isvalid(obj.MainAxes)
    return;
end

cp = get(obj.MainAxes, 'CurrentPoint');
x = cp(1,1);
y = cp(1,2);

% Make sure both are in pixels
hoveredObj = hittest(obj.Figure);
if isgraphics(hoveredObj) && isequal(ancestor(hoveredObj, 'axes'), obj.MainAxes)
    obj.CursorState = "Main";
    if obj.IsCtrlDown
        set(obj.Figure, 'Pointer', 'custom');
        set(obj.Figure, 'PointerShapeCData', obj.getMagnifierCursor());
    else
        set(obj.Figure, 'Pointer', 'crosshair');
    end
elseif isgraphics(hoveredObj) && isequal(ancestor(hoveredObj, 'axes'), obj.ConvAxes)
    obj.CursorState = "Conv";
else
    obj.CursorState = "Out";
    set(obj.Figure, 'Pointer', 'arrow');
    return;
end
% Update zoom box if dragging
if obj.IsDraggingZoom && isvalid(obj.ZoomRect)
    x0 = obj.ZoomStartPos(1);
    y0 = obj.ZoomStartPos(2);
    obj.ZoomRect.XData = [x0 x  x  x0 x0];
    obj.ZoomRect.YData = [y0 y0 y y   y0];
    return;
end

if obj.IsPanning
    cp = get(obj.MainAxes, 'CurrentPoint');
    currPos = [cp(1,1), cp(1,2)];
    delta = obj.LastMousePos - currPos;
    obj.LastMousePos = currPos;

    % Pan axes
    xlim = get(obj.MainAxes, 'XLim') + delta(1);
    ylim = get(obj.MainAxes, 'YLim') + delta(2);
    set(obj.MainAxes, 'XLim', xlim, 'YLim', ylim);
    return;
end
end