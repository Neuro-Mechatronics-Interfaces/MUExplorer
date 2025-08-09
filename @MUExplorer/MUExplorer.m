classdef MUExplorer < handle
    properties
        Figure
        MainAxes
        MainLayout           % tiledlayout object
        MetaPanel            % uipanel
        MetaTextHandles      % struct of text uicontrols
        MetaWidgets          % struct of pushbutton etc uicontrols
        Data
        Raw
        BackgroundNoise
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
        Whiten (1,1) struct;

        Templates cell = {}               % cell array of [nCh x tLen] Templates
        Spikes cell = {}                  % confirmed spike times per Template
        Residuals cell = {}               % optional: residual after subtracting Template
        CurrentTemplateIndex = 1            % active Template index for interaction

        SelectedPeaks = {}   % manually clicked
        Template
        ConvolutionTrace
        ConfirmedSpikes = []
        
        Grids % Struct array loaded from config.yaml

        SnapVertTol (1,1) double
        SnapHorizTol (1,1) double
        PeakSearchRadius (1,1) double {mustBePositive, mustBeInteger} = 4;
        PeakWidth (1,1) double = 0.010;     % in seconds
        MinPeakProminence = [];
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
        DemuseInputSubfolder
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

        % --- Param bridge (UDP) ---
        ParamUdp = [] %  UDP port
        ParamUdpLocalPort (1,1) double = 55557   % MATLAB listens here
        ParamUdpRemotePort (1,1) double = 55556
        ParamUdpSocketPort (1,1) double = 55555
        ParamUdpPeer {mustBeTextScalar} = "127.0.0.1"
        ParamOnUpdateReprocess (1,1) logical = true
        LatestOptions struct = struct()          % last-applied options snapshot
    end

    methods
        function obj = MUExplorer(Data, SampleRate, Sync, options)
            %MUEXPLORER Create MUExplorer instance
            %
            %
            % Syntax:
            %   app = MUExplorer(Data, SampleRate);
            %   app = MUExplorer(Data, SampleRate, Sync);
            %   app = MUExplorer(sessionName, experimentNum);
            %   app = MUExplorer(sessionName, experimentNum, loadDEMUSE);
            %
            % Example using options:
            %   app = MUExplorer("2025_03_06", 3, false, ...
            %       'DataRoot', "G:\Shared drives\NML_MetaWB\Data\MCP_08", ...
            %       'Prefix', "MCP08_");
            %   
            %   This loads from MCP_08 subject folder, session on
            %   2025-03-06. "Prefix" is used in combination with
            %   `sessionName` to form the full
            %   "MCP08_2025_03_06_synchronized_3.mat" corresponding to
            %   synchronized experiment 3 data file. 

            arguments
                Data
                SampleRate (1,1)
                Sync (1,:) = zeros(1, size(Data,2));
                options.Prefix {mustBeTextScalar} = "";
                options.Suffix {mustBeTextScalar} = "";
                options.DataRoot {mustBeTextScalar} = "";
                options.ConfigFile {mustBeTextScalar} = "";
            end

            p = mfilename("fullpath");
            [p,~,~] = fileparts(p);
            if strlength(options.ConfigFile) < 1
                configFile = fullfile(p,'config.yaml');
            else
                configFile = options.ConfigFile;
            end
            cfg = MUExplorer.parseYAML(configFile);
            obj.Version = cfg.Version;
            if strlength(options.DataRoot) < 1
                obj.DataRoot = cfg.DataRoot;
            else
                obj.DataRoot = options.DataRoot;
            end
            obj.InputSubfolder = cfg.InputSubfolder;
            obj.InputSuffix = cfg.InputSuffix;
            obj.OutputSubfolder = cfg.OutputSubfolder;
            obj.DemuseInputSubfolder = cfg.DemuseInputSubfolder;
            obj.LayoutFile = cfg.LayoutFile;
            obj.Spacing = cfg.InitialProcessingParameters.YLineSpacingSD;
            obj.EnvelopePathSmoothingLowCut = cfg.EnvelopePathSmoothingLowCutHz;
            obj.Grids = cfg.Grids;
            obj.LatestOptions = cfg.InitialProcessingParameters;

            if isnumeric(Data)
                obj.SampleRate = SampleRate;
                obj.SelectedPeaks = cell(1, 1);
                obj.processSignal(Data, Sync, ...
                    'AbsoluteEpsilon', cfg.InitialProcessingParameters.AbsoluteEpsilon, ...
                    'ApplyPostLowpass',cfg.InitialProcessingParameters.ApplyPostLowpass, ...
                    'CenterFrom', cfg.InitialProcessingParameters.CenterFrom, ...
                    'LowpassCutoff', cfg.InitialProcessingParameters.LowpassCutoff, ...
                    'RegularizationMode', cfg.InitialProcessingParameters.RegularizationMode, ...
                    'ScaleFrom', cfg.InitialProcessingParameters.ScaleFrom, ...
                    'TikhonovEpsilon', cfg.InitialProcessingParameters.TikhonovEpsilon, ...
                    'UseRobustScale', cfg.InitialProcessingParameters.UseRobustScale);
                obj.Ready = true;
                loadDEMUSE = false;
            else
                sessionName = Data;
                experimentNumber = SampleRate;
                if (nargin > 2) && islogical(Sync) && isscalar(Sync)
                    loadDEMUSE = Sync;
                else
                    loadDEMUSE = false;
                end
                loadSignal(obj, sessionName, experimentNumber, ...
                    'Prefix', options.Prefix, ...
                    'Suffix', options.Suffix);
                
            end
            obj.initGUI();
            obj.updatePointer();  % Force pointer mode sync
            if loadDEMUSE
                loadResultsDEMUSE(obj);
            else
                obj.loadResults();
            end

            % --- Defaults / tolerances (if not provided on obj)
            obj.SnapVertTol = cfg.Click.SnapVertTolFactor * obj.Spacing; 
            obj.SnapHorizTol = cfg.Click.SnapHorizTolFactor/obj.SampleRate;
            obj.PeakSearchRadius = cfg.Click.PeakSearchRadius;

            % % Ensure that Parameter Interface can run % %
            obj.ParamUdpLocalPort = cfg.MUExplorerPort;
            obj.ParamUdpRemotePort = cfg.MUConnectorPort;
            obj.ParamUdpSocketPort = cfg.MUConnectorUDP;
            obj.ParamUdpPeer = cfg.MUConnectorIP;
            connectorFolder = MUExplorer.resolve_path(fullfile(p,'..','MUConnector'));
            MUExplorer.ensureParamServer(connectorFolder, 'Port', cfg.MUConnectorPort);
            obj.startParamBridge('ReprocessOnUpdate', cfg.ReprocessParametersOnUpdate);
            try
                system(sprintf('start chrome %s:%d', cfg.MUConnectorIP, cfg.MUConnectorPort));
            catch ME
                warning(ME.identifier, 'Could not open browser: %s', ME.message);
            end
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
        refreshLineData(obj);
        
        handleScroll(obj, event);
        clickCallback(obj, event);
        handleMainAxesClick(obj);
        handleConvAxesClick(obj);
        keyHandler(obj, event);
        releaseCallback(obj);
        updatePointer(obj);

        deleteLastPeak(obj, idx);
        displaySelectedPeaks(obj);
        
        generateTemplate(obj, reset);
        confirmSpikes(obj);
        runConvolution(obj);
        newTemplateGroup(obj);
        subtractTemplate(obj);
        
        saveResults(obj);
        loadResults(obj);
        loadSignal(obj, SessionName, ExperimentNum);

        processSignal(obj, uni, sync);
        startParamBridge(obj, options);
        stopParamBridge(obj);

        saveResultsDEMUSE(obj);
        loadResultsDEMUSE(obj);
        loadSignalDEMUSE(obj, SessionName, ExperimentNum);

        onParamDatagram(obj);
    end

    methods (Access = protected)
        applyOptionsStruct(obj, s);
        addPeakSnippet(obj, x, y);
        updateTemplateMetadata(obj);
        updateTemplateInsetWaveforms(obj);
    end

    methods (Static, Access = public)
        p = resolve_path(p);
        ensureParamServer(serverPath, options);
        PNR = estimatePNR(MUPulses,IPT,fsamp, options);
        eSIG = extend(SIG, extFact);
        cfg = parseYAML(filepath);
        [E, D] = pcaesig(signal);
        [whitensignals, whiteningMatrix, dewhiteningMatrix] = whiteesig(signal, E, D)
        [ios,keep] = estimate_ios(MUPulses, fs, options)
        [emgZCA, W_zca, mu, sigma, stats] = zca_whiten_emg_masked(emg, ref_mask, options)
    end

    methods (Static, Access = protected)
        printHelp;
        cursor = getMagnifierCursor();
        [ref_signal, coordinates_plateau] = parseTargetPlateaus(sync);
    end
end
