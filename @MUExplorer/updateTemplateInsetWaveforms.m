function updateTemplateInsetWaveforms(obj)
%UPDATETEMPLATEWAVEFORMS  Updates template waveforms on inset in bottom-left.
if isempty(obj.TemplateInsetAxes)
    return;
end
k = obj.CurrentTemplateIndex;
if isempty(obj.Templates) || k > numel(obj.Templates) || isempty(obj.Templates{k})
    cla(obj.TemplateInsetAxes);
    title(obj.TemplateInsetAxes, sprintf('Template-%02d', k), ...
        'FontName','Consolas','Color','k');
    return;
end

template = obj.Templates{k};
template = template./max(abs(template(:)));
[~, tLen] = size(template);

% Clear and hold
cla(obj.TemplateInsetAxes);

for grid = 1:numel(obj.Grids)
    g = obj.Grids(grid);
    nCols = g.NumGridColumns;
    nRows = g.NumGridRows;
    boxW = g.GridTraceWidth;  % half width (2 grids per row)
    boxH = g.GridTraceHeight;  % half height (2 grids per col)
    t = linspace(0,boxW,tLen);

    % nGrid-channel block
    nGridCh = nCols*nRows;
    chStart = (grid-1)*(nGridCh) + 1;
    chEnd = chStart + (nGridCh-1);
    block = template(chStart:chEnd, :) .* boxH;
    baseX = g.GridOffsetX;
    baseY = g.GridOffsetY;

    for ch = 1:nGridCh
        [row, col] = ind2sub([nRows, nCols], ch);

        % Offset within grid
        posX = baseX + (col-1)*boxW + (0.005)*(col-1); % Tiny offset between traces
        posY = baseY + (row-1)*boxH;

        % Normalize waveform for display
        wf = block(ch, :);
        wfX = t + posX;
        wfY = wf + posY;

        plot(obj.TemplateInsetAxes, wfX, wfY, 'LineWidth', 0.75);
    end
end

title(obj.TemplateInsetAxes, sprintf('Template-%02d', k), ...
    'FontName','Consolas','Color','k');
end
