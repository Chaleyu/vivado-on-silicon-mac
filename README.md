# vivado-on-silicon-mac
This is a tool for installing [Vivado™](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html) on Arm®-based Apple Silicon Macs in a Rosetta-enabled virtual machine. It is in no way associated with Xilinx or AMD.

**English | [简体中文](README_zh_cn.md)**

*Updated for 2026.1!*

## Supported versions

| Vivado | Web installer | SFD installer | Ubuntu image | Real-machine test status |
|---|---|---|---|---|
| 2019.2 | ❌ retired | ✅ available | 18.04 | ⚠️ not tested |
| 2021.1 | ❌ retired | ✅ available | 20.04 | 🔶 upstream support only |
| 2021.2 | ❌ retired | ✅ available | 20.04 | ⚠️ not tested |
| 2022.1 | ❌ retired | ✅ available | 20.04 | ⚠️ not tested |
| 2022.2 | ❌ retired | ✅ available | 22.04 | 🔶 upstream README only |
| 2023.1 | ❌ retired | ✅ available | 22.04 | 🔶 upstream README only |
| 2023.2 | ❌ retired | ✅ available | 22.04 | 🔶 upstream README only |
| 2024.1 | ✅ available | ✅ available | 22.04 | 🔶 upstream README only |
| 2024.2 (2024.2.2) | ✅ available | ✅ available | 24.04 | 🔶 PR #68 author tested (old image) |
| 2025.1 (2025.1.1) | ✅ available | ✅ available | 24.04 | 🔶 third-party fork usage |
| 2025.2 (2025.2.1) | ✅ available | ✅ available | 24.04 | 🔶 PR #83 author claims tested (old image) |
| 2026.1 (2026.1.1) | ✅ available | ✅ available | 24.04 | ⚠️ not tested |

Legend: ❌ "retired" = AMD's web installer for that release is obsolete and rejected by the scripts (use the SFD `.tar`/`.tar.gz`). 🔶 = historical or third-party report, **not** verified with the current images / install-time configuration; ⚠️ = no test data.

Every release uses the **newest Ubuntu version that AMD officially supports** for it: 2019.2 → 18.04 (16.04 is older and not used), 2021.1/2021.2/2022.1 → 20.04, 2022.2–2024.1 → 22.04, 2024.2+ → 24.04. Override for experiments with `VIVADO_BASE_IMAGE=ubuntu:<version>`. **No version has been end-to-end verified on real hardware with the current code in this fork yet** — please report results.

