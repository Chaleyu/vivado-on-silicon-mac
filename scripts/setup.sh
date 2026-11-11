#!/bin/zsh

# Initial setup on host (macOS) side

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
# Make sure that the script is run in macOS and not the Docker container
validate_macos

# Warn if running on macOS 14 — most 14.x releases have Rosetta emulation
# bugs that can cause the installation or Vivado to crash. macOS 15 and later
# are recommended for M3/M4 and newer chips.
macos_major=$(sw_vers -productVersion | cut -d. -f1)
if [[ "$macos_major" -eq 14 ]]; then
    f_echo "WARNING: macOS 14 has known Rosetta emulation issues that may cause"
    f_echo "installation failures or Vivado crashes. macOS 15 or later is recommended."
    f_echo "Continue anyway [Y/n]?"
    read macos_consent
    case $macos_consent in
    [nN]|[nN][oO]*)
        f_echo "Aborting setup."
        exit 1
        ;;
    esac
fi

# Make sure permissions are right
if [[ "$current_user" == "root" ]]
then
	f_echo "Do not execute this script as root."
	exit 1
fi

# Make sure there are no previous installations in this folder
if [ -d "$script_dir/../Xilinx" ]
then
	f_echo "A previous installation was found. To reinstall, remove the Xilinx folder."
	exit 1
fi

validate_internet

f_echo "Advancing with the setup requires the following:"
f_echo "- Agreeing to Xilinx'/AMD's EULAs (which can be obtained by extracting the installation binary)"
f_echo "- Enabling WebTalk data collection for version 2021.1 and agreeing to corresponding terms"
f_echo "- Installation of Rosetta 2 and agreeing to Apple's corresponding software license agreement"
f_echo "Proceed [Y/n]?"
read user_consent
case $user_consent in
[yY]|[yY][eE]*)
	f_echo "Continuing setup..."
	;;
[nN]|[nN][oO]*)
	f_echo "Aborting setup."
	exit 1
	;;
*)
	f_echo "Invalid option."
	exit 1
	;;
esac

# Check if the Mac is Intel or Apple Silicon
if [[ "$(sysctl sysctl.proc_translated)" == "sysctl.proc_translated: 1" ]]; then
	f_echo "Terminal is in emulated mode. Convert terminal to native mode and restart."
	exit 1
else
	if [[ "$(uname -m)" == "x86_64" ]]; then
		f_echo "Mac is Intel-based. Rosetta installation is not required."
	else
		if arch -arch x86_64 uname -m > /dev/null 2>&1; then
			f_echo "Rosetta is already installed."
		else
			f_echo "Rosetta is not installed."
			f_echo "Proceeding with Rosetta installation..."
			if ! softwareupdate --install-rosetta --agree-to-license; then
				f_echo "Error installing Rosetta."
				exit 1
			fi
		fi
	fi
fi

