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
- Can optionally launch and connect to a **Node.js-based parameter server** for integration with external systems

---

## ⚙️ Prerequisites

### MATLAB
Requires MATLAB R2021b or later (earlier versions may work but are untested).

### Node.js (for parameter server support)
If you want MUExplorer to automatically launch and connect to the Node.js parameter server on startup, you must have **Node.js** installed.

1. Download and install Node.js from [https://nodejs.org/](https://nodejs.org/)  
   - **Recommended**: Use the LTS (Long-Term Support) version.
   - On Windows, check the box to add Node.js to your system `PATH` during installation.
2. Verify installation:
   ```bash
   node -v
   npm -v
   ```
   Both commands should print version numbers without error.
3. Ensure the `parameter_server.js` file is available in the expected location (see your `config.yaml` if customized).

When launching MUExplorer, if the parameter server is not running, the app will attempt to start it automatically.

---

## Quick Start
1. Download and unzip this repo.
2. Copy/paste `@MUExplorer` into any MATLAB workspace folder you like. Make sure your MATLAB Editor's current folder is set to that location.
3. Inside `@MUExplorer`, update `config.yaml` if you want to use auto file-name parsing/loading:
   + **DataRoot**, **InputSubfolder**, **InputSuffix**, and **LayoutFile** — Set these to match your experiment data structure. Example:
     ```
       <Your DataRoot Folder>/
       ├── <SessionName Folder> (e.g. "Max_2025_05_20")
       │  ├── tmsi_layout.mat         # contains REMAP indexing vector
       │  ├── <InputSubfolder>/
       │  │    ├── Max_2025_05_20_2_synchronized.mat
       ├── <Other Session Folders...>
     ```
   + **DemuseInputSubfolder** — Where to look for DEMUSE results (inside the SessionName folder).
   + **OutputSubfolder** — Where to save MUExplorer results.

---

## 🖥️ Launching MUExplorer

The constructor supports multiple calling styles via MATLAB’s `arguments` block.

### 1. Direct data input
If you have data `Data` (channels × samples) and a sample rate `fs`:
```matlab
app = MUExplorer(Data, fs);
```

### 2. Data + synchronization signal
If you have a synchronization/reference indicator `sync` (1 × samples):
```matlab
app = MUExplorer(Data, fs, sync);
```

### 3. Loading by session name and experiment number
If you’ve organized your data into the recommended folder structure:
```matlab
sessionName = "Max_2025_05_20";
experimentNum = 5;
app = MUExplorer(sessionName, experimentNum);
```

### 4. Loading DEMUSE results alongside experiment data
```matlab
app = MUExplorer(sessionName, experimentNum, true);
```

### 5. Using `options`
The constructor now accepts name–value pair options:
```matlab
app = MUExplorer("2025_03_06", 3, false, ...
    'DataRoot', "G:\Shared drives\NML_MetaWB\Data\MCP_08", ...
    'Prefix',   "MCP08_", ...
    'Suffix',   "_custom", ...
    'ConfigFile', "C:\path\to\my_config.yaml");
```

**Options:**
- `Prefix` (string) – Added before `sessionName` in filename construction
- `Suffix` (string) – Added after `sessionName` in filename construction
- `DataRoot` (string) – Override the default data root folder
- `ConfigFile` (string) – Path to a YAML configuration file

---

## Usage
Follow these steps for a typical spike template creation session:
1. Hold **Ctrl + Left Click** to select a region with spikes.
2. Left-click near peaks of spikes with consistent shape.
3. Press **Enter** to generate a template and run matched filter convolution.
4. Adjust lower/upper spike detection bounds as needed (Left/Right Click).
5. Regenerate or start a new template with **N**.
6. Save with **Ctrl + S** (MUExplorer format) or **Alt + S** (DEMUSE format).

---

## ⌨️ Keyboard Shortcuts

| Key / Combo   | Action                                                  |
|---------------|---------------------------------------------------------|
| `H`           | Show help                                                |
| `Enter`       | Generate template + convolution                         |
| `Space`       | Run convolution only                                    |
| `Escape`      | Reset selected peaks                                    |
| `Ctrl + S`    | Save MUExplorer file                                    |
| `Alt + S`     | Save DEMUSE file                                        |
| `Ctrl + L`    | Load MUExplorer file                                    |
| `Alt + L`     | Load DEMUSE file                                        |
| `N`           | New template group                                      |
| `Tab`         | Switch to next group                                    |
| `↑ / ↓`       | Navigate groups                                         |
| `← / →`       | Pan left/right                                          |

---

## 🖱️ Mouse & Zoom Controls

| Mouse Action             | Description                          |
|--------------------------|--------------------------------------|
| **Left Click**           | Add peak at clicked channel/time     |
| **Right Click**          | Remove nearest peak                  |
| **Middle Click + Drag**  | Pan                                  |
| **Ctrl + Click + Drag**  | Box zoom                             |
| **Mouse Scroll Down**    | Reset zoom                           |

---

## 💾 Output Formats

- **Native** (`*_muresults.mat`) – Templates, spikes, residuals, GUI state
- **DEMUSE-Compatible** (`*_DEMUSE.mat`) – `MUPulses`, `IPTs`, `PNR`, `SIG`, `ref_signal`

---

## 📂 Repository Structure

```
@MUExplorer/
├── MUExplorer.m
├── <Methods of MUExplorer>
├── config.yaml
```

---

## 📢 Citation / Acknowledgments

If you use MUExplorer in your work, please cite this repository or reference the DEMUSE format.

---

## 📧 Contact

Developed by the **Neuro-Mechatronics Lab**.  
For questions, open an issue or submit a pull request.
