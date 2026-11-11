#!/bin/bash

# This runs the Vivado installer in batch mode.
#
# The batch install configuration (edition + device families) is generated here
# at install time: module family names differ between Vivado releases, and the
# installer itself is the authority for the available families. The user picks
# a preset in the terminal (or lets ConfigGen generate the selection).

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
if [ -z "$vivado_version" ]; then
    if ! set_vivado_version_from_hash "$file_hash"; then
        f_echo "Invalid installer hash. Add its MD5 to /home/user/scripts/hashes.sh"
        exit 1
    fi
fi

installer_extension="${install_bin_path##*.}"
installer_extension="${installer_extension,,}"

# AMD retires the web installers of older releases; they cannot download their
# payload anymore and are therefore not supported.
if [ "$installer_extension" = "bin" ] && [ -n "$vivado_version" ] \
&& [ -n "$web_installer_unsupported_before" ] \
&& [ "$vivado_version" -lt "$web_installer_unsupported_before" ] 2>/dev/null; then
    f_echo "The web installer for Vivado ${vivado_version} is obsolete and cannot download its files anymore."
    f_echo "Use the SFD (full) installer (.tar / .tar.gz) for this release instead."
    exit 1
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
f_echo "You successfully logged into your account."
eula_args="XilinxEULA,3rdPartyEULA"

# 2019.2 and 2021.1 enable WebTalk data collection, which needs an extra EULA flag
case "$vivado_version" in
201920|202110)
    eula_args="${eula_args},WebTalkTerms"
    f_echo "Note: Vivado ${vivado_version} enables WebTalk data collection and agrees automatically to the corresponding terms."
    f_echo "For more information, see: https://docs.amd.com/r/2021.1-English/ug973-vivado-release-notes-install-license/WebTalk-Participation"
    wait_for_user_input
    ;;
esac

# ---------------------------------------------------------------------------
# Install configuration
# ---------------------------------------------------------------------------

install_edition=""
install_catalog=""

