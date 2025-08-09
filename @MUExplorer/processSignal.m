function processSignal(obj, uni, sync, options)
%PROCESSSIGNAL  ZCA-whiten EMG data using rest-epoch statistics, and compute path trace.
%
%   processSignal(obj, uni, sync, Name, Value)
%
%   This method:
%     1. Identifies "rest" epochs from the synchronization signal using
%        obj.parseTargetPlateaus().
%     2. Applies zero-phase highpass filtering to the raw EMG.
%     3. Estimates per-channel mean and scale (from either rest or all data).
%     4. Computes a ZCA whitening transform using only rest epochs for the
%        covariance estimate, with configurable regularization.
%     5. Applies the whitening transform to the full dataset.
%     6. Optionally applies a post-whitening lowpass filter.
%     7. Stores the whitened data, whitening parameters, and rest mask
%        in the object properties.
%     8. Computes a smoothed EMG envelope path trace for feedback/visualization.
%
%   Inputs:
%     obj      - Class instance
%     uni      - [nChannels x nSamples] raw EMG matrix
%     sync     - Synchronization signal used to identify reference/target epochs
%
%   Name-Value Options:
%     UseRobustScale       : (default: true) Use MAD for scaling instead of std
%     CenterFrom           : 'rest' or 'all' (default: 'rest')
%     ScaleFrom            : 'rest' or 'all' (default: 'rest')
%     RegularizationMode   : 'relative', 'absolute', or 'perChannelNoise'
%                            (default: 'relative')
%     AbsoluteEpsilon      : Scalar ε for 'absolute' mode (default: 3)
%     TikhonovEpsilon      : Factor for 'relative' mode, scales median eigenvalue (default: 5)
%     ApplyPostLowpass     : (default: true) Lowpass filter whitened data
%     LowpassCutoff        : Lowpass cutoff frequency in Hz for post-filtering
%
%   Side effects:
%     - Updates obj.Data with whitened EMG
%     - Updates obj.Whiten with whitening matrix, mean, sigma, and stats
%     - Updates obj.RefSignal with logical rest mask (TRUE = in-target)
%     - Updates obj.PathTrace with normalized smoothed envelope
%
%   Notes:
%     - Whitening covariance is estimated from rest epochs only (~ref_signal).
%     - Highpass and lowpass cutoff frequencies are normalized internally
%       using obj.SampleRate.
%     - The envelope path trace is normalized to the 95th percentile of
%       in-target amplitudes for relative scaling.

arguments
    obj
    uni
    sync
    options.UseRobustScale (1,1) logical = true
    options.CenterFrom (1,:) char {mustBeMember(options.CenterFrom,{'rest','all'})} = 'rest'
    options.ScaleFrom (1,:) char {mustBeMember(options.ScaleFrom, {'rest','all'})} = 'rest'
    options.RegularizationMode (1,:) char {mustBeMember(options.RegularizationMode,{'relative','absolute','perChannelNoise'})} = 'relative'
    options.AbsoluteEpsilon (1,1) double = 3
    options.TikhonovEpsilon (1,1) double = 5
    options.ApplyPostLowpass (1,1) logical = true
    options.LowpassCutoff (1,1) double = 200; % Hz
end

[ref_signal, obj.CoordinatesPlateau] = obj.parseTargetPlateaus(sync);
[Z, W, mu, sigma, stats] = MUExplorer.zca_whiten_emg_masked(uni.', ~ref_signal(:), ...  % TRUE = rest
           'HighpassCutoffNormalized', obj.EnvelopePathSmoothingLowCut/(obj.SampleRate/2), ...
           'RegularizationMode', options.RegularizationMode, ...   % or 'perChannelNoise'
           'TikhonovEpsilon', options.TikhonovEpsilon, ...
           'AbsoluteEpsilon', options.AbsoluteEpsilon, ...
           'ScaleFrom', options.ScaleFrom, ...
           'CenterFrom', options.CenterFrom, ...
           'UseRobustScale', options.UseRobustScale, ...
           'ApplyPostLowpass', options.ApplyPostLowpass, ...
           'LowpassCutoffNormalized', options.LowpassCutoff/(obj.SampleRate/2));

obj.Data = Z.';                         % back to [nChannels x nSamples]
obj.Raw  = uni;
obj.Time = (0:size(obj.Data,2)-1) / obj.SampleRate;
obj.Sync = sync;
obj.RefSignal = ref_signal;
obj.Whiten.W = W; 
obj.Whiten.mu = mu; 
obj.Whiten.sigma = sigma; 
obj.Whiten.stats = stats;

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
obj.PathTrace = env;

end