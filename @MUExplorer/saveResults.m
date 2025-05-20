function saveResults(obj)
%SAVERESULTS  Save results from all manual sorting for this session/experiment.
if isempty(obj.ConfirmedSpikes) || isempty(obj.Template)
    warning('Nothing to save. Confirmed Spikes or Template missing.');
    return;
end

if obj.ManualFileSelection || isempty(obj.SessionName)
    if ~isempty(obj.SessionName)
        if exist(sprintf("%s/%s/MUExplorer", obj.DataRoot, obj.SessionName),'dir')==0
            mkdir(sprintf("%s/%s/MUExplorer", obj.DataRoot, obj.SessionName));
        end
        [file,path] = uiputfile('*.mat', 'Save MUExplorer Results', ...
            sprintf('%s/%s/MUExplorer/%s_%d_muresults.mat', ...
            obj.DataRoot, obj.SessionName, obj.SessionName, obj.ExperimentNum));
    else
        [file,path] = uiputfile('*.mat', 'Save MUExplorer Results', ...
            obj.DataRoot);
    end
    if isequal(file, 0)
        disp('Save canceled.');
        return;
    end

    savePath = fullfile(path, file);
else
    saveFolder= sprintf("%s/%s/MUExplorer",obj.DataRoot,obj.SessionName);
    if exist(saveFolder,'dir')==0
        mkdir(saveFolder);
    end
    savePath = sprintf("%s/%s_%d_muresults.mat", saveFolder, obj.SessionName, obj.ExperimentNum);
end
% Package Data
MUResults = struct;
MUResults.SessionName = obj.SessionName;
MUResults.ExperimentNum = obj.ExperimentNum;
MUResults.SampleRate = obj.SampleRate;
MUResults.ConfirmedSpikes = obj.ConfirmedSpikes;
MUResults.SelectedPeaks = obj.SelectedPeaks;
MUResults.Template = obj.Template;
MUResults.residual = obj.Data;  % Modified Data after subtraction
MUResults.description = obj.Description;
MUResults.Templates = obj.Templates;
MUResults.Spikes = obj.Spikes;
MUResults.Residuals = obj.Residuals;  % if tracked
MUResults.Bounds = obj.ConvMatchLim;
MUResults.Version = obj.Version;

% Save
save(savePath, '-struct', 'MUResults', '-v7.3');

fprintf('Saved MU results to:\n  %s\n', savePath);
end