# Per-version module catalog: "<family>:<default enabled 0/1>" entries.
# The names are the exact ConfigGen names for the release; defaults mirror the
# repository's previous install_config files.
function install_catalog_for_version {
    case "$1" in
	201920)
		install_edition="Vivado HL WebPACK"
		install_catalog="Virtex UltraScale+ HBM:1,Zynq UltraScale+ MPSoC:1,DocNav:1,Kintex UltraScale:1,Zynq-7000:1,System Generator for DSP:0,Artix-7:1,Virtex UltraScale+:1,Kintex UltraScale+:1,Kintex-7:1,Spartan-7:1,Model Composer:0"
		;;
	202110)
		install_edition="Vivado ML Standard"
		install_catalog="Virtex UltraScale+ HBM:1,Zynq UltraScale+ MPSoC:1,DocNav:1,Kintex UltraScale:1,Zynq-7000:1,Spartan-7:1,Artix-7:1,Virtex UltraScale+:1,Kintex-7:1,Kintex UltraScale+:1,Vitis Model Composer(Xilinx Toolbox for MATLAB and Simulink. Includes the functionality of System Generator for DSP):1"
		;;
	202120)
		install_edition="Vivado ML Standard"
		install_catalog="Zynq UltraScale+ MPSoC:1,Virtex UltraScale+ 58G:1,Virtex UltraScale+ 58G ES:0,Versal Prime Series ES1:0,Zynq-7000:1,Kintex UltraScale+:1,Artix UltraScale+:1,Spartan-7:1,Versal AI Edge Series:0,Versal Premium Series ES1:0,Artix-7:1,Versal AI Core Series ES1:0,Versal Prime Series:0,DocNav:1,Virtex UltraScale+ HBM:1,Kintex-7:1,Virtex UltraScale+:1,Versal AI Core Series:0,Vitis Model Composer(Xilinx Toolbox for MATLAB and Simulink. Includes the functionality of System Generator for DSP):1,Kintex UltraScale:1,Virtex UltraScale:1,Versal HBM Series ES1:0,Zynq UltraScale+ RFSoC:1,Virtex-7:1,Install Devices for Kria SOMs and Starter Kits:1,Virtex UltraScale+ HBM ES:0,Versal AI Edge Series ES1:0,Zynq UltraScale+ RFSoC ES:0,Engineering Sample Devices:0"
		;;
	202210)
		# 2022.1 uses the same module family names as the 2022.2 catalog.
		install_edition="Vivado ML Standard"
		install_catalog="Virtex UltraScale+ HBM:1,DocNav:1,Kintex UltraScale:1,Artix UltraScale+:1,Spartan-7:1,Artix-7:1,Virtex UltraScale+:1,Vitis Model Composer(Xilinx Toolbox for MATLAB and Simulink. Includes the functionality of System Generator for DSP):1,Zynq UltraScale+ MPSoC:1,Zynq-7000:1,Virtex UltraScale+ 58G:1,Kintex-7:1,Install Devices for Kria SOMs and Starter Kits:1,Kintex UltraScale+:1"
		;;
	202220)
		install_edition="Vivado ML Standard"
		install_catalog="Virtex UltraScale+ HBM:1,DocNav:1,Kintex UltraScale:1,Artix UltraScale+:1,Spartan-7:1,Artix-7:1,Virtex UltraScale+:1,Vitis Model Composer(Xilinx Toolbox for MATLAB and Simulink. Includes the functionality of System Generator for DSP):1,Zynq UltraScale+ MPSoC:1,Zynq-7000:1,Virtex UltraScale+ 58G:1,Kintex-7:1,Install Devices for Kria SOMs and Starter Kits:1,Kintex UltraScale+:1"
		;;
	202310)
		install_edition="Vivado ML Standard"
		install_catalog="Virtex UltraScale+ HBM:1,DocNav:1,Kintex UltraScale:1,Artix UltraScale+:1,Spartan-7:1,Artix-7:1,Virtex UltraScale+:1,Vitis Model Composer(Toolbox for MATLAB and Simulink. Includes the functionality of System Generator for DSP):1,Zynq UltraScale+ MPSoC:1,Zynq-7000:1,Virtex UltraScale+ 58G:1,Kintex-7:1,Install Devices for Kria SOMs and Starter Kits:1,Kintex UltraScale+:1"
		;;
	202320)
		install_edition="Vivado ML Standard"
		install_catalog="Virtex UltraScale+ HBM:1,Kintex UltraScale:1,Vitis Networking P4:0,Artix UltraScale+:1,Spartan-7:1,Artix-7:1,Virtex UltraScale+:1,Vitis Model Composer(Toolbox for MATLAB and Simulink. Includes the functionality of System Generator for DSP):1,DocNav:1,Zynq UltraScale+ MPSoC:1,Zynq-7000:1,Virtex UltraScale+ 58G:1,Vitis Embedded Development:0,Kintex-7:1,Install Devices for Kria SOMs and Starter Kits:1,Kintex UltraScale+:1"
		;;
	202410)
		install_edition="Vivado ML Standard"
		install_catalog="Virtex UltraScale+ HBM:1,Kintex UltraScale:1,Vitis Networking P4:0,Artix UltraScale+:1,Spartan-7:1,Artix-7:1,Virtex UltraScale+:1,Vitis Model Composer(Toolbox for MATLAB and Simulink. Includes the functionality of System Generator for DSP):1,DocNav:1,Zynq UltraScale+ MPSoC:1,Zynq-7000:1,Virtex UltraScale+ 58G:1,Power Design Manager (PDM):0,Vitis Embedded Development:0,Kintex-7:1,Install Devices for Kria SOMs and Starter Kits:1,Kintex UltraScale+:1"
		;;
	202420)
		install_edition="Vivado ML Standard"
		install_catalog="Virtex UltraScale+ HBM:1,Kintex UltraScale:1,Vitis Networking P4:0,Artix UltraScale+:1,Spartan-7:1,Artix-7:1,Virtex UltraScale+:1,Vitis Model Composer(Toolbox for MATLAB and Simulink. Includes the functionality of System Generator for DSP):1,DocNav:1,Zynq UltraScale+ MPSoC:1,Zynq-7000:1,Virtex UltraScale+ 58G:1,Power Design Manager (PDM):0,Vitis Embedded Development:0,Kintex-7:1,Install Devices for Kria SOMs and Starter Kits:1,Kintex UltraScale+:1"
		;;
	202510)
		install_edition="Vivado ML Standard"
		install_catalog="Kintex UltraScale FPGAs:1,Kintex UltraScale+ FPGAs:1,Kintex-7 FPGAs:1,Artix-7 FPGAs:1,Artix UltraScale+ FPGAs:1,Spartan-7 FPGAs:1,Spartan UltraScale+:1,Virtex UltraScale+ FPGAs:1,Virtex UltraScale+ HBM FPGAs:1,Virtex UltraScale+ 58G FPGAs:1,Zynq-7000 All Programmable SoC:1,Zynq UltraScale+ MPSoCs:1,Vitis Model Composer(A toolbox for Simulink):1,DocNav:1,Vitis Embedded Development:0,Vitis Networking P4:0,Power Design Manager (PDM):0,Install Devices for Kria SOMs and Starter Kits:1,Install devices for Alveo and edge acceleration platforms:0"
		;;
	202520)
		install_edition="Vivado ML Standard"
		install_catalog="Kintex UltraScale FPGAs:1,Kintex UltraScale+ FPGAs:1,Kintex-7 FPGAs:1,Artix-7 FPGAs:1,Artix UltraScale+ FPGAs:1,Spartan-7 FPGAs:1,Spartan UltraScale+:1,Virtex UltraScale+ FPGAs:1,Virtex UltraScale+ HBM FPGAs:1,Virtex UltraScale+ 58G FPGAs:1,Zynq-7000 All Programmable SoC:1,Zynq UltraScale+ MPSoCs:1,Vitis Model Composer(A toolbox for Simulink):1,DocNav:1,Vitis Embedded Development:0,Vitis Networking P4:0,Power Design Manager (PDM):0,Install Devices for Kria SOMs and Starter Kits:1,Install devices for Alveo and edge acceleration platforms:0"
		;;
	202610)
		install_edition="Vivado ML Standard"
		install_catalog="Kintex UltraScale FPGAs:1,Kintex UltraScale+ FPGAs:1,Kintex-7 FPGAs:1,Artix-7 FPGAs:1,Artix UltraScale+ FPGAs:1,Spartan-7 FPGAs:1,Spartan UltraScale+:1,Virtex UltraScale+ FPGAs:1,Virtex UltraScale+ HBM FPGAs:1,Virtex UltraScale+ 58G FPGAs:1,Zynq-7000 All Programmable SoC:1,Zynq UltraScale+ MPSoCs:1,Vitis Model Composer(A toolbox for Simulink):1,DocNav:1,Vitis Embedded Development:0,Vitis Networking P4:0,Power Design Manager (PDM):0,Install Devices for Kria SOMs and Starter Kits:1,Install devices for Alveo and edge acceleration platforms:0"
		;;
    *)
        return 1
        ;;
    esac
    return 0
}

