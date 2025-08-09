function generateTemplate(obj, reset)
%GENERATETEMPLATE  Generates template using current member waveforms.

if nargin < 2
    reset = false;
end

k = obj.CurrentTemplateIndex;
if k > numel(obj.Spikes)
    obj.Spikes{k} = {};
end
peaks = obj.Spikes{k};
if isempty(peaks)
    peaks = obj.SelectedPeaks{k};
    if isempty(peaks)
        warning('No peaks selected for Template %d.', k);
        return;
    end
else
    if ~isempty(obj.SelectedPeaks{k}) && ~reset
        peaks = union(reshape(peaks,1,[]), obj.SelectedPeaks{k}(:,2)');
    end
    peaks = [ones(numel(peaks),1), reshape(peaks,[],1)];
    obj.SelectedPeaks{k} = peaks;
end

nCh = size(obj.Data, 1);
winRadius = round((obj.PeakWidth * obj.SampleRate) / 2);
winLen = 2 * winRadius + 1;
nPeaks = size(peaks, 1);

snippets = zeros(nCh, winLen, nPeaks);
for p = 1:nPeaks
    tIdx = peaks(p,2);
    tStart = tIdx - winRadius;
    tEnd = tIdx + winRadius;
    if tStart < 1 || tEnd > size(obj.Data,2)
        continue;
    end
    snippets(:,:,p) = obj.Data(:, tStart:tEnd);
end

obj.Templates{k} = mean(snippets, 3);
obj.Template = obj.Templates{k};
obj.updateTemplateInsetWaveforms();
fprintf('Generated Template %d [%d channels x %d samples]\n', k, nCh, winLen);
end