#!/bin/zsh

# Attempts to configure Docker by enabling Rosetta and increasing swap.
# Tested on Apple Silicon (M1/M2/M3/M4) running macOS 13–15.
#
# Supports both Docker Desktop settings file formats:
#   Legacy : settings.json      (keys: camelCase,  e.g. useVirtualizationFramework)
#   Current: settings-store.json (keys: PascalCase, e.g. UseVirtualizationFramework)

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

# Only Docker Desktop stores the settings this script changes. OrbStack and
# Colima enable Rosetta and size their VM through their own configuration.
runtime=$(detect_container_runtime)
if [ "$runtime" != "docker-desktop" ]
then
    f_echo "Detected container engine: $runtime"
    f_echo "Docker Desktop settings do not need to be changed for this engine."
    case "$runtime" in
        orbstack)
            f_echo "Enable Rosetta x86_64 emulation (recommended, enabled by default):"
            f_echo "  orb config set rosetta true"
            f_echo "Recommended memory limit for Vivado:"
            f_echo "  orb config set memory_mib 16384"
            ;;
        colima)
            f_echo "Make sure Colima was started with Rosetta x86_64 emulation:"
            f_echo "  colima start --vm-type=vz --vz-rosetta --cpu 8 --memory 16"
            ;;
    esac
    exit 0
fi

function cannot_setup_docker {
    f_echo "Unfortunately, the script could not configure Docker automatically."
    f_echo "Please change the settings in Docker Desktop manually:"
    f_echo "  Settings → General  → 'Use Virtualization Framework'  → ON"
    f_echo "  Settings → Features → 'Use Rosetta for x86/amd64 emulation' → ON"
    f_echo "  Settings → Resources → Swap → at least 8 GiB"
    f_echo "Restart Docker after applying the changes, then continue."
    wait_for_user_input
    exit 1
}

# Locate the settings file — Docker Desktop 4.x moved to settings-store.json
docker_settings_file=""
for candidate in \
    "$HOME/Library/Group Containers/group.com.docker/settings-store.json" \
    "$HOME/Library/Group Containers/group.com.docker/settings.json"
do
    if [ -f "$candidate" ]; then
        docker_settings_file="$candidate"
        break
    fi
done

if [ -z "$docker_settings_file" ]; then
    cannot_setup_docker
fi

stop_docker

# Prefer python3 when available (it ships with the Xcode Command Line Tools and
# gives the most robust JSON handling). macOS always provides plutil, so fall
# back to that if python3 is missing or cannot be run (e.g. a stub without the
# Command Line Tools installed).
settings_status=1

if command -v python3 > /dev/null 2>&1
then
    # Use Python to safely update the JSON settings regardless of key casing.
    # This handles both the legacy camelCase format and the newer PascalCase format.
    python3 - "$docker_settings_file" <<'PYEOF'
import os
import sys
import json

path = sys.argv[1]
with open(path, 'r') as f:
    data = json.load(f)

min_swap = 8192

# Build a normalised key map so we can match regardless of case
key_map = {k.lower(): k for k in data}

def set_key(logical_lower, pascal_key, value):
    """Set a value using whichever key variant already exists, or add PascalCase."""
    existing = key_map.get(logical_lower)
    if existing:
        data[existing] = value
    else:
        # Key doesn't exist yet — add it in PascalCase (current Docker format)
        data[pascal_key] = value

set_key('usevirtualizationframework',        'UseVirtualizationFramework',        True)
set_key('usevirtualizationframeworkrosetta', 'UseVirtualizationFrameworkRosetta', True)

# Only increase swap, never decrease
swap_key = key_map.get('swapmib', 'SwapMiB')
current_swap = data.get(swap_key, 0)
if not isinstance(current_swap, int) or current_swap < min_swap:
    data[swap_key] = min_swap

# Write atomically so an interrupted run cannot leave Docker's settings file broken
tmp_path = path + '.tmp'
with open(tmp_path, 'w') as f:
    json.dump(data, f, indent=4)
os.replace(tmp_path, path)

print(f"  UseVirtualizationFramework        = {data.get(key_map.get('usevirtualizationframework', 'UseVirtualizationFramework'))}")
print(f"  UseVirtualizationFrameworkRosetta = {data.get(key_map.get('usevirtualizationframeworkrosetta', 'UseVirtualizationFrameworkRosetta'))}")
print(f"  SwapMiB                           = {data.get(swap_key)}")
PYEOF
    settings_status=$?
else
    f_echo "python3 was not found."
fi

if [ "$settings_status" -ne 0 ]; then
    f_echo "Updating the Docker settings with macOS' built-in plutil instead."
    settings_status=0

    for logical_key in usevirtualizationframework usevirtualizationframeworkrosetta
    do
        pascal_key="UseVirtualizationFramework"
        [ "$logical_key" = "usevirtualizationframeworkrosetta" ] && pascal_key="UseVirtualizationFrameworkRosetta"
        existing_key=$(grep -o -i "\"$logical_key\"" "$docker_settings_file" | head -1 | tr -d '"')
        if [ -n "$existing_key" ]
        then
            plutil -replace "$existing_key" -bool true "$docker_settings_file" || settings_status=1
        else
            plutil -insert "$pascal_key" -bool true "$docker_settings_file" || settings_status=1
        fi
    done

    swap_key=$(grep -o -i '"swapmib"' "$docker_settings_file" | head -1 | tr -d '"')
    if [ -n "$swap_key" ]
    then
        current_swap=$(plutil -extract "$swap_key" raw "$docker_settings_file" 2>/dev/null)
        if [[ "$current_swap" != <-> ]] || [ "$current_swap" -lt 8192 ]
        then
            plutil -replace "$swap_key" -integer 8192 "$docker_settings_file" || settings_status=1
        fi
    else
        plutil -insert SwapMiB -integer 8192 "$docker_settings_file" || settings_status=1
    fi
fi

if [ "$settings_status" -ne 0 ]; then
    f_echo "Failed to update Docker settings automatically."
    cannot_setup_docker
fi

f_echo "Configured Docker successfully (file: $docker_settings_file)"
