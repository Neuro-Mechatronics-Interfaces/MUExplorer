function keyReleaseHandler(obj, event)
if strcmp(event.Key, 'control')
    obj.IsCtrlDown = false;
    obj.PointerMode = 'crosshair';
end
end