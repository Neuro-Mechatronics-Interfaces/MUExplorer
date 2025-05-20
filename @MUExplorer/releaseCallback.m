function releaseCallback(obj)
if obj.IsDraggingZoom
    obj.IsDraggingZoom = false;

    if isvalid(obj.ZoomRect)
        xBox = obj.ZoomRect.XData;
        yBox = obj.ZoomRect.YData;
        delete(obj.ZoomRect);
    end

    % Compute bounds
    xMin = min(xBox);
    xMax = max(xBox);
    yMin = min(yBox);
    yMax = max(yBox);

    % Only zoom if box has size
    if abs(xMax - xMin) > 0.01 && abs(yMax - yMin) > 0.01
        xlim(obj.MainAxes, [xMin, xMax]);
        ylim(obj.MainAxes, [yMin, yMax]);
    else
        disp('[Zoom] Box too small — ignoring.');
    end
end
if obj.IsPanning
    obj.IsPanning = false;
    return;
end

end