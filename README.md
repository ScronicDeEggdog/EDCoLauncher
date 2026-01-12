# EDCoLauncher

A Bash script designed to automate the installation, configuration, and launching of [**EDCoPilot**](https://www.razzafrag.com/) and [**EDCoPTER**](https://edcopter.net/) for Elite Dangerous on Linux. Optimized for **CachyOS**, **Bazzite**, **Steam Deck**, and **NixOS**.

## 🚀 Features

*   **Zero-Touch Setup**: Automatically fetches and installs the latest EDCoPilot .msi and EDCoPTER .exe releases from GitHub into your Elite Dangerous Proton prefix.
*   **Intelligent Pathing**: Detects `WINEPREFIX` via `protontricks` and resolves installation paths for both per-user and system-wide installs.
*   **Working Autofocus**: Runs the add-ons in the same container as the game, allowing route plotting, the pilot's dashboard and other features to work as intended.
*   **Stability Enhancements**:
    *   Disables Electron GPU sandboxing to prevent UI flickering/crashes in EDCoPTER.
*   **Auto Close**: Closes the add-ons gracefully when you close the game launcher, or the game window if using alongside MinEdLauncher.
*   **Advanced Logging**: Redirects `stdout` and `stderr` to timestamped, color-stripped log files for easy debugging.

## 📋 Prerequisites

*   **Elite Dangerous**: Installed via Steam (App ID: `359320`).
*   **Protontricks**: Must be installed and available in your `$PATH`.
*   **System Dependencies**: `curl`, `sed`, `grep`, `pgrep` and `tput` (standard on most distros).
*   **Elite Dangerous Proton Version**: `curl`, `sed`, `grep`, `pgrep` and `tput` (standard on most distros).

## 🛠️ Installation & Setup

1.  Download the latest release from [here](https://github.com/ScronicDeEggdog/EDCoLauncher/releases):
2.  Unzip the file
3.  Make the EDCoLauncher.sh file executable
4.  Read the configuration section below and make any changes you need to the config file
5.  Copy both files into the Elite Dangerous install directory. You can find the right folder by right clicking on the game in Steam, then going to Properties -> Installed Files -> Browse
6.  Check out the [useage](#-usage) section for instructions on how to use EDCoLauncher

## ⚙️ Configuration

The script reads from `EDCoLauncher_config`. If it doesn't exist, it applies safe defaults.

```bash
# Set to "true" for the first run to fetch and install latest GitHub releases. If you've already installed the add-ons, leave these set to "false"
INSTALL_EDCOPILOT="false"
INSTALL_EDCOPTER="false"

# Enable or disable apps. Setting these values to false will skip the launch of the relevant app. Note: EDCoPTER can't function without EDCoPilot running
EDCOPILOT_ENABLED="true"
EDCOPTER_ENABLED="true"

# Stability options
HOTAS_FIX_ENABLED="true" # Set to true to fix HOTAS-related game crashes
DISABLE_PROTON_ESYNC="false" # Set to true if you're hitting file descriptor limits (common on NixOS). This is a general compatibility option and should only be used if you're experiencing problems
DISABLE_PROTON_FSYNC="false" # Set to true to disbale Fsync in the wine prefix. This is a general compatibility option and should only be used if you're experiencing problems

# Optional paths 
EDCOPILOT_EXE_PATH="" # Specify the path to the LaunchEDCoPilot.exe file if you installed into a non-default location. Leave blank otherwise
EDCOPTER_EXE_PATH="" # Specify the path to the EDCoPTER.exe file if you installed into a non-default location. Leave blank otherwise
```

## 🖥️ Usage

To run EDCoPilot and EDCoPTER manually after the game launches, run the script from your terminal:
```bash
./EDCoLauncher.sh
```
To run the add-ons automatically withe the game, change your Steam Launch Options to:
```bash
%command% & ./EDCoLauncher.sh
```
To run the launcher alongside MinEdCopilot, change your Steam Launch Options to:
```bash
<MinEdLaunchOptions> & ./EDCoLauncher.sh
```
**Warning**
**EDCoLauncher does not support the use of the /autoquit option for MinEdLauncher**

## 📂 Troubleshooting & Logs
The script generates specific logs in its local directory:
*   **EDCoLauncher.log**: Core script execution and logic.
*   **EDCoLauncher_EDCoPilot_Install.log**: Output from the .msi installation process.
*   **EDCoLauncher_EDCoPTER_Install.log**: Output from the .exe installation process.
*   **EDCoLauncher_EDCoPilot.log**: Runtime output from EDCoPilot.
*   **EDCoLauncher_EDCoPTER.log**: Runtime output from EDCoPilot.

## ⚖️ License
This project is licensed under the GNU GPLv3 License.

## 🤝 Acknowledgments
[EDCoPilot](https://www.razzafrag.com/) by Razzafrag  
[EDCoPTER](https://edcopter.net/) by Mark Hollingworth  
[Elite Dangerous](https://www.elitedangerous.com/) by Frontier Developments  
[protontricks](https://github.com/Matoking/protontricks) by Matoking  
