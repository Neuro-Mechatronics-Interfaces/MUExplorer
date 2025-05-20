function ios = estimate_ios(MUPulses, fs, options)

arguments
    MUPulses
    fs
    options.SyncWindow = 2e-3; % ±2 ms
end

nUnits = numel(MUPulses);

% Compare pulse trains using IoS (index of synchronization)
syncWindow = round(options.SyncWindow * fs); 
ios = nan(nUnits);

for i = 1:nUnits
    spikesA = MUPulses{i};
    for j = i+1:nUnits
        spikesB = MUPulses{j};

        % Count synchronized events within ±syncWindow
        coincidences = 0;
        a_idx = 1; b_idx = 1;
        while a_idx <= numel(spikesA) && b_idx <= numel(spikesB)
            dt = spikesA(a_idx) - spikesB(b_idx);
            if abs(dt) <= syncWindow
                coincidences = coincidences + 1;
                a_idx = a_idx + 1;
                b_idx = b_idx + 1;
            elseif dt < 0
                a_idx = a_idx + 1;
            else
                b_idx = b_idx + 1;
            end
        end

        ios(i,j) = coincidences / min(numel(spikesA), numel(spikesB));
    end
end


end