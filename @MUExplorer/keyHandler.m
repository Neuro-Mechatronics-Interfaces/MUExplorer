function keyHandler(obj, event)
%KEYHANDLER MUExplorer keyboard callback handler.
if strcmp(event.Key, 'control')
    obj.IsCtrlDown = true;
    obj.PointerMode = 'zoom';
    return;
end
switch lower(event.Key)
    case {'return'}  % ENTER
        fprintf('Generating FRESH templates from %d peaks...\n', size(obj.SelectedPeaks,1));
        obj.generateTemplate(true);
        fprintf('Running convolution...\n');
        obj.runConvolution();
        obj.updateTemplateMetadata();

    case {'space'}
        fprintf('MERGING existing templates with %d peaks...\n', size(obj.SelectedPeaks,1));
        obj.generateTemplate(false);
        fprintf('Running convolution...\n');
        obj.runConvolution();
        obj.updateTemplateMetadata();

    case 'backspace'
        if ~isempty(obj.SelectedPeaks{obj.CurrentTemplateIndex})
            obj.deleteLastPeak();
        end

    case {'uparrow', 'tab'}
        if ~isempty(obj.Templates)
            obj.CurrentTemplateIndex = mod(obj.CurrentTemplateIndex, numel(obj.Templates)) + 1;
            fprintf('Switched to Template %d.\n', obj.CurrentTemplateIndex);
            obj.updateTemplateMetadata();
        end

    case 'downarrow'
        if ~isempty(obj.Templates)
            obj.CurrentTemplateIndex = mod(obj.CurrentTemplateIndex - 2, numel(obj.Templates)) + 1;
            fprintf('Switched to Template %d.\n', obj.CurrentTemplateIndex);
            obj.updateTemplateMetadata();
        end

    case 'leftarrow'
        xRange = diff(xlim(obj.MainAxes));
        xShift = 0.75 * xRange;
        xlim(obj.MainAxes, xlim(obj.MainAxes) - xShift);

    case 'rightarrow'
        xRange = diff(xlim(obj.MainAxes));
        xShift = 0.75 * xRange;
        xlim(obj.MainAxes, xlim(obj.MainAxes) + xShift);
    case 'w'
        fprintf(1,'Subtracting template-%02d from data...\n', obj.CurrentTemplateIndex);
        obj.subtractTemplate();

    case 'h'
        obj.printHelp();

    case 's' % Save
        % Modifier-based cases
        if ismember('control', event.Modifier)
            fprintf('Saving results to MUExplorer-style .mat (CTRL+S)...\n');
            obj.saveResults();
            return;
        elseif ismember('alt', event.Modifier)
            fprintf('Saving results to DEMUSE-compatible .mat (ALT+S)...\n');
            obj.saveResultsDEMUSE();
            return;
        end
    
    case 'l' % Load

        if ismember('control', event.Modifier)
            fprintf('Loading MUExplorer-style results (CTRL+L)...\n');
            obj.loadResults();
            return;
        elseif ismember('alt', event.Modifier)
            fprintf('Loading DEMUSE-style results (ALT+L)...\n');
            obj.loadResultsDEMUSE();
            return;
        end
    case 'c'
        obj.confirmSpikes();

    case 'escape'       % R
        fprintf('Resetting selected peaks...\n');
        obj.SelectedPeaks(obj.CurrentTemplateIndex) = cell(1,1);
        for iCh = 1:size(obj.Data,1)
            set(obj.MarkerHandles(iCh),'XData',[],'YData',[]);
        end
        obj.ConvolutionTrace = zeros(size(obj.ConvolutionTrace));
        set(obj.ConvolutionTraceHandle,'XData',obj.Time,'YData',obj.ConvolutionTrace);
        set(obj.ConvPeakMarkers,'XData',[],'YData',[]);
        obj.Spikes = [];
        obj.MetaTextHandles.SpikeCount.String = 'Spikes: 0';
        drawnow;

    case 'n'
        obj.newTemplateGroup();  % Start fresh group

    case 'subtract'
        set(obj.MainAxes, ...
            'XLim', obj.OriginalXLim, ...
            'YLim', obj.OriginalYLim);
    case 'add'
        xl = obj.MainAxes.XLim;
        yl = obj.MainAxes.YLim;
        dx = diff(xl);
        dy = diff(yl);
        xc = mean(xl);
        yc = mean(yl);
        set(obj.MainAxes, ...
            'XLim', xc + [-1, 1]*dx*0.25, ...
            'YLim', yc + [-1, 1]*dy*0.25);
    % otherwise
        % disp(event);

end
end