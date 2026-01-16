#!/bin/bash

############################
# Disable Steam Game Overlay
############################

unset LD_PRELOAD

############################
# General vars
############################
username="$(whoami)"
os_pretty_name=$(. /etc/os-release && echo "$PRETTY_NAME")
os_id=$(. /etc/os-release && echo "$ID")
os_like=$(. /etc/os-release && echo "$ID_LIKE")
config_file_path="$PWD/EDCoLauncher_config"
log_file_path="$PWD/EDCoLauncher.log"

############################
# Text helpers
############################
tab=$'\t'
colour_red=$(tput setaf 1)
colour_green=$(tput setaf 2)
colour_yellow=$(tput setaf 3)
colour_cyan=$(tput setaf 6)
colour_reset=$(tput sgr0)

strip_colour() {
    sed -Eu 's/\x1b(\[[0-9;]*[mGK]|\(B)//g'
}

# Send output to the log file with no colour chars and with timestamps
exec > >(stdbuf -oL tee -a >(strip_colour | grep --line-buffered . | while IFS= read -r line; do printf '%(%Y-%m-%d %H:%M:%S)T %s\n' -1 "$line"; done >> "${log_file_path}")) 2>&1

echo ""
echo "${colour_cyan}INFO:${colour_reset} Starting execution"

############################
# Steam vars
############################

# Steam Paths
steam_install_path=$(readlink -f "$HOME/.steam/root") # Gets the Steam install path on the system

if [ ! -d "${steam_install_path}" ]; then
    echo "${colour_red}ERROR:${colour_reset} Couldn't find your Steam install path. If you're running this script manually and you're using a flatpak install of Steam, it won't work. You must run the script using the games Lauch Options. Exiting."
    exit 1
fi

steam_base_path="${steam_install_path}/steamapps"
steam_pressure_vessel_bin_path="${steam_base_path}/common/SteamLinuxRuntime_sniper/pressure-vessel/bin"
steam_compat_data_path="${steam_base_path}/compatdata"
steam_library_file="${steam_install_path}/config/libraryfolders.vdf"

############################
# Elite Dangerous vars
############################
ed_app_id="359320"
ed_wine_prefix=""

