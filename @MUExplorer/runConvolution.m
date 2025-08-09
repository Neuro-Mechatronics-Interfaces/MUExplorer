function runConvolution(obj)
k = obj.CurrentTemplateIndex;

if isempty(obj.Templates) || numel(obj.Templates) < k || isempty(obj.Templates{k})
    warning('No Template found for group %d. Call generateTemplate first.', k);
    return;
end

template = obj.Templates{k};
[nCh, tLen] = size(template);
nSamp = size(obj.Data, 2);
winRadius = floor(tLen / 2);
hannLen = 2 * winRadius + 1;

% Compute convolution score
score = zeros(1, nSamp);
template = template - mean(template,2);
dtemplate = reshape(del2(reshape(template,8,nCh/32,[])),nCh,[]);
ddata = reshape(del2(reshape(obj.Data,8,nCh/32,[])),nCh,[]);
for ch = 1:nCh
    temp = dtemplate(ch,:);
    convOut = conv(ddata(ch,:), fliplr(temp), 'same');
    score = score + convOut / norm(temp(:));
end

% Normalize
templateNorm = norm(template(:));
convTrace = score / templateNorm;

% hannWin = hann(hannLen)';
% hannWin = hannWin / sum(hannWin);  % normalize to preserve amplitude
% convTrace = abs(convTrace);
convTrace(1:min(100,numel(convTrace))) = 0;
convTrace(max(1,numel(convTrace)-100):end) = 0;
% convTrace = conv(convTrace, hannWin, 'same');

convMask = obj.Time >= obj.ConvAxes.XLim(1) & obj.Time <= obj.ConvAxes.XLim(2);
convTrace = convTrace ./ max(convTrace(convMask));
disp(max(convTrace));
disp(iqr(convTrace));

obj.ConvolutionTrace = convTrace;

% Find peaks
minDistance = round(0.02 * obj.SampleRate);
threshold = obj.ConvMatchLim(k,1);
[pks, locs] = findpeaks(convTrace, 'MinPeakHeight', threshold, 'MinPeakDistance', minDistance);
if ~isempty(locs)
    locs = locs(pks < obj.ConvMatchLim(k,2));
end
obj.Spikes{k} = locs;

fprintf('Group %d: detected %d Spikes\n', k, numel(locs));

% Plot convolution trace
if ~isempty(obj.ConvolutionTraceHandle)
    set(obj.ConvolutionTraceHandle,'XData',obj.Time,'YData',convTrace);
else
    obj.ConvolutionTraceHandle = plot(obj.ConvAxes, obj.Time, convTrace, 'k', 'LineWidth', 1, 'HitTest', 'off');
end

% Overlay detected peaks
yVal = convTrace(locs);
if isgraphics(obj.ConvPeakMarkers)
    set(obj.ConvPeakMarkers,'XData',obj.Time(locs),'YData',yVal);
else
    obj.ConvPeakMarkers = plot(obj.ConvAxes, obj.Time(locs), yVal, 'ro', 'MarkerSize', 5, 'LineWidth', 1.5, 'HitTest', 'off');
end

% Update spike list
obj.Spikes{k} = locs;

end