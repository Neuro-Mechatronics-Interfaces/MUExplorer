function [emgZCA, W_zca, mu, sigma, stats] = zca_whiten_emg_masked(emg, ref_mask, options)
%ZCA_WHITEN_EMG_MASKED  ZCA-whiten multi-channel EMG using "rest" epochs for stats.
%
% Inputs:
%   emg       : [nSamples x nChannels] raw EMG (rows = time)
%   ref_mask  : [nSamples x 1] logical, TRUE for reference/REST samples
%
% Options:
%   HighpassCutoffNormalized (1,1) double = 0.05   % butter(1, ...) normalized by Nyquist
%   UseRobustScale           (1,1) logical = false % use MAD instead of std for sigma
%   CenterFrom               (1,:) char {mustBeMember(CenterFrom,{'rest','all'})} = 'rest'
%   ScaleFrom                (1,:) char {mustBeMember(ScaleFrom, {'rest','all'})} = 'rest'
%   RegularizationMode       (1,:) char {mustBeMember(RegularizationMode,{'relative','absolute','perChannelNoise'})} = 'relative'
%   Epsilon                  (1,1) double = 1e-3   % absolute eps (if Mode='absolute')
%   RelativeFactor           (1,1) double = 1.5    % multiplier for median eigenvalue (if Mode='relative')
%   NoiseVar                 (1,:) double = []     % per-channel noise var used if Mode='perChannelNoise'
%   ApplyPostLowpass         (1,1) logical = false
%   LowpassCutoffNormalized  (1,1) double = 0.25
%
% Outputs:
%   emgZCA : [nSamples x nChannels] whitened EMG
%   W_zca  : [nChannels x nChannels] ZCA whitening matrix
%   mu     : [1 x nChannels] per-channel mean used for centering
%   sigma  : [1 x nChannels] per-channel scale used before whitening
%   stats  : struct with fields: C, E, D, eps_used, ref_count
%
% Notes:
% - If you want temporal (time-embedded) whitening like your extend+Cholesky
%   pipeline, keep that step; this ZCA handles spatial (inter-channel) whitening.

arguments
    emg (:,:) double
    ref_mask (:,1) logical
    options.HighpassCutoffNormalized (1,1) double = 0.05
    options.UseRobustScale (1,1) logical = true;
    options.CenterFrom (1,:) char {mustBeMember(options.CenterFrom,{'rest','all'})} = 'rest'
    options.ScaleFrom (1,:) char {mustBeMember(options.ScaleFrom, {'rest','all'})} = 'rest'
    options.RegularizationMode (1,:) char {mustBeMember(options.RegularizationMode,{'relative','absolute','perChannelNoise'})} = 'relative'
    options.AbsoluteEpsilon (1,1) double = 1e-3
    options.TikhonovEpsilon (1,1) double = 4.5
    options.ApplyPostLowpass (1,1) logical = true;
    options.LowpassCutoffNormalized (1,1) double = 0.25
end

[nS,nC] = size(emg);
assert(numel(ref_mask)==nS, 'ref_mask length must equal number of samples');

% 1) Highpass (same as your first function)
[b_hp,a_hp] = butter(1, options.HighpassCutoffNormalized, 'high');
emg = filtfilt(b_hp, a_hp, emg);

% 2) Mean & scale from REST (by default)
idx_center = strcmp(options.CenterFrom,'rest');
idx_scale  = strcmp(options.ScaleFrom,'rest');

if idx_center
    mu = mean(emg(ref_mask,:), 1);
else
    mu = mean(emg, 1);
end
X = emg - mu;

if options.UseRobustScale
    % Robust sigma via MAD (consistent with Gaussian: /0.6745)
    if idx_scale
        S = X(ref_mask,:);
    else
        S = X;
    end
    med = median(S(:));
    sigma = median(abs(S(:) - med),1) ./ 0.6745;
    sigma = max(sigma,eps); % Avoid divide by zero
else
    if idx_scale
        sigma = std(X(ref_mask,:), 0, 1);
    else
        sigma = std(X, 0, 1);
    end
    sigma(sigma==0) = eps;
end

X = X ./ sigma; % normalize by single scalar or on per-channel basis

% 3) Covariance from REST epochs only
C = cov(X(ref_mask,:));  % [nC x nC]

% 4) Regularization epsilon
switch options.RegularizationMode
    case 'absolute'
        eps_used = options.AbsoluteEpsilon;
        D_add = eps_used;
    case 'relative'
        % Use median eigenvalue as a scale reference
        evals = eig((C+C')/2);
        mlam = median(max(evals,0));
        % If everything is tiny (e.g., very quiet rest), fall back
        if ~isfinite(mlam) || mlam <= 0
            mlam = trace(C)/max(nC,1);
        end
        eps_used = options.TikhonovEpsilon * mlam;
        D_add = eps_used;
    case 'perChannelNoise'
        s = var(X(ref_mask,:), 0, 1);
        noiseVar = s(:)';
        noiseVar = max(noiseVar, mean(noiseVar)); 
        eps_used = noiseVar; % record
        D_add = diag(noiseVar);
    otherwise
        error('Unknown RegularizationMode');
end

% 5) ZCA whitening
% We regularize as C + eps*I  (or + diag(noiseVar))
if isscalar(D_add)
    Creg = C + D_add * eye(nC);
else
    Creg = C + D_add;
end

% Numerical symmetrization
Creg = (Creg + Creg')/2;

% Eigendecomposition
[E,D] = eig(Creg);
d = real(diag(D));
d(d<0) = 0; % guard against tiny negatives from rounding
D_inv_sqrt = diag(1 ./ sqrt(d + eps)); % tiny eps to avoid 1/0

W_zca = E * D_inv_sqrt * E';

% 6) Apply
emgZCA = X * W_zca;

% 7) Optional post lowpass (off by default)
if options.ApplyPostLowpass
    [b_lp,a_lp] = butter(1, options.LowpassCutoffNormalized, 'low');
    emgZCA = filtfilt(b_lp, a_lp, emgZCA);
end

% 8) Zero-mean guard (tiny drift)
emgZCA = emgZCA - mean(emgZCA,1);

% Stats out
stats = struct();
stats.C = C;
stats.E = E;
stats.D = D;
stats.eps_used = eps_used;
stats.ref_count = nnz(ref_mask);
end