# Builds a Modules= value from the catalog using one of the presets:
# defaults | all | 7series | ultrascale
function modules_with_preset {
    preset="$1"
    printf "%s\n" "$install_catalog" | tr ',' '\n' | {
        result=""
        while IFS= read -r entry
        do
            name="${entry%:*}"
            default_value="${entry##*:}"
            case "$preset" in
            all)
                value=1
                ;;
            7series)
                case "$name" in
                *"Artix-7"*|*"Kintex-7"*|*"Spartan-7"*|*"Zynq-7000"*|*DocNav*)
                    value=1
                    ;;
                *)
                    value=0
                    ;;
                esac
                ;;
            ultrascale)
                case "$name" in
                *UltraScale*|*Versal*|*Kria*|*DocNav*|*"Vitis Model Composer"*)
                    value=1
                    ;;
                *)
                    value=0
                    ;;
                esac
                ;;
            *)
                value="$default_value"
                ;;
            esac
            if [ -z "$result" ]; then
                result="$name:$value"
            else
                result="$result,$name:$value"
            fi
        done
        printf "%s" "$result"
    }
}

function write_install_config {
    target="$1"
    modules="$2"
    {
        echo "#### Generated by vivado-on-silicon-mac ####"
        echo "Edition=${install_edition}"
        echo "Product=Vivado"
        echo "Destination=/home/user/Xilinx"
        echo "Modules=${modules}"
        echo "InstallOptions="
        echo "CreateProgramGroupShortcuts=1"
        echo "ProgramGroupFolder=Xilinx Design Tools"
        echo "CreateShortcutsForAllUsers=0"
        echo "CreateDesktopShortcuts=1"
        echo "CreateFileAssociation=1"
    } > "$target"
}

