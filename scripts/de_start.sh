#!/bin/bash

# This script is run whenever the desktop environment has started.
# (with normal user privileges).

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_linux

# Resolve the libgdk path at runtime — it moved from /lib to /usr/lib in
# Ubuntu 24.04 (libgtk2.0-0t64 package from the 64-bit time_t transition).
GDK_LIB=$(find /lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu \
               -name "libgdk-x11-2.0.so.0" 2>/dev/null | head -1)

export LD_PRELOAD="/lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libselinux.so.1 /lib/x86_64-linux-gnu/libz.so.1${GDK_LIB:+ $GDK_LIB}"

# Returns the candidate with the highest version number from a list of paths
# (e.g. 2026.1.1 ranks above 2026.1; both Vivado and Vivado_Lab are supported).
function newest_vivado_candidate {
	while IFS= read -r candidate_path
	do
		[ -z "$candidate_path" ] && continue
		candidate_version=$(printf "%s\n" "$candidate_path" | grep -Eo '20[0-9][0-9]\.[0-9]+(\.[0-9]+)?' | head -1)
		printf "%s\t%s\n" "${candidate_version:-0.0}" "$candidate_path"
	done | sort -V -k1,1 | tail -1 | cut -f2-
}

# if Vivado is installed
if [ -d "/home/user/Xilinx" ]
then
	# Vivado changed its installation layout in 2025.1:
	#   <= 2024.x: /home/user/Xilinx/Vivado/<version>/{bin,settings64.sh}
	#   >= 2025.1: /home/user/Xilinx/<version>/Vivado/{bin,settings64.sh}
	# Version strings can have four parts (2026.1.1) and a Lab Edition install
	# uses Vivado_Lab. Collect all candidates, pick the highest version and fall
	# back to searching the installation tree.
	hw_server_bin=$(
		{
			for pattern in "/home/user/Xilinx/*/Vivado/bin/hw_server" \
			               "/home/user/Xilinx/*/Vivado_Lab/bin/hw_server" \
			               "/home/user/Xilinx/Vivado/*/bin/hw_server" \
			               "/home/user/Xilinx/Vivado_Lab/*/bin/hw_server"
			do
				for candidate in $pattern
				do
					[ -x "$candidate" ] && printf "%s\n" "$candidate"
				done
			done
			find /home/user/Xilinx -maxdepth 6 -type f -name hw_server 2>/dev/null
		} | newest_vivado_candidate
	)

	if [ -n "$hw_server_bin" ]
	then
		# Make Vivado connect to the xvcd server running on macOS.
		# Docker Desktop provides host.docker.internal; the Apple container
		# backend passes host.container.internal through VIVADO_HOST_ALIAS.
		xvcd_host="${VIVADO_HOST_ALIAS:-host.docker.internal}"
		"$hw_server_bin" -e "set auto-open-servers     xilinx-xvc:${xvcd_host}:2542" &
	fi

	settings_file=$(
		{
			for pattern in "/home/user/Xilinx/*/Vivado/settings64.sh" \
			               "/home/user/Xilinx/*/Vivado_Lab/settings64.sh" \
			               "/home/user/Xilinx/Vivado/*/settings64.sh" \
			               "/home/user/Xilinx/Vivado_Lab/*/settings64.sh"
			do
				for candidate in $pattern
				do
					[ -f "$candidate" ] && printf "%s\n" "$candidate"
				done
			done
			find /home/user/Xilinx -maxdepth 6 -type f -name settings64.sh 2>/dev/null
		} | newest_vivado_candidate
	)

	if [ -n "$settings_file" ]
	then
		source "$settings_file"
		if command -v vivado > /dev/null 2>&1
		then
			vivado
		else
			vivado_bin=$(
				find /home/user/Xilinx -maxdepth 6 -type f \( -name vivado -o -name vivado_lab \) 2>/dev/null | newest_vivado_candidate
			)
			if [ -n "$vivado_bin" ]
			then
				"$vivado_bin"
			else
				f_echo "Could not find the Vivado executable under /home/user/Xilinx."
				wait_for_user_input
			fi
		fi
	else
		f_echo "Could not find a Vivado installation under /home/user/Xilinx."
		wait_for_user_input
	fi
else
	f_echo "The installation is incomplete."
	wait_for_user_input
fi
