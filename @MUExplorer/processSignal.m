function processSignal(obj, uni, sync)

[ref_signal, coordinatesPlateau] = obj.parseTargetPlateaus(sync);
extensionFactor = round(obj.PeakWidth * obj.SampleRate)+1;
R = cov(uni(:,~ref_signal)');
epsilon = diag(R);
epsilon = max(epsilon, mean(epsilon));
obj.BackgroundNoise = repelem(epsilon, extensionFactor,1);

fprintf(1,'Extending data and computing covariance...\n');
eSIG = MUExplorer.extend(uni, extensionFactor);
Ry = eSIG * eSIG';
W = chol(Ry + diag(obj.BackgroundNoise));
wSIG = W \ eSIG;
fprintf(1,'\bcomplete.\n');

% Add lowpass envelope estimate for path

[b, a] = butter(1, obj.EnvelopePathSmoothingLowCut / (obj.SampleRate/2), 'low');
env = zeros(size(uni));
for iCh = 1:size(uni,1)
    env(iCh,:) = filtfilt(b, a, abs(uni(iCh,:)));
end
env = mean(env,1);
mu_rest = mean(env(~ref_signal & ((1:numel(env)) > 6000) & ((1:numel(env)) < (numel(env)-6000))));
env = env - mu_rest;
env([1:6000, (end-6000):end]) = 0;
env_sort = sort(env(logical(ref_signal)),'ascend');
env = env ./ env_sort(round(0.95*numel(env_sort)));
% Store everything into class properties
obj.Data = wSIG(round(extensionFactor/2):extensionFactor:end,:);
obj.Raw = uni;
obj.Time = (0:size(obj.Data,2)-1) / obj.SampleRate;
obj.Sync = sync;
obj.RefSignal = ref_signal;
obj.CoordinatesPlateau = coordinatesPlateau;
obj.PathTrace = env;

end