# Runs the installer's interactive ConfigGen, points the generated file at the
# bind-mounted installation folder and sets CONFIG_FILE to it.
function generate_config_with_configgen {
    f_echo "Generating an install configuration with 'xsetup -b ConfigGen' (follow the prompts)..."
    if ! cd /home/user/installer; then
        f_echo "The installer was not extracted to /home/user/installer."
        return 1
    fi
    configgen_marker="/tmp/.configgen_started"
    touch "$configgen_marker"
    if ! ./xsetup -b ConfigGen; then
        f_echo "Could not generate an install configuration for ${vivado_version}."
        return 1
    fi
    generated_config=""
    for candidate in /home/user/.Xilinx/install_config.txt \
                     /home/user/install_config.txt \
                     /home/user/installer/install_config.txt
    do
        if [ -f "$candidate" ]; then
            generated_config="$candidate"
            break
        fi
    done
    if [ -z "$generated_config" ]; then
        generated_config=$(find /home/user -maxdepth 3 -type f -name 'install_config*.txt' -newer "$configgen_marker" 2>/dev/null | head -1)
    fi
    if [ -z "$generated_config" ]; then
        f_echo "Could not find the file ConfigGen created."
        f_echo "Enter the path to the generated configuration file:"
        read -r generated_config
    fi
    if [ -z "$generated_config" ] || [ ! -f "$generated_config" ]; then
        f_echo "No install configuration available for ${vivado_version}."
        return 1
    fi
    sed -i 's|^Destination=.*|Destination=/home/user/Xilinx|' "$generated_config"
    CONFIG_FILE="$generated_config"
    f_echo "Using generated configuration: $CONFIG_FILE"
    return 0
}

CONFIG_FILE="/tmp/install_config.txt"
if install_catalog_for_version "$vivado_version"; then
    f_echo "Select the device families to install for Vivado ${vivado_version}:"
    f_echo "  1) Default selection (recommended)"
    f_echo "  2) All available device families"
    f_echo "  3) 7-series only (Artix-7 / Kintex-7 / Spartan-7 / Zynq-7000)"
    f_echo "  4) UltraScale / UltraScale+ / Versal only"
    f_echo "  5) Let the installer generate the selection with ConfigGen"
    f_echo "Enter 1-5 [1]:"
    install_selection=""
    read -r install_selection || true
    case "$install_selection" in
    2)
        install_modules=$(modules_with_preset all)
        f_echo "Using all available device families."
        ;;
    3)
        install_modules=$(modules_with_preset 7series)
        f_echo "Using the 7-series selection."
        ;;
    4)
        install_modules=$(modules_with_preset ultrascale)
        f_echo "Using the UltraScale/UltraScale+/Versal selection."
        ;;
    5)
        if ! generate_config_with_configgen; then
            exit 1
        fi
        ;;
    *)
        install_modules=$(modules_with_preset defaults)
        f_echo "Using the default selection."
        ;;
    esac
    if [ -n "$install_modules" ]; then
        write_install_config "$CONFIG_FILE" "$install_modules"
        f_echo "Installation configuration: $CONFIG_FILE"
    fi
else
    f_echo "No built-in device catalog for Vivado ${vivado_version}."
    if ! generate_config_with_configgen; then
        exit 1
    fi
fi

f_echo "The installation will begin now."
if /home/user/installer/xsetup -c "$CONFIG_FILE" -b Install -a "${eula_args}"
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
