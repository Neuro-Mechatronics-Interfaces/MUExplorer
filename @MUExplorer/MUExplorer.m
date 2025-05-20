classdef MUExplorer < handle
    properties
        Figure
        MainAxes
        MainLayout           % tiledlayout object
        MetaPanel            % uipanel
        MetaTextHandles      % struct of text uicontrols
        Data
        SampleRate
        Time
        Sync
        RefSignal
        CoordinatesPlateau
        PathTrace
        Description
        SessionName
        ExperimentNum
        Ready (1,1) logical = false

        Templates cell = {}               % cell array of [nCh x tLen] Templates
        Spikes cell = {}                  % confirmed spike times per Template
        Residuals cell = {}               % optional: residual after subtracting Template
        CurrentTemplateIndex = 1            % active Template index for interaction

        SelectedPeaks = {}   % manually clicked
        Template
        ConvolutionTrace
        ConfirmedSpikes = []
        
        Grids % Struct array loaded from config.yaml
        PeakSearchRadius (1,1) double {mustBePositive, mustBeInteger} = 4;
        PeakWidth     % in seconds
        Spacing % µV Spacing between traces
        EnvelopePathSmoothingLowCut % Smoothing lowpass filter coefficient cutoff for EMG envelope reference traces
        ColorOrder = [repelem(winter(8),4,1); repelem(spring(8),4,1)];

        ConvAxes             % for convolution trace
        ConvMatchLbLine      % Lower-bound yline for convolution template cluster
        ConvMatchUbLine      % Upper-bound yline for convolution template cluster
        ConvMatchLim (:,2) double = [0.15, 0.5];
        ConvPeakMarkers      % handle for peak overlay (optional)
        ConvolutionTraceHandle

        TemplateInsetAxes  % For template plot

        PlotHandles
        MarkerHandles
        PathTraceHandle
        SyncTraceHandle

        DataRoot
        InputSubfolder
        InputSuffix
        OutputSubfolder
        LayoutFile
        Version
    end

    properties (Hidden, Access=public)
        CursorState string = "Out";
        PointerMode char = 'crosshair'  % 'crosshair' or 'zoom'
        IsCtrlDown (1,1) logical = false;
        IsPanning (1,1) logical = false;
        GuiReady (1,1) logical = false;
        ManualFileSelection logical = false;
        LastMousePos (1,2) double = [0 0];
        ZoomStartPos  % Starting point of zoom drag
        ZoomRect      % Handle to zoom rectangle (line object)
        IsDraggingZoom logical = false
        OriginalXLim
        OriginalYLim
    end

    methods
        function obj = MUExplorer(Data, SampleRate, Sync)
            %MUEXPLORER Create MUExplorer instance
            %
            %
            % Syntax:
            %   app = MUExplorer(Data, SampleRate);
            %   app = MUExplorer(Data, SampleRate, Sync);
            %   app = MUExplorer(sessionName, experimentNum);

            if nargin < 3
                Sync = zeros(1,size(Data,2));
            end
            p = mfilename("fullpath");
            [p,~,~] = fileparts(p);
            configFile = fullfile(p,'config.yaml');
            cfg = MUExplorer.readSimpleYAML(configFile);
            obj.Version = cfg.Version;
            obj.DataRoot = cfg.DataRoot;
            obj.InputSubfolder = cfg.InputSubfolder;
            obj.InputSuffix = cfg.InputSuffix;
            obj.OutputSubfolder = cfg.OutputSubfolder;
            obj.LayoutFile = cfg.LayoutFile;
            obj.Spacing = cfg.YLineSpacingMicroVolts;
            obj.PeakWidth = cfg.ExtensionPeakWidthSeconds;
            obj.EnvelopePathSmoothingLowCut = cfg.EnvelopePathSmoothingLowCutHz;
            obj.Grids = cfg.Grids;

            if isnumeric(Data)
                obj.Data = Data;
                obj.SampleRate = SampleRate;
                obj.Time = (0:size(Data,2)-1) / SampleRate;
                obj.SelectedPeaks = cell(1, 1);
                obj.Sync = Sync;
                % Add lowpass envelope estimate for path
                [ref_signal, coordinatesPlateau] = obj.parseTargetPlateaus(Sync);
                [b, a] = butter(1, obj.EnvelopePathSmoothingLowCut / (obj.SampleRate/2), 'low');
                env = zeros(size(Data));
                for iCh = 1:size(Data,1)
                    env(iCh,:) = filtfilt(b, a, abs(Data(iCh,:)));
                end
                env = mean(env,1);
                mu_rest = mean(env(~ref_signal & ((1:numel(env)) > 6000) & ((1:numel(env)) < (numel(env)-6000))));
                env = env - mu_rest;
                env([1:6000, (end-6000):end]) = 0;
                env_sort = sort(env(logical(ref_signal)),'ascend');
                env = env ./ env_sort(round(0.95*numel(env_sort)));
                obj.CoordinatesPlateau = coordinatesPlateau;
                obj.PathTrace = env;
                obj.Ready = true;
            else
                sessionName = Data;
                experimentNumber = SampleRate;
                loadSignal(obj, sessionName, experimentNumber);
            end
            obj.initGUI();
            obj.updatePointer();  % Force pointer mode sync
            obj.loadResults();
            drawnow();
        end

        function delete(obj, ~, ~)
            if ~isempty(obj.Figure)
                if isvalid(obj.Figure)
                    if ~obj.Figure.BeingDeleted
                        obj.Figure.DeleteFcn = [];
                        delete(obj.Figure);
                    end
                end
            end
        end

        initGUI(obj);
        
        handleScroll(obj, event);
        clickCallback(obj, event);
        handleMainAxesClick(obj);
        handleConvAxesClick(obj);
        keyHandler(obj, event);
        releaseCallback(obj);
        updatePointer(obj);

        deleteLastPeak(obj, idx);
        displaySelectedPeaks(obj);
        
        generateTemplate(obj);
        confirmSpikes(obj);
        runConvolution(obj);
        newTemplateGroup(obj);
        subtractTemplate(obj);
        
        saveResults(obj);
        loadResults(obj);
        loadSignal(obj, SessionName, ExperimentNum);

        saveResultsDEMUSE(obj);
        loadResultsDEMUSE(obj);
        loadSignalDEMUSE(obj, SessionName, ExperimentNum);
    end

    methods (Access = protected)
        addPeakSnippet(obj, x, y);
        updateTemplateMetadata(obj);
        updateTemplateInsetWaveforms(obj);
    end

    methods (Static, Access = public)
        PNR = estimatePNR(MUPulses,IPT,fsamp, options);
        eSIG = extend(SIG, extFact);
        cfg = readSimpleYAML(filepath);
    end

    methods (Static, Access = protected)
        printHelp;
        cursor = getMagnifierCursor();
        [ref_signal, coordinates_plateau] = parseTargetPlateaus(sync);
    end
end
