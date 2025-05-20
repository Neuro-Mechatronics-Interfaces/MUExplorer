function subtractTemplate(obj)
k = obj.CurrentTemplateIndex;

if isempty(obj.Templates) || numel(obj.Templates) < k || isempty(obj.Templates{k})
    warning('No Template found for group %d.', k);
    return;
end
if isempty(obj.Spikes) || numel(obj.Spikes) < k || isempty(obj.Spikes{k})
    warning('No confirmed Spikes found for group %d.', k);
    return;
end

Template = obj.Templates{k};
Spikes = obj.Spikes{k};
[nCh, tLen] = size(Template);
winRadius = floor(tLen / 2);

nSamp = size(obj.Data, 2);
dataCopy = obj.Data;  % to keep an unmodified version of original if needed

for s = 1:numel(Spikes)
    tIdx = Spikes(s);
    tStart = tIdx - winRadius;
    tEnd = tIdx + winRadius;

    if tStart < 1 || tEnd > nSamp
        continue; % Skip edge violations
    end

    obj.Data(:, tStart:tEnd) = obj.Data(:, tStart:tEnd) - Template;
end

% Optionally store residual
obj.Residuals{k} = dataCopy;

fprintf('Subtracted Template group %d from %d spike locations.\n', k, numel(Spikes));

% Optionally refresh display
for ch = 1:nCh
    y = zscore(obj.Data(ch,:)) + offsetVec(ch);
    set(obj.PlotHandles(ch),'YData',y);
end
end