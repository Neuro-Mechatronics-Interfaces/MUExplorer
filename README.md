# `MUExplorer` #

**`MUExplorer`** is an interactive MATLAB GUI for manually identifying and refining motor unit templates from high-density surface EMG (HDsEMG) signals. It allows users to click-select spike events, generate templates, run template-matching convolution, and export results in a DEMUSE-compatible format.

---

## 🚀 Features

- Visualizes multi-channel HDsEMG data with per-channel vertical stacking
- Manual spike peak selection and template averaging
- Matched filter convolution for spike detection
- Subtraction of detected motor units to reveal residual activity
- Zooming, panning, and keyboard-driven interaction
- Supports export in [DEMUSE-compatible format](https://demuse.feri.um.si/)
- Handles data from synchronized `.mat` recordings and provides GUI layout for reviewing and editing MU templates

## Quick Start
1. Download and unzip this repo.
2. Copy/paste @MUExplorer into whatever MATLAB workspace folder you like. Make sure your MATLAB Editor workspace path is set to that folder.
3. Inside @MUExplorer folder there is a `config.yaml` if you want to use the auto file-name parsing/loading, you will want to update:
  + DataRoot, InputSubfolder, InputSuffix, and LayoutFile - Set this to the folder containing your experiment data folders. Structure should be:
  ```
    <Your DataRoot Folder>/
    ├── <Your SessionName Folder, e.g. "Max_2025_05_20" for SessionName>
    |  ├── <LayoutFile (e.g. "tmsi_layout.mat")> -- Should contain REMAP indexing vector, such that `obj.Data = data(REMAP,:);` puts the rows in order according to the grid layout specified in the Grids array of config.yaml.
    |  ├── <InputSubfolder> (can be multiple "/" delimited filepath levels)
    |       ├──<Your data file(s) (e.g. "Max_2025_05_20_2_synchronized.mat" where _synchronized.mat is <InputSuffix> and 2 is ExperimentNum)>
    |
    ├── <Your Other Session Folders...>
  ```

You can open the app by either giving your data directly, i.e. if you have `N` channels x `M` samples data in time-series `data` with sample rate `fs`, then you can simply specify:
```
app = MUExplorer(data, fs);
```
If you have a synchronization/reference indicator (i.e. a discrete indicator of when the desired contraction levels were happening throughout your experiment), then it should be given as a `1 x M` array `sync`:
```
app = MUExplorer(data, fs, sync);
```
If you've set up the folder data structure, then you can also load in a specific experiment using string `sessionName` and integer `experimentNum` e.g.
```
sessionName = "Max_2025_05_20";
experimentNum = 5;
app = MUExplorer(sessionName, experimentNum);
```
If you set up your folders and config first, this way is preferred because ultimately it can make dealing with the data easier. For one-off ad hoc usage it will probably be easier to use by specifying the data, sample rate, and ref/sync signal explicitly.  

---

## ⌨️ Keyboard Shortcuts

| Key / Combo       | Action                                                  |
|-------------------|----------------------------------------------------------|
| `H`               | Show this help message                                   |
| `Enter/Space`     | Generate template from selected peaks and run matched filter convolution |
| `Escape`          | Reset selected peaks                                     |
| `Ctrl + S`        | Save results to MUExplorer-style `.mat` file             |
| `Alt + S`         | Save results to DEMUSE-compatible `.mat` file            |
| `Ctrl + L`        | Load results from MUExplorer-style `.mat` file           |
| `Alt + L`         | Load results from DEMUSE-compatible `.mat` file          |
| `N`               | Start a new template group                               |
| `Tab`             | Switch to next template group                            |
| `↑ / ↓`           | Navigate through template groups                         |
| `← / →`           | Pan view left/right by 75%% of current view              |
| `Backspace`       | Remove last selected peak                                |

---

## 🖱️ Mouse & Zoom Controls

| Mouse Action                | Description                                      |
|----------------------------|--------------------------------------------------|
| **Left Click**             | Add peak at clicked channel/time                 |
| **Right Click**            | Remove nearest peak                              |
| **Middle Click + Drag**    | Pan view                                         |
| **Ctrl + Click + Drag**    | Draw box to zoom in                              |
| **Mouse Scroll Down**      | Reset zoom to original view                      |

---

## 💾 Output Format

Results can be saved in two formats:
- **Native Format** (`*_muresults.mat`): Includes templates, spikes, residuals, and GUI state.
- **DEMUSE-Compatible Format** (`*_DEMUSE.mat`): Includes `MUPulses`, `IPTs`, `PNR`, `SIG`, and `ref_signal` fields for downstream use with DEMUSE pipelines.

---

## 📂 Repository Structure

```
@MUExplorer/
├── MUExplorer.m
├── <Methods of MUExplorer>
```
To add it to a different project, just copy/paste the full @MUExplorer folder and its contents to the location where your Editor Workspace will be when you want to use it. 

---

## 📢 Citation / Acknowledgments

If you use MUExplorer in your work, please consider citing this repository or referencing the associated DEMUSE format. Contributions welcome!

---

## 📧 Contact

Developed and maintained by researchers at the **Neuro-Mechatronics Lab**.  
For questions or contributions, open an issue or submit a pull request.
