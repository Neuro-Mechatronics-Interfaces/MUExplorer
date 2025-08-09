function addPeakSnippet(obj, x, y)
%ADDPEAKSNIPPET Adds the snippet near the snapped-to peak to the template waveforms list
% for the current template group. Improved snapping:
%   1) Projects click to nearest interpolated point on each channel trace (with offsets)
%   2) Uses combined horizontal/vertical distance with data-scaled tolerances
%   3) Chooses nearest *prominent* extremum (pos/neg) in a local window
%   4) Parabolic refine around the peak for sub-sample timing (stored index stays integer)

% --- Quick guards
nCh = size(obj.Data,1);
nT  = size(obj.Data,2);
if nCh == 0 || nT == 0, return; end

% --- Compute fractional time index for interpolation
%     tFrac in [1, nT], t0 = floor, t1 = min(t0+1, nT)
tFrac = interp1(obj.Time, 1:nT, x, 'linear', 'extrap');
t0 = max(1, min(nT-1, floor(tFrac)));
t1 = t0 + 1;
alpha = tFrac - t0;  % between 0 and 1 typically

% --- Channel offsets (waterfall stack top -> bottom)
offsetVec = obj.Spacing * (nCh:-1:1);

% --- For each channel, compute interpolated y at x and combined distance
%     d_vert = |y - (trace_y + offset)|
%     d_horz = min(|x - t0|, |x - t1|) in time units
%     score = sqrt( (d_vert/VertTol)^2 + (d_horz/HorizTol)^2 )
dScore = inf(nCh,1);
yProj  = nan(nCh,1);
for iCh = 1:nCh
    yi = (1-alpha)*obj.Data(iCh, t0) + alpha*obj.Data(iCh, t1);
    yiOff = yi + offsetVec(iCh);
    dVert = abs(y - yiOff);
    % horizontal distance in time units (accounting for nonuniform time just use nearest sample distance)
    dHorz = min(abs(x - obj.Time(t0)), abs(x - obj.Time(t1)));
    dScore(iCh) = hypot(dVert/obj.SnapVertTol, dHorz/obj.SnapHorizTol);
    yProj(iCh)  = yiOff;
end

% --- Pick best channel by smallest normalized distance
[~, chIdx] = min(dScore);

% --- Seed time index near click (integer)
[~, tIdx0] = min(abs(obj.Time - x));

% --- Local search window
idxSearch = max(1, tIdx0 - obj.PeakSearchRadius) : min(nT, tIdx0 + obj.PeakSearchRadius);
seg = obj.Data(chIdx, idxSearch);

% --- Choose polarity + peak by proximity + prominence
%     Auto prominence: 4 * MAD(seg) (robust scale), unless user specified
if isempty(obj.MinPeakProminence)
    sMAD = 1.4826 * median(abs(seg - median(seg)));
    minProm = max(eps, 4*sMAD);
else
    minProm = obj.MinPeakProminence;
end

% Find positive and negative peaks
[pksP, locsP, wP, pProm] = findpeaks(seg, 'MinPeakProminence', minProm); %#ok<ASGLU>
[pksN, locsN, wN, nProm] = findpeaks(-seg, 'MinPeakProminence', minProm); %#ok<ASGLU>
pksN = -pksN;

% Convert local locs to absolute indices
absLocsP = idxSearch(1) + locsP - 1;
absLocsN = idxSearch(1) + locsN - 1;

% If neither found, fall back to nearest sample; else choose nearest in time to tFrac
candIdx = [];
candVal = [];
if ~isempty(absLocsP)
    [~, k] = min(abs(absLocsP - tFrac));
    candIdx(end+1) = absLocsP(k); %#ok<AGROW>
    candVal(end+1) = pksP(k); %#ok<AGROW>
end
if ~isempty(absLocsN)
    [~, k] = min(abs(absLocsN - tFrac));
    candIdx(end+1) = absLocsN(k); %#ok<AGROW>
    candVal(end+1) = pksN(k); %#ok<AGROW>
end

if ~isempty(candIdx)
    % If both exist, choose the one closer in time to tFrac; tie-break by |amplitude|
    [~, bestK] = min(abs(candIdx - tFrac) + 1e-6*(max(abs(candVal)) - abs(candVal)));
    tIdx = candIdx(bestK);
else
    % As a last resort, pick max |seg| near the click
    [~, k] = max(abs(seg));
    tIdx = idxSearch(k);
end

% --- Optional: parabolic refine around peak (sub-sample); we still store integer tIdx
if tIdx>1 && tIdx<nT
    yL = obj.Data(chIdx, tIdx-1);
    y0 = obj.Data(chIdx, tIdx);
    yR = obj.Data(chIdx, tIdx+1);
    denom = (yL - 2*y0 + yR);
    if abs(denom) > eps
        delta = 0.5*(yL - yR)/denom;            % in samples, typically between -0.5..0.5
        % (If you later want sub-sample markers, use obj.Time(tIdx) + delta*dt)
        % We keep integer tIdx for storage/compatibility.
    end
end

% --- Add to selected peaks list
if numel(obj.SelectedPeaks) < obj.CurrentTemplateIndex || isempty(obj.SelectedPeaks{obj.CurrentTemplateIndex})
    obj.SelectedPeaks{obj.CurrentTemplateIndex} = [chIdx, tIdx];
else
    obj.SelectedPeaks{obj.CurrentTemplateIndex}(end+1,:) = [chIdx, tIdx];
end

% --- Update markers (reuse your existing handles)
xn = [obj.MarkerHandles(1).XData, obj.Time(tIdx)];
for iCh = 1:nCh
    yn = [obj.MarkerHandles(iCh).YData, obj.Data(iCh,tIdx) + offsetVec(iCh)];
    set(obj.MarkerHandles(iCh), 'XData', xn, 'YData', yn);
end
drawnow;
end
