#!/bin/zsh

# starts the Docker container and xvcd for USB forwarding

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

# XVC server used for JTAG forwarding. The vendored xvcd is the default; set
# VIVADO_XVC_BIN (and optionally VIVADO_XVC_ARGS) to try an active alternative
# such as xvc-usb or jtag-remote-server (see scripts/xvcd/README.md).
xvc_bin="${VIVADO_XVC_BIN:-$script_dir/xvcd/bin/xvcd}"
xvc_args="${VIVADO_XVC_ARGS:-}"
xvc_pid=""

# this is called when the container stops or ctrl+c is hit
function stop_container {
    docker kill vivado_container > /dev/null 2>&1
    f_echo "Stopped Docker container"
    if [ -n "$xvc_pid" ] && kill -0 "$xvc_pid" 2>/dev/null
    then
        kill "$xvc_pid" > /dev/null 2>&1
        f_echo "Stopped XVC server"
    fi
    killall xvcd > /dev/null 2>&1
    exit 0
}
trap 'stop_container' INT

# Make sure everything is setup to run the container
start_docker
if [[ $(docker ps) == *vivado_container* ]]
then
    f_echo "There is already an instance of the container running."
    exit 1
fi
killall xvcd > /dev/null 2>&1

# run container
docker run --init --rm --name vivado_container --mount type=bind,source="$script_dir/..",target="/home/user" -p 127.0.0.1:5901:5901 --platform linux/amd64 x64-linux sudo -H -u user bash /home/user/scripts/linux_start.sh &
f_echo "Started container"
sleep 7
f_echo "Starting VNC viewer"
vncpass=$( tr -d "\n\r\t " < "$script_dir/vncpasswd" )
osascript -e "tell application \"Screen Sharing\" to GetURL \"vnc://user:$vncpass@localhost:5901\""
f_echo "Running XVC server: $xvc_bin"
# while vivado_container is running
while [[ $(docker ps) == *vivado_container* ]]
do
    # restart the XVC server if it exited
    if [ -n "$xvc_pid" ] && kill -0 "$xvc_pid" 2>/dev/null
    then
        :
    else
        if [ -n "$xvc_args" ]
        then
            eval "\"$xvc_bin\" $xvc_args > /dev/null 2>&1 &"
        else
            "$xvc_bin" > /dev/null 2>&1 &
        fi
        xvc_pid=$!
        sleep 2
    fi
done
stop_container