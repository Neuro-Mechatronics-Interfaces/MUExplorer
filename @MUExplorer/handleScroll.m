function handleScroll(obj, event)
if event.VerticalScrollCount > 0  % Scroll down
    % Reset zoom
    set(obj.MainAxes, ...
        'XLim', obj.OriginalXLim, ...
        'YLim', obj.OriginalYLim);
    disp('[Zoom] Reset to original view.');
end
end