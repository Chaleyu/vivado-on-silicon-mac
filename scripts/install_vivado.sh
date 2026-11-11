#!/bin/bash

# This runs the Vivado installer in batch mode.

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_linux

install_bin_path=$(tr -d "\n\r\t " < "/home/user/scripts/install_bin")
file_hash=$(tr -d "\n\r\t " < "/home/user/hash")

# setup.sh records the detected version. It is authoritative for installers whose
# hash is not in the tracked list (e.g. a newer release detected from the file
# name after explicit user confirmation).
vivado_version=""
if [ -f "/home/user/installer_version" ]; then
    vivado_version=$(tr -d "\n\r\t " < "/home/user/installer_version")
fi
if [ -z "$vivado_version" ] || [ ! -f "/home/user/scripts/install_configs/${vivado_version}.txt" ]; then
    if ! set_vivado_version_from_hash "$file_hash"; then
        f_echo "Invalid installer hash. Add its MD5 to /home/user/scripts/hashes.sh"
        exit 1
    fi
fi

installer_extension="${install_bin_path##*.}"
installer_extension="${installer_extension,,}"

# AMD retires the online files used by older web installers; warn early.
if [ "$installer_extension" = "bin" ] && [ -n "$vivado_version" ] \
&& [ -n "$web_installer_warn_before" ] && [ "$vivado_version" -lt "$web_installer_warn_before" ] 2>/dev/null; then
    f_echo "Note: AMD marks older web installers as obsolete and may not provide"
    f_echo "their online files anymore. If the download fails, use the SFD (full)"
    f_echo "installer for Vivado $vivado_version instead."
fi

if [ "$installer_extension" = "bin" ]; then
    # Extract installer
    f_echo "Extracting installer"
    eval "$install_bin_path --target /home/user/installer --noexec"

    # Get AuthToken by repeating the following command until it succeeds
    f_echo "Log into your Xilinx account to download the necessary files."
    while ! /home/user/installer/xsetup -b AuthTokenGen
    do
        f_echo "Your account information seems to be wrong. Please try logging in again."
        sleep 1
    done
elif [ "$installer_extension" = "tar" ] || [ "$installer_extension" = "gz" ] || [ "$installer_extension" = "tgz" ]; then

    # Get AuthToken by repeating the following command until it succeeds
    cd /home/user/installer || {
        f_echo "The installer was not extracted to /home/user/installer. Run cleanup.sh and try again."
        exit 1
    }
    if [ ! -x ./xsetup ]; then
        f_echo "xsetup was not found in /home/user/installer. Run cleanup.sh and try again."
        exit 1
    fi
    while ! ./xsetup -b AuthTokenGen
    do
        f_echo "Your account information seems to be wrong. Please try logging in again."
        sleep 1
    done
else
    f_echo "Unsupported installer file type: $install_bin_path"
    exit 1
fi

# Run installer
f_echo "You successfully logged into your account. The installation will begin now."
eula_args="XilinxEULA,3rdPartyEULA"

# Check if the version is 202110 to include WebTalk terms
if [ "$vivado_version" = "202110" ]; then
    eula_args="${eula_args},WebTalkTerms"
    f_echo "Note: The 2021.1 version enables WebTalk data collection and agrees automatically to the corresponding terms."
    f_echo "For more information, see: https://docs.amd.com/r/2021.1-English/ug973-vivado-release-notes-install-license/WebTalk-Participation"
    wait_for_user_input
fi

if /home/user/installer/xsetup -c "/home/user/scripts/install_configs/${vivado_version}.txt" -b Install -a "${eula_args}"
then
    f_echo "Vivado was successfully installed."
    # Remove the extracted installer — it is ~1 GB and no longer needed.
    # Vivado itself lives in /home/user/Xilinx (bind-mounted on the Mac) and
    # persists across container restarts — no re-download required.
    f_echo "Cleaning up extracted installer files..."
    rm -rf /home/user/installer
    f_echo "Run start_container.sh to launch Vivado."
else
    f_echo "An error occurred during installation. Please run cleanup.sh and try again."
    exit 1
fi