## Compatibility
- **Apple Silicon**: M1, M2, M3, M4 and later chips are supported.
- **macOS**: macOS 15 (Sequoia) or later is recommended. Most versions of macOS 14 (Sonoma) are **not supported** due to Rosetta emulation bugs — the installer will warn you if you are on macOS 14.
- **Container engine**: Docker Desktop (default), [OrbStack](https://orbstack.dev/) or [Colima](https://github.com/abiosoft/colima). All three provide the `docker` command line, and the scripts detect and start the engine automatically.
- The Docker container image is kept well under **8 GiB** (Vivado itself is installed to a bind-mounted folder, not inside the image). The base image is selected automatically: Ubuntu 18.04 for 2019.2, Ubuntu 20.04 for 2021.1–2022.1, Ubuntu 22.04 for 2022.2–2024.1, Ubuntu 24.04 for 2024.2+.

## How to install
Expect the installation process to last about one to two hours and download ~20 GB for the web installer.
About 30 minutes for the local installer (SFD).

### Preparations
You first need a Docker-compatible container engine:

- **Docker Desktop** (default): install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and make sure to choose "Apple Chip" instead of "Intel Chip". You may find it useful to disable the option "Open Docker Dashboard when Docker Desktop starts".
- **OrbStack**: install [OrbStack](https://orbstack.dev/). Rosetta emulation is enabled by default; the recommended memory limit for Vivado is set with `orb config set memory_mib 16384`.
- **Colima**: `brew install colima docker`, then start it with `colima start --vm-type=vz --vz-rosetta --cpu 8 --memory 16`. The `--vz-rosetta` flag is required for the x86_64 emulation that Vivado needs.

Rosetta must be installed on your Mac. The installer will ask you to install it if it is not already installed.

You will also need the Vivado installer file: either the "Linux® Self Extracting Web Installer" (`.bin`) or the full "SFD" installer (`.tar` / `.tar.gz`).

> AMD retires the web installers of older releases: the small `.bin` installer downloads its payload at install time and stops working after a few years. Web installers are only supported for **2024.1 and newer**; for 2019.2, 2021.1, 2021.2, 2022.1, 2022.2, 2023.1 and 2023.2 use the SFD (full) installer (`.tar` / `.tar.gz`). `setup.sh` refuses obsolete web installers with a clear message.

### Installation
1. Download this [tool](https://github.com/ichi4096/vivado-on-silicon-mac/archive/refs/heads/main.zip).
2. Extract the ZIP file.
3. Copy the Vivado installer into the extracted folder.
4. Open a terminal. Then copy & paste:
```
cd Downloads/vivado-on-silicon-mac-main
caffeinate -dim zsh ./scripts/setup.sh
```
5. Follow the instructions (in yellow) from the terminal.

`setup.sh` starts the detected container engine and, for Docker Desktop, enables the Virtualization Framework, Rosetta emulation and a sufficient swap size automatically. For OrbStack and Colima it prints the recommended settings instead.

Note that the installation requires You to log into Your AMD account. When asked to, allow "Terminal" to access data of other apps (the installation may succeed regardless).

### Usage
Run
```
Downloads/vivado-on-silicon-mac-main/scripts/start_container.sh
```
inside the terminal. The container can be stopped by pressing `Ctrl-C` inside the terminal or by logging out inside the container.

USB flashing support is limited, see the "USB Connection" paragraph below.

If you want to exchange files with the container, you need to store them inside the "vivado-on-silicon-mac-main" folder. Inside Vivado, the files will be accessible via the "/home/user" folder.

Memory and CPU resources can be changed per engine:

- Docker Desktop: Settings → Resources.
- OrbStack: `orb config set memory_mib 16384` (CPU and memory can also be adjusted in the OrbStack app's Settings).
- Colima: `colima stop && colima start --vm-type=vz --vz-rosetta --cpu 8 --memory 16`.

### Notes

If the installation fails or Vivado crashes, consider:
- deleting the folder and go through the above steps again
- establishing a more reliable internet connection
- trying a different version of Vivado
- increasing RAM / Swap / CPU allocations in the container engine settings.

Installer hashes are specific to each Vivado release. If a supported installer is rejected, add its MD5 to `scripts/hashes.sh`. The batch install configuration is **generated at install time**: `install_vivado.sh` asks which device families to install (default selection, all families, 7-series only, or UltraScale/UltraScale+/Versal only) or can let the installer generate the selection with `xsetup -b ConfigGen`. There are no per-version configuration files to maintain.

For a newly released Vivado version you can also create an untracked `scripts/hashes.local` (see `scripts/hashes.local.example`) with one line per installer: `<md5> <version-code> [web|sfd]`, for example `0123456789abcdef0123456789abcdef 202710`. This adds local support without editing the tracked hash list. If the installer hash is unknown, `setup.sh` additionally tries to detect the version from the installer file name and asks for confirmation; the install-time selection then generates the configuration (or falls back to `ConfigGen` for a version without a built-in catalog).

Vivado changed its installation layout in 2025.1 (`Xilinx/<version>/Vivado/` instead of `Xilinx/Vivado/<version>/`), and 2026.1 and later may change it again. The start script checks the known layouts and then searches the installation directory, so layout changes are handled on a best-effort basis.

**One Dockerfile, four Ubuntu bases.** The base image is chosen per Vivado version as the newest Ubuntu AMD officially supports for it: 18.04 for 2019.2, 20.04 for 2021.1/2021.2/2022.1, 22.04 for 2022.2–2024.1, and 24.04 for 2024.2+. `gen_image.sh` passes `--build-arg BASE_IMAGE=ubuntu:<version>`; the Dockerfile installs the packages common to all supported releases and then applies release-specific steps (ncurses5/libjpeg62/libssl1.1 vs t64 packages, TigerVNC tool layout, `.so.5` compatibility symlinks) inside conditional `RUN` steps. This keeps one file to maintain while every release runs on its best-supported Ubuntu. Override with `VIVADO_BASE_IMAGE` or `VIVADO_DOCKERFILE`.

Caveats: the Docker tags resolve to 18.04.6/22.04.5/24.04.x, slightly newer patch releases than some old matrices list (patch-level compatibility is expected). The 22.04 image also installs the focal `libssl1.1` package because some 2022.x/2023.x binaries still link against it. Ubuntu 18.04 is end-of-life for standard support; archive.ubuntu.com still serves bionic (as of 2026).

The built-in device-family catalogs for 2026.1 (and the exact selection for 2019.2/2021.2) have not been verified against real installers here. If the installer reports unknown module names, choose option 5 ("ConfigGen") in the install-time menu to let the installer generate the selection for that exact release.

You may download via `git` instead of downloading the ZIP file and/or modify the scripts. The installation is wholly contained in the repository folder, which is exposed in the Docker container as the `/home/user` folder.

Installation on external storage media may work but can cause issues, such as a file system (like FAT32, exFAT, NTFS) that does not support UNIX file permissions.

## Installing other software
If you want to use additional Ubuntu packages, specify them in the Dockerfile. If you want to install further AMD / Xilinx software, you can do so by copying the corresponding installer into the folder containing the Vivado installation and launching it via the GUI. __Attention!__ You must install it into the folder `/home/user/Xilinx` because any data outside of `/home/user` does not persist between VM reboots. You can even skip installing Vivado entirely by commenting out the last line of `setup.sh`. I do not plan on supporting this out of the box.

## How it works
### Docker, Rosetta & VNC
This collection of scripts creates an x64 Docker container running **Ubuntu 22.04** Linux (Ubuntu 18.04 or 24.04 depending on the Vivado version) that is accelerated by [Rosetta 2](https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment) via the Apple Virtualization framework. The container has all the necessary libraries preinstalled for running Vivado. It is installed automatically given an installer file that the user must provide. GUI functionality is provided via VNC and the built-in "Screen Sharing" app. Any Docker-compatible engine can run the container; Docker Desktop is the default and the only one whose settings are adjusted automatically.

The Docker container image is kept under **8 GiB** — Vivado itself is installed to the host-side bind-mounted folder (`/home/user/Xilinx`) and is therefore not part of the image.

### Java heap limit
Vivado and its installer are Java-based. The container sets `JAVA_TOOL_OPTIONS="-Xmx4096m -Xms512m"` so that the JVM heap is capped at **4 GiB**. This keeps the memory used by the Java-based installer and Vivado components within the Docker resource limits you configure. Synthesis runs in separate non-JVM processes, so this setting does not bound their memory usage.

### USB connection
Vivado and `hw_server` only run inside the Linux container, so the FPGA's JTAG port has to be reached from there. These scripts use the [Xilinx Virtual Cable protocol](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/644579329/Xilinx+Virtual+Cable) for that: the Mac runs an XVC server ([xvcd](https://github.com/tmbinc/xvcd) by Felix Domke) which forwards the JTAG traffic, and `hw_server` inside the container connects to it.

Native USB passthrough is available through some engines but not through all of them:

- **OrbStack** (2.2 or later) can attach USB devices to its Linux environment (`orb usb list`, then `orb usb attach <id>`; use dedicated passthrough for a JTAG cable). This native path is **not wired into the scripts yet**: containers do not always receive the `/dev/bus/usb` device nodes automatically, and `hw_server` needs raw libusb access. If you want to try it, attach the cable and verify that `lsusb` and `hw_server` see it inside the container; otherwise keep xvcd (the default). Please report results.
- **Apple container** (`container` 1.7.x) has no USB/device passthrough option. macOS 27 adds the Accessory Access framework and `VZUSBPassthroughDeviceConfiguration` for Virtualization-based apps, but Apple's `container` CLI does not expose it yet, so xvcd is still required when using that engine.
- **Docker Desktop and Colima** do not support USB device passthrough on macOS (Docker Desktop only documents USB/IP with a privileged container and a host-side USB/IP server), so xvcd is used there as well.

Therefore xvcd remains the default for all engines. It is included in this repository.

xvcd is contained in this repository, but with slight changes to make it compile on modern day macOS (compilation requires libusb and libftdi installed via homebrew, though there is a compiled version included). It runs continuously while the docker container is running.

This version of xvcd only supports the FT2232C chip. There are forks of this software supporting other boards such as [xvcserver by Xilinx](https://github.com/Xilinx/XilinxVirtualCable).

## Files overview
- `header.sh`: Common shell functions (including container engine detection)
- `setup.sh`: Setup file, to be run once in the beginning
- `start_container.sh`: Starts the container and "Screen Sharing" session
- `configure_docker.sh`: Automatically sets necessary Docker Desktop settings (skipped for OrbStack/Colima)
- `gen_image.sh`: Generates the Docker image and selects the Ubuntu base for the detected Vivado version
- `Dockerfile`: Single image definition; the `BASE_IMAGE` build arg selects Ubuntu 18.04 / 20.04 / 22.04 / 24.04
- `install_vivado.sh`: Runs the installer and generates the batch install configuration (device-family selection) at install time
- `hashes.sh`: Contains the hashes of installer files and associated Vivado versions
- `hashes.local`: Optional, untracked extra hashes for new Vivado releases (format shown in `hashes.local.example`)
- `linux_start.sh`: Docker container start script
- `de_start.sh`: Script to be executed when the desktop environment has started
- `cleanup.sh`: Removes Vivado and dotfiles.
- `xvcd`: [xvcd](https://github.com/tmbinc/xvcd) source and binary copy
- `install_bin`: Full path to Vivado installation binary
- `vnc_resolution`: Manually adjustable resolution of the container GUI, formatted like "widthxheight"
- `vncpasswd`: Password for the VNC connection. It is purposefully weak, as it serves no security function. The VNC server inside the container will not allow outside connections. The password can be changed manually nonetheless.

## License, copyright and trademark information
The repository's contents are licensed under the Creative Commons Zero v1.0 Universal license.

Note that the scripts are configured such that you automatically agree to Xilinx' and 3rd party EULAs (which can be obtained by extracting the installer yourself) by running them. You also automatically agree to [Apple's software license agreement](https://www.apple.com/legal/sla/) for Rosetta 2.

If you are installing Vivado version 2021.1:
- WebTalk data collection is enabled, and you automatically agree to the corresponding terms.
- For more information, see: https://docs.amd.com/r/2021.1-English/ug973-vivado-release-notes-install-license/WebTalk-Participation.

This repository contains the modified source code of [xvcd](https://github.com/tmbinc/xvcd) as well as a compiled version which is statically linked against [libusb](https://libusb.info/) and [libftdi](https://www.intra2net.com/en/developer/libftdi/). This is in accordance to the [LGPL Version 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html), under which both of those libraries are licensed.

Vivado and Xilinx are trademarks of Xilinx, Inc.

Arm is a registered trademark of Arm Limited (or its subsidiaries) in the US and/or elsewhere.

Apple, Mac, MacBook, MacBook Air, macOS and Rosetta are trademarks of Apple Inc., registered in the U.S. and other countries and regions.

Docker and the Docker logo are trademarks or registered trademarks of Docker, Inc. in the United States and/or other countries. Docker, Inc. and other parties may also have trademark rights in other terms used herein.

Intel and the Intel logo are trademarks of Intel Corporation or its subsidiaries.

Linux® is the registered trademark of Linus Torvalds in the U.S. and other countries.

Oracle, Java, MySQL, and NetSuite are registered trademarks of Oracle and/or its affiliates. Other names may be trademarks of their respective owners.

X Window System is a trademark of the Massachusetts Institute of Technology.
