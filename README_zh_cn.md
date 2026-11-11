# vivado-on-silicon-mac
这是一个在基于 Arm® 的 Apple Silicon Mac 上，通过启用 Rosetta 的虚拟机安装 [Vivado™](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html) 的工具。本项目与 Xilinx 或 AMD 没有任何关联。

**[English](README.md) | 简体中文**

*已更新至 2026.1！*

支持的版本：
- 2019.2（仅支持 SFD，使用 legacy 镜像）
- 2021.1
- 2021.2（仅支持 SFD，使用 legacy 镜像）
- 2022.2
- 2023.1
- 2023.2
- 2024.1
- 2024.2
- 2025.1（以及 2025.1.1）
- 2025.2（以及 2025.2.1）
- 2026.1（以及 2026.1.1）——安装配置为初版，见下方说明

## 兼容性
- **Apple Silicon**：支持 M1、M2、M3、M4 及更新芯片。
- **macOS**：推荐 macOS 15（Sequoia）或更新版本。由于 Rosetta 模拟存在缺陷，大多数 macOS 14（Sonoma）版本**不受支持**——如果检测到 macOS 14，安装脚本会给出警告。
- **容器引擎**：Docker Desktop（默认）、[OrbStack](https://orbstack.dev/) 或 [Colima](https://github.com/abiosoft/colima)。三者都提供 `docker` 命令行，脚本会自动检测并启动对应的容器引擎。
- Docker 容器镜像保持在 **8 GiB** 以内（Vivado 本身安装在绑定挂载的目录中，不在镜像内）。

## 如何安装
预计安装过程需要一到两个小时，Web 安装器需要下载约 20 GB 数据。
本地安装器（SFD）约需 30 分钟。

### 准备工作
首先需要一个兼容 Docker 的容器引擎：

- **Docker Desktop**（默认）：安装 [Docker Desktop](https://www.docker.com/products/docker-desktop/)，注意选择 "Apple Chip" 而不是 "Intel Chip"。建议关闭 "Open Docker Dashboard when Docker Desktop starts" 选项。
- **OrbStack**：安装 [OrbStack](https://orbstack.dev/)。默认已启用 Rosetta 模拟；建议为 Vivado 调高内存上限：`orb config set memory_mib 16384`。
- **Colima**：`brew install colima docker`，然后使用 `colima start --vm-type=vz --vz-rosetta --cpu 8 --memory 16` 启动。Vivado 所需的 x86_64 模拟依赖 `--vz-rosetta` 参数。

你的 Mac 必须安装 Rosetta。如果尚未安装，安装脚本会提示你安装。

你还需要 Vivado 安装文件：要么是 "Linux® Self Extracting Web Installer"（`.bin`），要么是完整的 "SFD" 安装器（`.tar` / `.tar.gz`）。

> AMD 会下架旧版本 Web 安装器所使用的在线下载文件。如果所选版本受影响，安装脚本会给出提示；这些版本请改用 SFD（完整）安装器，它包含全部文件。

### 安装步骤
1. 下载这个[工具](https://github.com/ichi4096/vivado-on-silicon-mac/archive/refs/heads/main.zip)。
2. 解压 ZIP 文件。
3. 将 Vivado 安装文件复制到解压后的目录中。
4. 打开终端，复制粘贴并运行：
```
cd Downloads/vivado-on-silicon-mac-main
caffeinate -dim zsh ./scripts/setup.sh
```
5. 按照终端中的（黄色）提示操作。

`setup.sh` 会自动启动检测到的容器引擎；如果使用 Docker Desktop，还会自动启用 Virtualization Framework、Rosetta 模拟并设置足够的交换空间。对于 OrbStack 和 Colima，则会打印推荐的设置方法。

注意：安装过程需要登录 AMD 账号。当系统询问时，请允许 "Terminal" 访问其他应用的数据（即使不允许，安装也可能成功）。

### 使用
在终端中运行
```
Downloads/vivado-on-silicon-mac-main/scripts/start_container.sh
```
容器可以通过在终端按 `Ctrl-C` 或在容器内注销来停止。

USB 烧录支持有限，请参考下方 "USB 连接" 段落。

如果需要在容器与宿主机之间交换文件，请将文件存放在 "vivado-on-silicon-mac-main" 目录内。在 Vivado 中，这些文件可以通过 "/home/user" 目录访问。

内存和 CPU 资源可按容器引擎分别调整：

- Docker Desktop：设置 → Resources。
- OrbStack：`orb config set memory_mib 16384`（CPU 和内存也可在 OrbStack 应用的设置中调整）。
- Colima：`colima stop && colima start --vm-type=vz --vz-rosetta --cpu 8 --memory 16`。

### 说明

如果安装失败或 Vivado 崩溃，可以尝试：
- 删除该目录，重新执行上述步骤
- 使用更稳定的网络连接
- 尝试其他 Vivado 版本
- 调高容器引擎设置中的 RAM / Swap / CPU 配额。

安装器哈希和批量安装配置与每个 Vivado 版本一一对应。如果受支持的安装器被拒绝，请将其 MD5 添加到 `scripts/hashes.sh`。如果安装器报告未知的模块名，请按 `scripts/install_configs/<version>.txt` 文件顶部的说明，用 `xsetup -b ConfigGen` 重新生成该文件。

对于刚发布的 Vivado 版本，你还可以创建一个不被 git 跟踪的 `scripts/hashes.local`（格式见 `scripts/hashes.local.example`），每个安装器一行：`<md5> <版本号> [web|sfd]`，例如 `0123456789abcdef0123456789abcdef 202710`。这样无需修改被跟踪的哈希列表即可在本地支持新版本。如果安装器哈希未知，`setup.sh` 还会尝试从安装文件名推断版本并请你确认（必须已存在对应的安装配置）。

Vivado 在 2025.1 更改了安装目录结构（`Xilinx/<version>/Vivado/`，而不再是 `Xilinx/Vivado/<version>/`），2026.1 及之后版本还可能再次调整。启动脚本会先检查已知的目录结构，然后搜索安装目录，因此会尽力适配目录布局的变化。

Vivado 2021.2 及更早版本只支持 Ubuntu 20.04 或更早系统。对于这些版本，`gen_image.sh` 会自动构建 `Dockerfile.legacy`（Ubuntu 20.04），而不是默认的 Ubuntu 24.04 镜像。这些旧版本的测试程度低于新版本；2019.2/2021.2 的安装配置来自真实 ConfigGen 输出，但尚未在本仓库做过端到端验证。如果安装器报告未知模块名，可在安装脚本提示时用 `xsetup -b ConfigGen` 重新生成配置（当某个版本没有随仓库提供的配置时，安装脚本现在会自动这样做）。

2026.1 的安装配置是初版：其模块系列名称与已核实的 2025.1/2025.2 ConfigGen 输出一致，但尚未在 2026.1 安装器上验证。如果安装器报告未知模块，请用 `xsetup -b ConfigGen` 重新生成 `scripts/install_configs/202610.txt`。

你也可以通过 `git` 而不只是 ZIP 文件下载本项目，并修改脚本。整个安装过程都包含在仓库目录内，该目录在 Docker 容器中映射为 `/home/user`。

安装到外部存储介质可能可行，但可能引发问题，例如 FAT32、exFAT、NTFS 等文件系统不支持 UNIX 文件权限。

## 安装其他软件
如果需要额外的 Ubuntu 软件包，请在 Dockerfile 中指定。如果还需要安装其他 AMD / Xilinx 软件，可以把对应的安装器复制到 Vivado 安装目录中，并通过图形界面启动它。__注意！__ 必须安装到 `/home/user/Xilinx` 目录，因为 `/home/user` 之外的数据在 VM 重启后不会保留。你甚至可以通过注释掉 `setup.sh` 的最后一行来完全跳过 Vivado 安装。不过我不打算开箱即用地支持这种做法。

## 工作原理
### Docker、Rosetta 与 VNC
这些脚本会创建一个运行 **Ubuntu 24.04** Linux 的 x64 Docker 容器，并通过 Apple Virtualization framework 使用 [Rosetta 2](https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment) 加速。容器内预装了运行 Vivado 所需的全部库。只要用户提供安装器文件，Vivado 就会被自动安装。图形界面通过 VNC 和系统自带的 "屏幕共享" 应用提供。任何兼容 Docker 的容器引擎都可以运行该容器；Docker Desktop 是默认引擎，也是唯一会自动修改其设置的引擎。

Docker 容器镜像保持在 **8 GiB** 以内——Vivado 安装在宿主机侧绑定挂载的目录（`/home/user/Xilinx`）中，因此不包含在镜像内。

### Java 堆上限
Vivado 及其安装器基于 Java。容器设置了 `JAVA_TOOL_OPTIONS="-Xmx4096m -Xms512m"`，将 JVM 堆上限限制为 **4 GiB**。这样可以让基于 Java 的安装器和 Vivado 组件的内存占用保持在所配置的 Docker 资源限制内。综合（synthesis）在独立的非 JVM 进程中运行，因此不受该设置限制。

### USB 连接
Vivado 和 `hw_server` 只运行在 Linux 容器内，因此需要从容器内访问 FPGA 的 JTAG 端口。这些脚本使用 [Xilinx Virtual Cable 协议](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/644579329/Xilinx+Virtual+Cable)：macOS 宿主机运行 XVC 服务器（[xvcd](https://github.com/tmbinc/xvcd)，作者 Felix Domke）转发 JTAG 数据，容器内的 `hw_server` 连接到它。

部分容器引擎支持原生 USB 直通，但并非全部：

- **OrbStack**（2.2 及以上）可以把 USB 设备附加到它的 Linux 环境（`orb usb list`，然后 `orb usb attach <id>`；JTAG 线缆请使用独占直通）。该原生路径**尚未接入脚本**：容器不一定能自动获得 `/dev/bus/usb` 设备节点，且 `hw_server` 需要原始 libusb 访问权限。如想尝试，请附加线缆后确认容器内 `lsusb` 和 `hw_server` 能看到设备；否则继续使用默认的 xvcd。欢迎反馈测试结果。
- **Apple container**（`container` 1.7.x）没有 USB/设备直通选项。macOS 27 为基于 Virtualization 的应用新增了 Accessory Access 框架和 `VZUSBPassthroughDeviceConfiguration`，但 Apple 的 `container` CLI 尚未暴露该能力，因此使用该引擎时仍然需要 xvcd。
- **Docker Desktop 和 Colima** 在 macOS 上不支持 USB 设备直通（Docker Desktop 仅支持需要特权容器和宿主机 USB/IP 服务的 USB/IP 方案），因此也使用 xvcd。

因此 xvcd 仍然是所有引擎下的默认方案，它已包含在本仓库中。

xvcd 已包含在本仓库中，但做了少量修改使其能在现代 macOS 上编译（编译需要 homebrew 安装的 libusb 和 libftdi，不过仓库中也包含编译好的版本）。它随容器运行而持续运行。

此版本的 xvcd 只支持 FT2232C 芯片。也有一些支持其他开发板的 fork，例如 [Xilinx 的 xvcserver](https://github.com/Xilinx/XilinxVirtualCable)。

## 文件说明
- `header.sh`：通用 shell 函数（包括容器引擎检测）
- `setup.sh`：安装设置脚本，只需在开始时运行一次
- `start_container.sh`：启动容器和 "屏幕共享" 会话
- `configure_docker.sh`：自动设置必要的 Docker Desktop 选项（OrbStack/Colima 下会跳过）
- `gen_image.sh`：根据 Dockerfile 生成要使用的 Docker 镜像（Vivado <= 2021.2 使用 legacy 镜像）
- `Dockerfile.legacy`：Vivado <= 2021.2 自动使用的 Ubuntu 20.04 镜像
- `hashes.sh`：包含安装器文件哈希及其对应的 Vivado 版本
- `hashes.local`：可选的、不被 git 跟踪的额外哈希，用于新 Vivado 版本（格式见 `hashes.local.example`）
- `linux_start.sh`：Docker 容器启动脚本
- `de_start.sh`：桌面环境启动后执行的脚本
- `cleanup.sh`：删除 Vivado 和点文件。
- `xvcd`：[xvcd](https://github.com/tmbinc/xvcd) 源码和二进制副本
- `install_bin`：Vivado 安装二进制文件的完整路径
- `vnc_resolution`：可手动调整的容器 GUI 分辨率，格式为 "宽x高"
- `vncpasswd`：VNC 连接密码。它故意设置得很弱，因为它不承担安全功能。容器内的 VNC 服务器不会接受外部连接。你也可以手动修改该密码。

## 许可、版权与商标信息
本仓库内容基于 Creative Commons Zero v1.0 Universal 许可发布。

请注意，脚本的配置方式意味着：运行这些脚本即表示你自动同意 Xilinx 及第三方 EULA（你可以自行解压安装器获取这些协议）。同时你也自动同意 [Apple 的软件许可协议](https://www.apple.com/legal/sla/)（针对 Rosetta 2）。

如果你安装的是 Vivado 2021.1：
- WebTalk 数据收集已启用，你自动同意相应条款。
- 更多信息见：https://docs.amd.com/r/2021.1-English/ug973-vivado-release-notes-install-license/WebTalk-Participation。

本仓库包含 [xvcd](https://github.com/tmbinc/xvcd) 的修改版源码，以及一个静态链接了 [libusb](https://libusb.info/) 和 [libftdi](https://www.intra2net.com/en/developer/libftdi/) 的编译版本。这符合两者所采用的 [LGPL Version 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html) 许可要求。

Vivado 和 Xilinx 是 Xilinx, Inc. 的商标。

Arm 是 Arm Limited（或其子公司）在美国和/或其他地区的注册商标。

Apple、Mac、MacBook、MacBook Air、macOS 和 Rosetta 是 Apple Inc. 在美国及其他国家和地区注册的商标。

Docker 和 Docker 标志是 Docker, Inc. 在美国和/或其他国家的商标或注册商标。Docker, Inc. 及其他方也可能对文中使用的其他术语拥有商标权。

Intel 和 Intel 标志是 Intel Corporation 或其子公司的商标。

Linux® 是 Linus Torvalds 在美国和其他国家的注册商标。

Oracle、Java、MySQL 和 NetSuite 是 Oracle 和/或其关联公司的注册商标。其他名称可能是其各自所有者的商标。

X Window System 是麻省理工学院的商标。
