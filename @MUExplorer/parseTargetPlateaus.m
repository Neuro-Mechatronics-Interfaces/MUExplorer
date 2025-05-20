function [ref_signal, coordinates_plateau] = parseTargetPlateaus(sync)
%PARSE_TARGET_PLATEAUS  Parses the target plateau regions from discretized sync signal.

ref_signal = zeros(size(sync));
sync_LOW = max(sync);
u_sync = unique(sync);
u_sync = setdiff(u_sync,sync_LOW);
if isempty(u_sync)
    rising = 1;
    falling = numel(sync);
else
    n_val = zeros(size(u_sync));
    for ii = 1:numel(u_sync)
        n_val(ii) = nnz(sync==u_sync(ii));
    end
    [~,k] = max(n_val);
    sync_HIGH = u_sync(k);
    high_mask = sync == sync_HIGH;
    ref_signal(high_mask) = 1;
    rising = strfind(high_mask,[0 1]);
    falling = strfind(high_mask,[1 0]);
    if numel(rising) < numel(falling)
        if falling(1) < rising(1)
            rising = [1, rising];
        end
    end
    if numel(falling) < numel(rising)
        if rising(end) > falling(end)
            falling = [falling, numel(sync)];
        end
    end
    assert(numel(rising)==numel(falling));
end
coordinates_plateau = [rising(:), falling(:)];

end