# general functions and definitions used by the other scripts

# This script needs to be sourced into other scripts or
# be run explicitly with an interpreter since it has no shebang

script_dir=$(dirname -- "$(readlink -nf $0)";)

# echo with color
function f_echo {
	echo -e "\e[1m\e[33m$1\e[0m"
}

source "$script_dir/hashes.sh"

# Optional, untracked additions for newly released installers. The file
# scripts/hashes.local contains one entry per line:
#   <32-char-hex-md5> <version-code> [web|sfd]
# (web is the default). This keeps the tracked hash list clean while still
# allowing immediate installs of a new release.
if [ -f "$script_dir/hashes.local" ]
then
    while read -r local_hash local_version local_kind local_rest || [ -n "$local_hash" ]
    do
        # Tolerate CRLF line endings
        local_hash=${local_hash%$'\r'}
        local_version=${local_version%$'\r'}
        local_kind=${local_kind%$'\r'}
        # Hashes are compared in lowercase.
        local_hash=$(printf "%s" "$local_hash" | tr 'A-F' 'a-f')
        case "$local_hash" in
            ""|\#*)
                continue
                ;;
        esac
        if ! printf "%s" "$local_hash" | grep -Eq '^[0-9a-fA-F]{32}$' \
        || ! printf "%s" "$local_version" | grep -Eq '^20[0-9][0-9][12]0$'
        then
            f_echo "Ignoring malformed line in scripts/hashes.local (expected: <md5> <version-code> [web|sfd])"
            continue
        fi
        # Allow a trailing comment after the optional type
        case "$local_kind" in
            \#*)
                local_kind=""
                ;;
        esac
        if [ "$local_kind" = "sfd" ]
        then
            sfd_hashes[$local_hash]=$local_version
        else
            web_hashes[$local_hash]=$local_version
        fi
    done < "$script_dir/hashes.local"
fi

# aborts the script if it isn't run on macOS
function validate_macos {
    if [[ $(uname) == *Darwin* ]]
    then
        :
    else
        f_echo "Make sure to run this script on macOS."
        exit 1
    fi
}

# aborts the script if it isn't run inside the Docker container
function validate_linux {
    if [[ $(uname) == *Linux* ]]
    then
        :
    else
        f_echo "Make sure to run this script on Linux."
        exit 1
    fi
}

function validate_internet {
    if ! ping -q -c1 google.com &>/dev/null
    then
        f_echo "Internet connection required."
        exit 1
    fi
}

function wait_for_user_input {
    f_echo "Press Enter to continue..."
    read
}

# ---------------------------------------------------------------------------
# Container engine management
#
# The scripts work with any Docker-compatible engine on macOS:
#   - Docker Desktop (default)
#   - OrbStack       (https://orbstack.dev)
#   - Colima         (https://github.com/abiosoft/colima)
# All of them provide the `docker` CLI, so everything below this file works
# unchanged. Only Docker Desktop needs its settings adjusted (configure_docker.sh).
#
# This branch (ctn) additionally supports Apple's `container` CLI as an
# experimental backend. Docker-compatible engines are preferred automatically;
# set VIVADO_ENGINE=apple (or VIVADO_ENGINE=docker) to force an engine.
# ---------------------------------------------------------------------------

# Prints the engine the docker CLI currently uses:
# docker-desktop | orbstack | colima | docker-other | none
function detect_container_runtime {
    if [ "${VIVADO_ENGINE:-}" = "apple" ]
    then
        echo "apple-container"
        return 0
    fi
    if command -v docker &> /dev/null
    then
        context=$(docker context show 2>/dev/null)
        case "$context" in
            orbstack)
                echo "orbstack"
                return 0
                ;;
            colima*)
                echo "colima"
                return 0
                ;;
        esac
        if [ -n "$DOCKER_HOST" ]
        then
            echo "docker-other"
            return 0
        fi
        if [ -d "/Applications/Docker.app" ] || [ "$context" = "desktop-linux" ]
        then
            echo "docker-desktop"
            return 0
        fi
    fi
    if [ -d "/Applications/OrbStack.app" ]
    then
        echo "orbstack"
        return 0
    fi
    if command -v colima &> /dev/null
    then
        echo "colima"
        return 0
    fi
    if [ "${VIVADO_ENGINE:-}" != "docker" ] && command -v container &> /dev/null
    then
        echo "apple-container"
        return 0
    fi
    echo "none"
}

# Prints the engine family: docker | apple | none
function engine_kind {
    case "$(detect_container_runtime)" in
        apple-container)
            echo "apple"
            ;;
        none)
            echo "none"
            ;;
        *)
            echo "docker"
            ;;
    esac
}

# Starts the Apple container services (experimental backend).
function start_apple_container {
    if ! command -v container &> /dev/null
    then
        f_echo "The Apple 'container' CLI is not installed."
        f_echo "Download it from https://github.com/apple/container/releases"
        f_echo "(requires macOS 26+ on Apple silicon) and run 'container system start'."
        exit 1
    fi
    if container system status &> /dev/null
    then
        return 0
    fi
    f_echo "Starting Apple container services..."
    container system start || exit 1
    attempts=0
    while ! container system status &> /dev/null
    do
        sleep 2
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 60 ]
        then
            f_echo "Apple container services did not start in time."
            exit 1
        fi
    done
    sleep 2
}