# Get Vivado installation file
f_echo "You need to put the Vivado installation file into this folder if you have not done so already."
installation_binary=""
while true
do
	installation_binary=""
	# Get the absolute path to the file
	f_echo "Then, drag and drop the Vivado installation binary into this terminal window and press Enter: "
	read installation_binary
	
	# check if it is accessible from the container
	parent_dir=$(dirname "$script_dir")
	if ! [[ $installation_binary == $parent_dir/* ]]
	then
		f_echo "You need to move the installation binary into the folder!"
		continue
	fi

	# A previously computed hash is cached in the repository root to avoid hashing
	# a large installer again. The cache is only reused for the exact same installer
	# path, so a different installer can never be detected as the cached version.
	hash_cache_path="$script_dir/../hash"
	hash_source_path="$script_dir/../hash_source"
	if [ -f "$hash_cache_path" ] && [ -f "$hash_source_path" ] \
	&& [ "$(tr -d "\n\r" < "$hash_source_path")" = "$installation_binary" ]
	then
		f_echo "Reusing the stored hash for this installer."
		file_hash=$(tr -d "\n\r\t " < "$hash_cache_path")
	else
		f_echo "Generating hash, this may take a while..."
		file_hash=$(md5 -q "$installation_binary")
	fi

	# Check whether the hash is known. If it is not (a newer or re-packed
	# installer), fall back to the version encoded in the file name, but only
	# when an install config for that version exists and the user confirms.
	detected_version=""
	if set_vivado_version_from_hash "$file_hash"
	then
		f_echo "Valid file provided. Detected version $vivado_version"
	elif detected_version=$(version_from_installer_filename "$installation_binary") \
	&& [ -n "$detected_version" ] \
	&& [ -f "$script_dir/install_configs/$detected_version.txt" ]
	then
		f_echo "The installer hash is not in the supported list."
		f_echo "The file name suggests Vivado $detected_version (newer release or re-packed installer)."
		f_echo "Continue with Vivado $detected_version? [y/N]"
		read unknown_hash_consent
		case $unknown_hash_consent in
		[yY]*)
			vivado_version="$detected_version"
			;;
		*)
			f_echo "File corrupted or version not supported."
			continue
			;;
		esac
	else
		f_echo "File corrupted or version not supported."
		f_echo "For a new Vivado release, add its installer MD5 to scripts/hashes.sh"
		f_echo "(or an untracked scripts/hashes.local) and add scripts/install_configs/<version>.txt."
		continue
	fi

	f_echo "Using Vivado version $vivado_version"

	# AMD retires the online files used by older web installers, so their
	# installation can fail while downloading. SFD (full) installers carry all
	# files and do not have this problem.
	case "${installation_binary:l}" in
	*.bin)
		if [ -n "$web_installer_warn_before" ] && [ "$vivado_version" -lt "$web_installer_warn_before" ] 2>/dev/null
		then
			f_echo "Note: AMD marks older web installers as obsolete and may not provide"
			f_echo "their online files anymore, so this installation can fail while downloading."
			f_echo "If that happens, use the SFD (full) installer for Vivado $vivado_version instead."
		fi
		;;
	esac

	# Save hash and version to speed up future runs and for the container.
	echo -n "$file_hash" > "$hash_cache_path"
	printf "%s" "$installation_binary" > "$hash_source_path"
	echo -n "$vivado_version" > "$script_dir/../installer_version"
	break
done

# Extract the SFD installer on macOS for speed. AMD ships it either as a
# plain .tar archive (e.g. 2024.2) or as a gzip-compressed .tar.gz (older versions).
case "${installation_binary:l}" in
*.tar|*.tar.gz|*.tgz|*.gz)
	f_echo "Extracting the SFD installer, this may take a while..."
	rm -rf "$script_dir/../installer"
	mkdir -p "$script_dir/../installer"
	if ! tar -xf "$installation_binary" -C "$script_dir/../installer" --strip-components 1
	then
		f_echo "Extracting the installer failed. Make sure there is enough free disk space."
		exit 1
	fi
	;;
esac

# write file path to "install_bin"
install_bin_path="${installation_binary#$parent_dir}"
install_bin_path="/home/user$install_bin_path"
echo -n "$install_bin_path" > "$script_dir/install_bin"

# Make the user own the whole folder
if ! chown -R $current_user "$script_dir/.."
then
	f_echo "Higher privileges are required to make the folder owned by the user."
	if ! sudo chown -R $current_user "$script_dir/.."
	then
		f_echo "Error setting $current_user as owner of this folder."
		exit 1
	fi
fi

# Make the scripts executable
if xattr -p com.apple.quarantine "$script_dir/xvcd/bin/xvcd" &>/dev/null
then
	if ! xattr -d com.apple.quarantine "$script_dir/xvcd/bin/xvcd"
	then
		f_echo "You need to remove the quarantine attribute from $script_dir/xvcd/bin/xvcd manually."
		wait_for_user_input
	fi
fi

if ! chmod +x "$script_dir"/*.sh "$script_dir/xvcd/bin/xvcd" "$installation_binary"
then
	f_echo "Error making the scripts executable."
	exit 1
fi

# make sure that a Docker-compatible container engine is installed and running
# (Docker Desktop, OrbStack or Colima)
start_docker

# Docker Desktop needs Rosetta/Virtualization Framework/swap configured;
# OrbStack and Colima handle this themselves (configure_docker.sh prints hints).
eval "$script_dir/configure_docker.sh"
print_runtime_resource_hint

# Generate the Docker image (the detected version selects the legacy image for
# old Vivado releases)
export VIVADO_VERSION="$vivado_version"
if ! eval "$script_dir/gen_image.sh"
then
	exit 1
fi

# Set VNC resolution
f_echo "Set the resolution of the container. Keep in mind that high resolutions might make text and images appear small."
f_echo "You can change the resolution manually in the vnc_resolution file later."
f_echo "Press enter to leave the default (1920x1080) or type in your preference:"
read resolution
# if resolution has the right format
if [[ $resolution =~ "^[0-9]+x[0-9]+$" ]]
then
	f_echo "Setting $resolution as resolution"
	echo "$resolution" > "$script_dir/vnc_resolution"
else
	f_echo "Setting the default of $vnc_default_resolution"
	echo "$vnc_default_resolution" > "$script_dir/vnc_resolution"
fi
echo ""

# copy de_start.desktop autostart file
mkdir -p "$script_dir/../.config/autostart"
cp "$script_dir/de_start.desktop" "$script_dir/../.config/autostart/de_start.desktop"
mkdir "$script_dir/../Desktop"

# Start container
f_echo "Now, the container is started (only terminal, no GUI) and the actual installation process begins."
docker run --init -it --rm --name vivado_container --mount type=bind,source="$script_dir/..",target="/home/user" -p 127.0.0.1:5901:5901 --platform linux/amd64 x64-linux sudo -H -u user bash /home/user/scripts/install_vivado.sh
