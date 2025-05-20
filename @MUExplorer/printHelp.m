function printHelp()
fprintf('\n==== MUExplorer Key Bindings ====\n');
fprintf('  [H]              : Show this help message\n');
fprintf('  [Enter/Space]    : Generate template from selected peaks and run convolution\n');
fprintf('  [C]              : Confirm spikes from current template\n');
fprintf('  [ESCAPE]         : Reset selected peaks for current template\n');
fprintf('  [CTRL+S]         : Save current results to MUExplorer-style .mat file\n');
fprintf('  [ALT+S]          : Save current results to DEMUSE-style .mat file\n');
fprintf('  [CTRL+L]         : Load existing results for this session from MUExplorer-style .mat file\n');
fprintf('  [ALT+L]          : Load existing results for this session from DEMUSE-style .mat file\n');
fprintf('  [N]              : Start new template group\n');
fprintf('  [Tab]            : Switch to next template group\n');
fprintf('  [↑/↓]            : Navigate through template groups\n');
fprintf('  [←/→]            : Pan view left/right (75%% shift)\n');
fprintf('  [Backspace]      : Remove last clicked peak\n');
fprintf('\n==== MUExplorer Mouse Bindings ====\n');
fprintf('  [Left Click]             : Add peak at clicked channel/time\n');
fprintf('  [Right Click]            : Remove nearest peak at click location\n');
fprintf('  [Middle Click + Drag]    : Pan view\n');
fprintf('  [CTRL + Click + Drag]    : Draw zoom box to zoom in\n');
fprintf('  [Scroll Down]            : Reset zoom to original view\n');
fprintf('=================================\n\n');
end
