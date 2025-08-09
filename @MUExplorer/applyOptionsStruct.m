function applyOptionsStruct(obj, s)
% Map incoming struct fields to processSignal Name-Value options.
% Accepts partial updates; merges into obj.LatestOptions.
%
% Recognized fields (match your processSignal):
%   UseRobustScale           (logical)
%   CenterFrom               ('rest'|'all')
%   ScaleFrom                ('rest'|'all')
%   RegularizationMode       ('relative'|'absolute'|'perChannelNoise')
%   AbsoluteEpsilon          (double)
%   TikhonovEpsilon          (double)
%   ApplyPostLowpass         (logical)
%   LowpassCutoff            (double, Hz)

% Initialize if empty
f = fieldnames(s);
for k = 1:numel(f)
    obj.LatestOptions.(f{k}) = s.(f{k});
end

obj.Spacing = obj.LatestOptions.YLineSpacingSD;

% Optional: sanity clamps
if isfield(obj.LatestOptions,'LowpassCutoff')
    obj.LatestOptions.LowpassCutoff = max(1, obj.LatestOptions.LowpassCutoff);
end
if isfield(obj.LatestOptions,'TikhonovEpsilon')
    obj.LatestOptions.TikhonovEpsilon = max(0, obj.LatestOptions.TikhonovEpsilon);
end
if isfield(obj.LatestOptions,'AbsoluteEpsilon')
    obj.LatestOptions.AbsoluteEpsilon = max(0, obj.LatestOptions.AbsoluteEpsilon);
end
end