function start_docker {
    if [ "$(engine_kind)" = "apple" ]
    then
        start_apple_container
        return 0
    fi

    # A Docker-compatible engine provides the `docker` CLI.
    if ! command -v docker &> /dev/null
    then
        f_echo "No container engine was found. Install one of:"
        f_echo "- Docker Desktop (default): https://www.docker.com/products/docker-desktop/"
        f_echo "- OrbStack: https://orbstack.dev/"
        f_echo "- Colima: brew install colima docker"
        exit 1
    fi

    # Nothing to do when the engine is already running.
    if docker ps &> /dev/null
    then
        return 0
    fi

    runtime=$(detect_container_runtime)
    f_echo "Container engine: $runtime"
    case "$runtime" in
        orbstack)
            f_echo "Starting OrbStack..."
            open -a OrbStack &> /dev/null
            ;;
        colima)
            f_echo "Starting Colima with Rosetta x86_64 emulation..."
            f_echo "(resources can be overridden with VIVADO_CPUS / VIVADO_MEMORY)"
            colima start --vm-type=vz --vz-rosetta \
                --cpu "${VIVADO_CPUS:-8}" --memory "${VIVADO_MEMORY:-16}" || exit 1
            ;;
        docker-desktop)
            f_echo "Launching Docker daemon..."
            open -a Docker &> /dev/null
            ;;
        docker-other)
            f_echo "Waiting for the container engine configured via DOCKER_HOST..."
            ;;
        *)
            f_echo "Could not detect a container engine. Install Docker Desktop, OrbStack or Colima."
            exit 1
            ;;
    esac

    # Wait for the engine to accept connections (max. ~3 minutes).
    sleep 2
    attempts=0
    while ! docker ps &> /dev/null
    do
        sleep 5
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 36 ]
        then
            f_echo "The container engine did not start in time."
            exit 1
        fi
    done
    sleep 2
}

# Prints engine-specific hints for the memory/CPU settings Vivado needs.
function print_runtime_resource_hint {
    runtime=$(detect_container_runtime)
    case "$runtime" in
        orbstack)
            f_echo "OrbStack memory limit (default 8 GiB; 16 GiB recommended for Vivado):"
            f_echo "  orb config set memory_mib 16384"
            ;;
        colima)
            f_echo "Colima VM resources are fixed when it is started (8 CPUs / 16 GiB recommended):"
            f_echo "  colima stop && colima start --vm-type=vz --vz-rosetta --cpu 8 --memory 16"
            ;;
        apple-container)
            f_echo "Apple container resources are set per container (the scripts use 8 CPUs / 16 GiB)."
            f_echo "Override them with VIVADO_CPUS / VIVADO_MEMORY."
            ;;
        docker-desktop)
            f_echo "Adjust CPU/RAM/swap in Docker Desktop -> Settings -> Resources."
            ;;
    esac
}

# Returns true when the named container is running.
function engine_is_running {
    if [ "$(engine_kind)" = "apple" ]
    then
        container inspect "$1" 2>/dev/null | grep -Eq '"status"[[:space:]]*:[[:space:]]*"running"'
    else
        docker ps --filter "name=^$1$" --format '{{.Names}}' 2>/dev/null | grep -qx "$1"
    fi
}

# Kills the named container (if it exists).
function engine_kill {
    if [ "$(engine_kind)" = "apple" ]
    then
        container kill "$1" &> /dev/null
    else
        docker kill "$1" &> /dev/null
    fi
}

# Apple container needs a DNS entry to reach services running on the Mac
# (Docker Desktop provides host.docker.internal automatically).
function engine_ensure_host_alias {
    if [ "$(engine_kind)" = "apple" ]
    then
        if ! container system dns list --quiet 2>/dev/null | grep -qx "host.container.internal"
        then
            f_echo "Creating host.container.internal for host access (requires sudo)..."
            if ! sudo container system dns create host.container.internal --localhost 203.0.113.113
            then
                f_echo "Warning: host.container.internal was not created."
                f_echo "USB/JTAG forwarding via xvcd will not work until it exists."
            fi
        fi
    fi
}

function stop_docker {
    curl -s -X POST -H 'Content-Type: application/json' -d '{ "openContainerView": true }' -kiv --unix-socket "$HOME/Library/Containers/com.docker.docker/Data/backend.sock" http://localhost/engine/stop &> /dev/null
    osascript -e 'quit app "Docker Desktop"'
    sleep 2
}

vivado_version=""

# Sets vivado_version from an installer MD5. Returns 0 when the hash is known,
# 1 otherwise (the caller decides what to do; this used to exit immediately).
function set_vivado_version_from_hash {
    if [[ -v web_hashes[$1] ]]
    then
        vivado_version=${web_hashes[$1]}
    elif [[ -v sfd_hashes[$1] ]]
    then
        vivado_version=${sfd_hashes[$1]}
    else
        vivado_version=""
        return 1
    fi
    return 0
}

# Tries to derive the version code (e.g. 202610) from an installer file name.
# AMD installers contain a marker such as 2026.1 or 2024.2 in their name.
# Prints the version code on success and returns 0, prints nothing and returns
# 1 when the name does not contain a recognizable version.
function version_from_installer_filename {
    installer_name=$(basename "$1")
    version_match=$(printf "%s\n" "$installer_name" | grep -Eo '20[0-9][0-9]\.[12]' | head -1)
    if [ -z "$version_match" ]
    then
        return 1
    fi
    version_year=${version_match%%.*}
    version_sub=${version_match##*.}
    echo "${version_year}${version_sub}0"
}

# The actual resolution is stored in the file vnc_resolution
vnc_default_resolution="1920x1080"

current_user=$(whoami)
