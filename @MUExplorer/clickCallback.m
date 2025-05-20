function clickCallback(obj)
%CLICKCALLBACK Callback for main axes mouse click interactions.
if ~obj.Ready
    return;
end

switch obj.CursorState
    case "Main"
        handleMainAxesClick(obj);
    case "Conv"
        handleConvAxesClick(obj);
    otherwise
        % Do nothing, for now.
end

end