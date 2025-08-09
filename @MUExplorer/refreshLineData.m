function refreshLineData(obj)

nCh = size(obj.Data,1);
% Compute vertical offset per channel
offsetVec = obj.Spacing * (nCh:-1:1);
for ch = 1:nCh
        set(obj.PlotHandles(ch),'XData',obj.Time,'YData',obj.Data(ch,:)+offsetVec(ch)); 
end

drawnow();

end