ed_library_paths=$(awk -v appid="${ed_app_id}" '
    /"path"/ {
        current_path = $2;
        gsub(/"/, "", current_path)
    }
    /"apps"/ { in_apps = 1 }
    in_apps && $1 ~ "\""appid"\"" {
        print current_path
    }
    /}/ && in_apps { in_apps = 0 }
' "${steam_library_file}")

# Loop through each found path to create the wine prefixes
for path in $ed_library_paths; do
    full_prefix="${path}/steamapps/compatdata/${ed_app_id}/pfx"
    if [ -e "${full_prefix}" ]; then
        ed_wine_prefix="${full_prefix}"
        break
    fi
done

if [[ -z "${ed_wine_prefix}" ]]; then
    echo "${colour_red}ERROR:${colour_reset} Couldn't find a suitable game prefix in your libraryfolders.vdf file. Make sure the the library Elite Dangerous is installed in is accessible."
    exit 1
fi

ed_proton_path=$(grep -m 1 -E "/(common|compatibilitytools.d)/[^/]*(Proton|proton)" "$(dirname ${ed_wine_prefix})/config_info" | sed 's|/files/.*||') # Gets the path to the proton binary used by Elite Dangerous

############################
# WINE & Steam environment vars
############################

export WINEFSYNC=1
export WINEPREFIX="${ed_wine_prefix}"
export WINELOADER="${ed_proton_path}/files/bin/wine"
export WINESERVER="${ed_proton_path}/files/bin/wineserver"
export SteamGameId="${ed_app_id}"
export STEAM_COMPAT_DATA_PATH="${steam_compat_data_path}"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="${steam_install_path}"
export STEAM_LINUX_RUNTIME_LOG=1
export STEAM_LINUX_RUNTIME_VERBOSE=1
export PROTON_LOG=1
export PROTON_WINE="${WINELOADER}"
export WINEDEBUG="+fixme,+err,+loaddll,+warn"
unset LD_LIBRARY_PATH

############################
# EDCoPilot & EDCoPTER vars
############################
ignore_pattern="Fossilize INFO|gameoverlayrenderer.so|WARN: Skipping fix execution."
edcopilot_log_file="$PWD/EDCoLauncher_EDCoPilot.log"
edcopter_log_file="$PWD/EDCoLauncher_EDCoPTER.log"
edcopilot_install_log_file="$PWD/EDCoLauncher_EDCoPilot_Install.log"
edcopter_install_log_file="$PWD/EDCoLauncher_EDCoPTER_Install.log"
edcopilot_default_install_exe_path="${ed_wine_prefix}/drive_c/EDCoPilot/LaunchEDCoPilot.exe"
edcopter_default_per_user_exe_path="${ed_wine_prefix}/drive_c/users/steamuser/AppData/Local/Programs/EDCoPTER/EDCoPTER.exe"
edcopter_default_all_users_exe_path="${ed_wine_prefix}/drive_c/Program Files/EDCoPTER/EDCoPTER.exe"

# Check the per-user install location of EDCoPTER first and fall back on the system-wide install location
if [[ -f "${edcopter_default_per_user_exe_path}" ]]; then
    edcopter_default_install_exe_path="${edcopter_default_per_user_exe_path}"
else
    edcopter_default_install_exe_path="${edcopter_default_all_users_exe_path}"
fi

#############################
# Handle config file
#############################

[[ -f "${config_file_path}" ]] && . "${config_file_path}" || echo "${colour_yellow}WARNING:${colour_reset} Config file does not exist. Setting defaults"

    # General settings
    install_edcopilot="${INSTALL_EDCOPILOT:-false}"
    install_edcopter="${INSTALL_EDCOPTER:-false}"
    edcopilot_enabled="${EDCOPILOT_ENABLED:-true}"
    edcopter_enabled="${EDCOPTER_ENABLED:-true}"
    launcher_detection_timeout="${LAUNCHER_DETECTION_TIMEOUT:-30}"
    edcopilot_detection_timeout="${EDCOPILOT_DETECTION_TIMEOUT:-40}"

    # Stability options
    hotas_fix_enabled="${HOTAS_FIX_ENABLED:-true}"

    # Optional paths
    edcopilot_path="${EDCOPILOT_EXE_PATH:-}"
    edcopter_path="${EDCOPTER_EXE_PATH:-}"

    # Handle empty path variables
    edcopilot_final_path=$([[ -z "$edcopilot_path" ]] && echo "${edcopilot_default_install_exe_path}" || echo "${edcopilot_path}")
    edcopter_final_path=$([[ -z "$edcopter_path" ]] && echo "${edcopter_default_install_exe_path}" || echo "${edcopter_path}")

#############################
# Pre-flight cleanup
#############################

if [[ -f "${edcopilot_log_file}" ]]; then
    echo "${colour_cyan}INFO:${colour_reset} Cleaning up temp EDCoPilot log file"
    rm -f "${edcopilot_log_file}"
fi

if [[ -f "${edcopter_log_file}" ]]; then
    echo "${colour_cyan}INFO:${colour_reset} Cleaning up temp EDCoPTER log file";
    rm -f "${edcopter_log_file}"
fi

############################
# Check for existing installs
############################

edcopilot_installed="false"
edcopter_installed="false"

if [[ -f "${edcopilot_final_path}" ]]; then
    edcopilot_installed="true"
fi

if [[ -f "${edcopter_final_path}" ]]; then
    edcopter_installed="true"
fi

############################
# Install Logic
############################

edcopter_install_failed="false"

# Download and install EDCoPilot if INSTALL_EDCOPILOT is set to true

if [[ "${install_edcopilot}" == "true" ]]; then
    if [[ "${edcopilot_installed}" == "false" ]]; then
        latest_edcopilot_msi_url=$(curl -s "https://api.github.com/repos/Razzafrag/EDCoPilot-Installer/releases/latest" | grep -oP '"browser_download_url":\s*"\K[^"]+\.msi' | head -n 1)

        echo "${colour_cyan}INFO:${colour_reset} Downloading EDCoPilot installer. Please wait..."
        curl -s -L -O --output-dir "${ed_wine_prefix}/drive_c" "${latest_edcopilot_msi_url}"

        echo "${colour_cyan}INFO:${colour_reset} Installing EDCoPilot. Please wait..."

        # Set WINE vars
        "${WINELOADER}" start /wait msiexec /i "${ed_wine_prefix}/drive_c/$(basename $latest_edcopilot_msi_url)" /quiet /qn /norestart > "${edcopilot_install_log_file}" 2>&1
        sleep 2

        if [[ ! -f "${edcopilot_final_path}" ]]; then
            echo "${colour_red}ERROR:${colour_reset} It looks like EDCoPilot wasn't installed properly. Please check the install log here: ${edcopilot_install_log_file}"
            exit 1
        else
            echo "${colour_cyan}INFO:${colour_reset} EDCoPilot was installed successully. Setting the INSTALL_EDCOPILOT config variable back to false"
            edcopilot_installed="true"
            sed -i 's/^INSTALL_EDCOPILOT=.*/INSTALL_EDCOPILOT="false"/' "${config_file_path}" # Set the INSTALL_EDCOPILOT config variable to false to prevent re-runs
        fi

        echo "${colour_cyan}INFO:${colour_reset} Cleaning up EDCoPilot installer"
        rm -f "${ed_wine_prefix}/drive_c/$(basename $latest_edcopilot_msi_url)"
    else
        echo "${colour_cyan}WARN:${colour_reset} The INSTALL_EDCOPILOT config variable was set to true, but I detected an existing install here: $(dirname "${edcopilot_final_path}"). Setting the INSTALL_EDCOPILOT config variable back to false"
        sed -i 's/^INSTALL_EDCOPILOT=.*/INSTALL_EDCOPILOT="false"/' "${config_file_path}" # Set the INSTALL_EDCOPILOT config variable to false to prevent re-runs
    fi
fi

# Download and install EDCoPTER if INSTALL_EDCOPTER is set to true and if EDCoPilot is installed

if [[ ${install_edcopter} == "true" ]]; then
    if [[ -f "${edcopilot_final_path}" ]]; then
        if [[ ! -f "${edcopter_final_path}" ]]; then

            latest_edcopter_exe_url=$(curl -s "https://api.github.com/repos/markhollingworth-worthit/EDCoPTER2.0-public-releases/releases/latest" | grep -oP '"browser_download_url":\s*"\K[^"]+\.exe' | head -n 1)

            echo "${colour_cyan}INFO:${colour_reset} Downloading EDCoPTER installer. Please wait..."
            curl -s -L -O --output-dir "${ed_wine_prefix}/drive_c" "${latest_edcopter_exe_url}"

            echo "${colour_cyan}INFO:${colour_reset} Installing EDCoPTER. Please wait..."

            # Install the app
            "${WINELOADER}" start /wait /unix "${ed_wine_prefix}/drive_c/$(basename $latest_edcopter_exe_url)" /S /allusers /D="C:\Program Files\EDCoPTER" > "${edcopter_install_log_file}" 2>&1
            sleep 2

            if [[ ! -f "${edcopter_final_path}" ]]; then
                echo "${colour_red}ERROR:${colour_reset} It looks like EDCoPTER wasn't installed properly. Please check the install log here: ${edcopter_install_log_file}"
                edcopter_install_failed="true"

            else
                echo "${colour_cyan}INFO:${colour_reset} EDCoPTER was installed successully. Setting the INSTALL_EDCOPTER config variable back to false"
                edcopter_installed="true"
                sed -i 's/^INSTALL_EDCOPTER=.*/INSTALL_EDCOPTER="false"/' "${config_file_path}" # Set the INSTALL_EDCOPTER config variable to false to prevent re-runs
            fi

            echo "${colour_cyan}INFO:${colour_reset} Cleaning up EDCoPTER installer"
            rm -f "${ed_wine_prefix}/drive_c/$(basename $latest_edcopter_exe_url)"
        else
            echo "${colour_yellow}WARN:${colour_reset} The INSTALL_EDCOPTER config variable was set to true, but I detected an existing install here: $(dirname "${edcopter_final_path}"). Setting the INSTALL_EDCOPTER config variable back to false"
            sed -i 's/^INSTALL_EDCOPTER=.*/INSTALL_EDCOPTER="false"/' "${config_file_path}" # Set the INSTALL_EDCOPTER config variable to false to prevent re-runs
        fi
    else
        echo "${colour_yellow}WARN:${colour_reset} Can't install EDCoPTER as a valid install of EDCoPilot wasn't detected"
    fi
fi

###################################################################
# wait for the Elite Dangerous Launcher OR MinEdLauncher to start
###################################################################

# wait for launcher and exit if one isn't found within the number of seconds defined in launcher_detection_timeout setting

launcher_detection_count=0
launcher_detection_interval=1

echo "${colour_cyan}INFO:${colour_reset} Waiting for Elite Dangerous Launcher or MinEdLauncher to start for ${launcher_detection_timeout} seconds. You can change this value in the config file."
while ! pgrep -f "Z:..*steamapps.common.Elite Dangerous.EDLaunch.exe.*" > /dev/null && ! pgrep -f "MinEdLauncher" > /dev/null; do

    seconds_left=$(( $launcher_detection_timeout - $launcher_detection_count ))
    echo -ne "${seconds_left} seconds remaining...\r"

    if (( $launcher_detection_count >= $launcher_detection_timeout )); then
        echo "${colour_red}ERROR:${colour_reset} Failed to detect a running launcher. Exiting"
        exit 1
    fi

    sleep $launcher_detection_interval
    ((launcher_detection_count++))
done

# Determine the launcher type

echo "${colour_cyan}INFO:${colour_reset} Found a launcher. Determining the launcher type..."

# Get the correct launcher PID
if pgrep -f "MinEdLauncher" > /dev/null; then
    echo "${colour_cyan}INFO:${colour_reset} Detected MinEdLauncher. Waiting for game window to spawn..."

    game_window_detection_count=0
    game_window_detection_timeout=60
    while ! pgrep -f "Z:..*EliteDangerous64.exe" > /dev/null; do
        seconds_left=$(( $game_window_detection_timeout - $game_window_detection_count ))
        echo -ne "${seconds_left} seconds remaining...\r"

        if (( $game_window_detection_count >= $game_window_detection_timeout )); then
            echo "${colour_red}ERROR:${colour_reset} Failed to detect a running game window. Exiting"
            exit 1
        fi

        sleep 1
        ((launcher_detection_count++))
    done

    echo "${colour_cyan}INFO:${colour_reset} Getting game window PID..."
    edlauncher_pid=$(pgrep -f "Z:..*EliteDangerous64.exe")

    if [[ -n "${edlauncher_pid}" ]]; then
        echo "${colour_cyan}INFO:${colour_reset} Elite Dangerous window PID: ${edlauncher_pid}. Preparing to launch Add-ons..."
    else
        echo "${colour_red}ERROR:${colour_reset} Couldn't find the Elite Dangerous window PID. Exiting."
        exit 1
    fi
else
    echo "${colour_cyan}INFO:${colour_reset} Detected Elite Dangerous Launcher. Getting Launcher PID..."
    edlauncher_pid=$(pgrep -f "Z:..*steamapps.common.Elite Dangerous.EDLaunch.exe.*")
    if [[ -n "${edlauncher_pid}" ]]; then
        echo "${colour_cyan}INFO:${colour_reset} Detected the Elite Dangerous Launcher (PID: ${edlauncher_pid}). Preparing to launch Add-ons..."
        echo ""
    else
        echo "${colour_red}ERROR:${colour_reset} Couldn't find the Elite Dangerous Launcher PID. Exiting."
        exit 1
    fi
fi

# Get the correct path to the steam-linux-client-runtime binary

steam_linux_client_runtime_cmd="${steam_install_path}$(pgrep -fa "SteamLinuxRuntime_.*/pressure-vessel" | sed -n 's|.*\(/[^ ]\+/common/SteamLinuxRuntime_[^/]\+\)/.*|\1|p' | head -n 1)/pressure-vessel/bin/steam-runtime-launch-client"

#############################
# Print configuration summary
#############################
echo "${colour_cyan}Current User:${colour_reset} ${username}"
echo "${colour_cyan}OS Pretty Name:${colour_reset} ${os_pretty_name}"
echo "${colour_cyan}OS ID:${colour_reset} ${os_id}"
echo "${colour_cyan}OS Like:${colour_reset} ${os_like}"
echo ""
echo "${colour_cyan}Steam Install Path:${colour_reset} ${steam_install_path}"
echo "${colour_cyan}Steam Linux Client Runtime Path:${colour_reset} ${steam_linux_client_runtime_cmd}"
echo "${colour_cyan}Elite Dangerous Wine Prefix:${colour_reset} ${ed_wine_prefix}"
echo "${colour_cyan}Elite Dangerous Proton Path:${colour_reset} ${ed_proton_path}"
echo "${colour_cyan}Elite Dangerous Steam App ID:${colour_reset} ${ed_app_id}"
echo ""
echo "${colour_cyan}Config File Path:${colour_reset} ${config_file_path}"
echo "${colour_cyan}EDCoPilot Enabled:${colour_reset} ${edcopilot_enabled}"
echo "${colour_cyan}EDCoPTER Enabled:${colour_reset} ${edcopter_enabled}"
echo "${colour_cyan}EDCoPilot Path:${colour_reset} ${edcopilot_final_path}"
echo "${colour_cyan}EDCoPTER Path:${colour_reset} ${edcopter_final_path}"
echo "${colour_cyan}HOTAS Fix Enabled:${colour_reset} ${hotas_fix_enabled}"
echo ""

##########################################################
# Manage windows.gaming.input to fix HOTAS crash problem
##########################################################

if "${WINELOADER}" reg query "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "windows.gaming.input" &>/dev/null; then
    echo "${colour_cyan}INFO:${colour_reset} The HOTAS fix to override windows.gaming.input is currently active."
    if [[ "${hotas_fix_enabled}" != "true" ]]; then
        if "${WINELOADER}" reg delete "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "windows.gaming.input" /f &>/dev/null; then
            echo "${colour_cyan}INFO:${colour_reset} Removed the windows.gaming.input DLL override from the wine prefix. The HOTAS fix is now NOT active."
        else
            echo "${colour_yellow}WARNING:${colour_reset} Failed to remove the windows.gaming.input DLL override from the wine prefix. Consider doing this manually through the protontricks GUI"
        fi
    fi
else
    if [[ "${hotas_fix_enabled}" == "true" ]]; then
        echo "${colour_cyan}INFO:${colour_reset} The HOTAS fix to override windows.gaming.input was not found."
        if "${WINELOADER}" reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "windows.gaming.input" /t REG_SZ /d "" /f &>/dev/null; then
            echo "${colour_cyan}INFO:${colour_reset} Added the windows.gaming.input DLL override from the wine prefix. The HOTAS fix is now active."
        else
            echo "${colour_yellow}WARNING:${colour_reset} Failed to add the windows.gaming.input DLL override from the wine prefix. Consider doing this manually through the protontricks GUI"
        fi
    fi
fi

####################
# Launch EDCoPilot
####################

if [[ "$edcopilot_enabled" == "true" && "${edcopilot_installed}" == "true" ]]; then

    # Set RunningOnLinux EDCoPilot flag to 1
    echo "${colour_cyan}INFO:${colour_reset} Setting the EDCoPilot RunningOnLinux flag to 1. This might need a relaunch to take effect"
    sed -i "s/RunningOnLinux=\"0\"/RunningOnLinux=\"1\"\\r/" "$(dirname ${edcopilot_final_path})/EDCoPilot.ini"
    sed -i "s/RunningOnLinux=\"0\"/RunningOnLinux=\"1\"\\r/" "$(dirname ${edcopilot_final_path})/edcopilotgui.ini"

    sleep 1

    echo ""
    echo "${colour_cyan}INFO:${colour_reset} Launching EDCoPilot"

    $steam_linux_client_runtime_cmd --bus-name="com.steampowered.App${ed_app_id}" --pass-env-matching="WINE*" --pass-env-matching="STEAM*" --pass-env-matching="PROTON*" --env="SteamGameId=${ed_app_id}" -- "${WINELOADER}" "${edcopilot_final_path}" &> "${edcopilot_log_file}" &
    edcopilot_pid=$!

    #echo "${edcopilot_pid}"

    sleep 4

    # Check if the process is still running
    if kill -0 $edcopilot_pid 2>/dev/null; then
        echo "${colour_cyan}INFO:${colour_reset} EDCoPilot launched successfully (PID: ${edcopilot_pid})"
    else
        echo "${colour_red}ERROR:${colour_reset} EDCoPilot failed to start or crashed immediately. Check ${edcopilot_log_file}"
        exit
    fi
else
    echo "${colour_red}ERROR:${colour_reset} EDCoPilot was either not enabled in the config file or the install wasn't found at this path: ${edcopilot_final_path}. Exiting."
    exit 1
fi

#################################
# Allow EDCoPilot to initialise
#################################

# Wait for EDCoPilot to start

echo "${colour_cyan}INFO:${colour_reset} Waiting for EDCoPilot to fully initialise..."

edcopilot_detection_count=0
edcopilot_detection_interval=1

while ! pgrep -f "EDCoPilotGUI2.exe" > /dev/null; do

    seconds_left=$(( $edcopilot_detection_timeout - $edcopilot_detection_count ))
    echo -ne "${seconds_left} seconds remaining...\r"

    if (( $edcopilot_detection_count >= $edcopilot_detection_timeout )); then
        echo "${colour_red}ERROR:${colour_reset} Failed to find a running EDCoPilot GUI after ${edcopilot_detection_timeout} seconds. Exiting"

        kill -15 $(pgrep -f "EDCoPilot.exe|LaunchEDCoPilot.exe|EDCoPilotGUI2.exe") &>/dev/null

        exit 1
    fi

    sleep $edcopilot_detection_interval
    ((edcopilot_detection_count++))
done

# Give another X seconds grace period for EDCoPilot to fully launch

initialise_count=35

echo "${colour_cyan}INFO:${colour_reset} Detected EDCoPilot GUI. Waiting for ${initialise_count} seconds for it to initialise..."

while (( ${initialise_count} >= 0 )); do
    sleep 1
    initialise_count=$((initialise_count - 1))
done

########################
# Start EDCoPTER
########################

if [[ "$edcopter_enabled" == "true" && ${edcopter_installed} = "true" ]]; then
    echo ""
    echo "${colour_cyan}INFO:${colour_reset} Launching EDCoPTER"
    $steam_linux_client_runtime_cmd --bus-name="com.steampowered.App${ed_app_id}" --pass-env-matching="WINE*" --pass-env-matching="STEAM*" --pass-env-matching="PROTON*" --env="SteamGameId=${ed_app_id}" -- "${WINELOADER}" "${edcopter_final_path}" &> "${edcopter_log_file}" &
    edcopter_pid=$!

    sleep 4

    # Check if the process is still running
    if kill -0 $edcopter_pid 2>/dev/null; then
        echo "${colour_cyan}INFO:${colour_reset} EDCoPTER launched successfully (PID: ${edcopter_pid})"
    else
        echo "${colour_red}ERROR:${colour_reset} EDCoPTER failed to start or crashed immediately. Check ${edcopter_log_file}"
    fi
else
    echo "${colour_yellow}WARNING:${colour_reset} EDCoPTER was either not enabled in the config file or the install wasn't found at this path: ${edcopter_final_path}. Consider installing EDCoPTER or setting the enabled flag to false in the config file"
fi

#######################################################################################
# Monitor the Elite Dangerous Launcher and exit EDCoPilot and EDCoPTER once it closed
#######################################################################################

echo ""
echo "${colour_cyan}INFO:${colour_reset} To close EDCoPilot and EDCoPTER, please close the Elite Dangerous Launcher"

while kill -0 "$edlauncher_pid" 2>/dev/null; do
    sleep 1
done

#
# Send murder signals to EDCoPTER
#

echo "${colour_cyan}INFO:${colour_reset} Closing EDCoPTER. Please wait"
kill -15 $(pgrep -f "EDCoPTER.exe") &>/dev/null

#
# Gracefully shutdown EDCoPilot
#

echo "${colour_cyan}INFO:${colour_reset} Closing EDCoPilot. Please wait"

# Check if EDCoPilot is still running
if pgrep -f "EDCoPilotGUI2.exe" > /dev/null; then

    echo "${colour_cyan}INFO:${colour_reset} Sending graceful shutdown request"
    # Send graceful shutdown command to EDCoPilot
    echo Shutdown >> "$(dirname "${edcopilot_final_path}")/EDCoPilot.request.txt"

    # Wait for EDCoPilot to shutdown
    shutdown_timeout=30
    shutdowntimout_count=0
    while pgrep -f "EDCoPilot.exe|LaunchEDCoPilot.exe|EDCoPilotGUI2.exe" > /dev/null; do

        seconds_left=$(( $shutdown_timeout - $shutdowntimout_count ))
        echo -ne "${seconds_left} seconds remaining...\r"

        if (( $shutdowntimout_count >= $shutdown_timeout )); then
            echo "${colour_red}ERROR:${colour_reset} EDCoPilot failed to exit after ${shutdown_timeout} seconds. Forcefully killing the processes..."

            kill -9 $(pgrep -f "EDCoPilot.exe|LaunchEDCoPilot.exe|EDCoPilotGUI2.exe") &>/dev/null
        fi
        sleep 1
        ((shutdowntimout_count++))
    done

    echo "${colour_cyan}INFO:${colour_reset} EDCoPilot has closed successfully."

    # Clean up the EDCoPilot.request.txt in case there is a race condition
    rm -f "$(dirname "${edcopilot_final_path}")/EDCoPilot.request.txt" &>/dev/null
else
    # Wait for EDCoPilot to shutdown for 30 seconds

    shutdown_timeout=30
    shutdowntimout_count=0
    while pgrep -f "EDCoPilot.exe|LaunchEDCoPilot.exe|EDCoPilotGUI2.exe" > /dev/null; do

        seconds_left=$(( $shutdown_timeout - $shutdowntimout_count ))
        echo -ne "${seconds_left} seconds remaining...\r"

        if (( $shutdowntimout_count >= $shutdown_timeout )); then
            echo "${colour_red}ERROR:${colour_reset} EDCoPilot failed to exit after ${shutdown_timeout} seconds. Forcefully killing the processes..."

            edcopilot_pids=$(pgrep -f "EDCoPilot.exe|LaunchEDCoPilot.exe|EDCoPilotGUI2.exe")
            if [ -n "${edcopilot_pids}" ]; then
                disown ${edcopilot_pids} 2>/dev/null
                kill -15 ${edcopilot_pids} &>/dev/null
            fi
        fi

        sleep 1
        ((shutdowntimout_count++))
    done
fi

#
# Ensure all processes in the Wine prefix for Elite Dangerous are stopped properly
#

echo "${colour_cyan}INFO:${colour_reset} Closing EDCoPTER and cleaning up Wine prefix subprocesses"
"${WINESERVER}" -k
"${WINESERVER}" -w

echo "${colour_cyan}INFO:${colour_reset} All done! Exiting"
