# EDCoLauncher

A Bash script designed to automate the installation, configuration, and launching of [**EDCoPilot**](www.razzafrag.com) and [**EDCoPTER**](edcopter.net) for Elite Dangerous on Linux.

## 🚀 Features

*   **Native Steam Integration**: Leverages the **Steam Linux Client Runtime** and official Steam environment variables for maximum compatibility.
*   **Zero-Touch Setup**: Automatically fetches and installs the latest EDCoPilot `.msi` and EDCoPTER `.exe` releases from GitHub directly into your Elite Dangerous Proton prefix.
*   **Working Autofocus**: Runs add-ons within the official game container, ensuring route plotting, the pilot's dashboard, and overlays function as intended.
*   **Stability Enhancements**: 
    *   Includes HOTAS stability fix which is enabled by default
*   **Auto Close**: Gracefully terminates add-ons when the game launcher or game window (if using MinEdLauncher) is closed.
*   **Advanced Logging**: Redirects `stdout` and `stderr` to timestamped, color-stripped log files for easy debugging.
*   **Google TTS Supported**: You can set your json key in the config use Google TTS Service

## 📋 Prerequisites

*   **Elite Dangerous**: Installed via Steam (App ID: `359320`).
*   **Proton 10.0-3**: Other versions of Proton may work, but results might vary.
*   **System Dependencies**: `curl`, `sed`, `grep`, `pgrep`, and `tput` (standard on most Linux distributions).

## 🛠️ Installation & Setup

1.  Download the latest release from [here](https://github.com/ScronicDeEggdog/EDCoLauncher/releases).
2.  Unzip the archive.
3.  Make the script executable:
    ```bash
    chmod +x EDCoLauncher.sh
    ```
4.  Configure your preferences in `EDCoLauncher_config`. For a first-time install, set:
    ```bash
    INSTALL_EDCOPILOT="true"
    INSTALL_EDCOPTER="true"
    ```
5.  Copy `EDCoLauncher.sh` and `EDCoLauncher_config` into your Elite Dangerous install directory. 
    *   *Tip: Right-click the game in Steam > Properties > Installed Files > Browse.*
    *   *Tip: Use the root install directory, NOT the odyssey expansion directory*

## ⚙️ Configuration

The script reads from `EDCoLauncher_config`. If the file is missing, the script applies safe defaults.

```bash
###################
# General settings
###################

# Set to "true" for the first run to fetch and install latest GitHub releases. If you've already installed the add-ons, leave these set to "false"
INSTALL_EDCOPILOT="false"
INSTALL_EDCOPTER="false"

# The number of seconds to wait while trying to detect the launcher before exiting
LAUNCHER_DETECTION_TIMEOUT=30

####################
# EDCoPilot Settings
####################

# Enable or disable EDCoPilot. Setting this value to false will skip the launch of EDCoPilot. Note: EDCoPTER can't function without EDCoPilot running
EDCOPILOT_ENABLED="true"

# The number of seconds to wait while trying to detect the EDCoPilot GUI before exiting
EDCOPILOT_DETECTION_TIMEOUT=50

####################
# EDCoPTER Settings
####################

# Enable or disable EDCoPTER. Setting this value to false will skip the launch of EDCoPTER. Note: EDCoPTER can't function without EDCoPilot running
EDCOPTER_ENABLED="true"

# Enable or disable EDCoPTER headless mode. Enabling this will run EDCoPTER without a GUI (server only). Default is "false"
EDCOPTER_HEADLESS_ENABLED="false"

# Specify the TCP port EDCoPTER should listen on. Default is "4500". Leave empty to use default or saved EDCoPTER configuration
EDCOPTER_LISTEN_PORT=""

# Specify the IP address EDCoPTER should listen on. Default listens on all available local IPs "0.0.0.0". Leave empty to use default or saved EDCoPTER configuration
EDCOPTER_LISTEN_IP=""

# Specify the IP address of the EDCoPilot server. Default is the loopback address "127.0.0.1". Leave empty to use default or saved EDCoPTER configuration
EDCOPTER_EDCOPILOT_SERVER_IP=""

####################
# Stability options
####################

# Set to true to fix HOTAS-related game crashes
HOTAS_FIX_ENABLED="true"

#################
# Optional paths
#################

# Specify the path to the LaunchEDCoPilot.exe file if you installed into a non-default location. Leave blank otherwise
EDCOPILOT_EXE_PATH=""

# Specify the path to the EDCoPTER.exe file if you installed into a non-default location. Leave blank otherwise
EDCOPTER_EXE_PATH=""

#################
# Google TTS
#################

# Path to your Google Cloud JSON key file.
# Example: "/home/deck/Documents/edcopilot-key.json"
# Leave blank to disable.
GOOGLE_TTS_KEY_PATH=""


```

## 🖥️ Usage

<blockquote>
<p>[!IMPORTANT]
EDCoLauncher is optimized for Proton 10.0-3. Other versions of proton may not work.
</blockquote>

<blockquote>
<p>[!WARNING]
Running this script manually is not supported. You can monitor what the script is doing in realtime by running: </p><pre><code>tail -f EDCoLauncher.log</code></pre>
</blockquote>

To run the add-ons automatically with the game, change your Steam Launch Options to:
```bash
STEAM_COMPAT_LAUNCHER_SERVICE=container-runtime %command% & ./EDCoLauncher.sh
```
To run EDCoLauncher alongside MinEdLauncher, change your Steam Launch Options to:
```bash
STEAM_COMPAT_LAUNCHER_SERVICE=container-runtime <MinEdLaunchOptions> & ./EDCoLauncher.sh
```
<blockquote>
<p>[!WARNING]
Not compatible with the /Autoquit MinEdLauncher option
</blockquote>

## 📂 Troubleshooting & Logs
The script generates specific logs in its local directory:
*   **EDCoLauncher.log**: Core script execution and logic.
*   **EDCoLauncher_EDCoPilot_Install.log**: Output from the .msi installation process.
*   **EDCoLauncher_EDCoPTER_Install.log**: Output from the .exe installation process.
*   **EDCoLauncher_EDCoPilot.log**: Runtime output from EDCoPilot.
*   **EDCoLauncher_EDCoPTER.log**: Runtime output from EDCoPTER.

## ⚖️ License
This project is licensed under the GNU GPLv3 License.

## 🤝 Acknowledgments
[EDCoPilot](https://www.razzafrag.com/) by Razzafrag  
[EDCoPTER](https://edcopter.net/) by Mark Hollingworth  
[Elite Dangerous](https://www.elitedangerous.com/) by Frontier Developments 
