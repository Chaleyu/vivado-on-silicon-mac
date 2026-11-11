# xvcd maintenance notes

This directory vendors [tmbinc/xvcd](https://github.com/tmbinc/xvcd), a small
Xilinx Virtual Cable (XVC) daemon that lets Vivado's `hw_server` (inside the
container) reach a USB JTAG cable attached to the Mac.

## Current state

- Upstream default branch: **`ftdi`** (the `master` branch is stale since 2015).
  Latest synced commit: `e24745d5fe29b52d30e5c08cda4f2ecdf4909abb`
  ("Compilation fix (#11)", 2025-03-06). Upstream activity is low but non-zero.
- License: CC0 1.0 (public domain), so vendoring is unproblematic.
- Local changes on top of upstream (kept intentionally):
  - `src/Makefile`: macOS/Homebrew include path, IOKit/CoreFoundation/Security
    frameworks, static libftdi1/libusb-1.0 linking, `-Wno-deprecated`.
  - `bin/xvcd`: prebuilt arm64 binary (statically linked, no Homebrew runtime
    dependency).
- Known limitation: only FTDI FT2232-based cables are supported. The XVC
  protocol itself is tiny (`getinfo`, `settck`, `shift`), so most limitations
  come from the USB backend, not the protocol.

## Maintenance plan

1. **Track upstream regularly** (e.g. every Vivado release or quarter):
   ```sh
   git ls-remote https://github.com/tmbinc/xvcd ftdi
   ```
   Compare the reported SHA with the `Synced commit` line in `UPSTREAM`.
   To inspect a new revision without adding a remote:
   ```sh
   git clone --depth=1 --branch=ftdi https://github.com/tmbinc/xvcd /tmp/xvcd-upstream
   diff -ru /tmp/xvcd-upstream/src scripts/xvcd/src
   ```
   Re-apply the `src/Makefile` macOS changes when updating the sources, then
   rebuild and commit source + binary together.
2. **Rebuild the binary** with `./build.sh` (requires
   `brew install libftdi libusb`). The script checks for missing dependencies,
   builds into `bin/`, and warns if the result is not statically linked.
3. **Smoke-test after every rebuild** on a real cable:
   - start the container, connect a cable, run `hw_server`/Vivado;
   - program a small bitstream and open the Hardware Manager;
   - confirm the JTAG chain is detected (the container sees the xvcd server at
     `host.docker.internal:2542` / `host.container.internal:2542`).
4. **Adapter coverage**: report/test FT2232C/D/H, FT4232H and Digilent HS2/HS3
   cables where possible. If a cable does not work, an alternative server (see
   below) may be the better fix than patching xvcd.
5. **Security/robustness**: xvcd listens on TCP port 2542. It is meant for
   localhost use only; do not expose the port on a public interface.

## Alternatives evaluated (as of 2026-11)

| Project | License | Activity | Hardware | macOS | Verdict |
|---|---|---|---|---|---|
| [tmbinc/xvcd](https://github.com/tmbinc/xvcd) | CC0-1.0 | low (latest fix 2025-03) | FTDI FT2232 | yes, patched here | **kept as default**: tiny, prebuilt arm64 binary, no runtime deps, battle-tested |
| [xvc-rs / `xvc-usb`](https://github.com/Schottkyc137/xvc-rs) | MIT | active (2026), but very new (`xvc-server-usb` 0.1.1, ~17 downloads) | FT2232H/FT4232H/FT232H | source-only; upstream CI is Linux-only, macOS not tested upstream | best modern candidate; **no prebuilt binaries**, needs Rust 1.91+ (`cargo install xvc-server-usb`) |
| [jtag-remote-server](https://github.com/jiegec/jtag-remote-server) | MIT | active (2025-12) | FT2232/FT4232, Digilent HS2/HS3 | yes (README uses a MacBook) | strong alternative; build from source (CMake/Meson/Nix), no prebuilt macOS binary |
| [Rubusch/mini-xvcd](https://github.com/Rubusch/mini-xvcd) | MIT | active (2026) | FT2232H (MPSSE) | not targeted (RPi/Linux) | wait |
| [fabrica-eda/tapir](https://github.com/fabrica-eda/tapir) | MIT | active (2026) | FT2232H interface A | Linux/Nix focused | early-stage; not a general replacement |
| [Xilinx/XilinxVirtualCable](https://github.com/Xilinx/XilinxVirtualCable) | Apache-2.0 | active (2026) | reference sample code | Linux-oriented | reference implementation, not a packaged macOS daemon |
| [kholia/xvc-pico](https://github.com/kholia/xvc-pico) | — | active (2026) | RP2040/Pico as the probe | host-side irrelevant | different hardware approach |
| [BerkeleyLab/XVC-FTDI-JTAG](https://github.com/BerkeleyLab/XVC-FTDI-JTAG) | — | last 2024 | FT4232H only | unclear | inactive, narrow hardware support |

Conclusion: there is no drop-in, dependency-free replacement that is clearly
better than the vendored xvcd for the default macOS + FT2232 setup. We therefore
keep xvcd as the default and offer an escape hatch: `start_container.sh` accepts
an external server without code changes:

```sh
# xvc-usb (xvc-rs)
VIVADO_XVC_BIN="$HOME/.cargo/bin/xvc-usb" zsh ./scripts/start_container.sh

# jtag-remote-server (built from source; FT2232H pid 0x6010, XVC mode)
VIVADO_XVC_BIN="/path/to/jtag-remote-server" VIVADO_XVC_ARGS="-p 6010 -x" \
    zsh ./scripts/start_container.sh
```

`VIVADO_XVC_ARGS` is split by the shell, so quote complex argument lists
carefully. The scripts do not otherwise manage an external server's lifecycle.

## Can we just use `xvc-usb` (xvc-rs) instead of maintaining xvcd?

Not yet, for three concrete reasons:

1. **No prebuilt binary is published.** The GitHub release
   `xvc-server-usb/v0.1.1` contains only source archives (`.tar.gz`/`.zip`), and
   crates.io distributes source. There is no macOS/arm64 artifact to download.
2. **macOS is not covered by upstream CI.** `xvc-rs`'s CI builds/tests only on
   `ubuntu-latest`; the crate is very new (v0.1.1, ~17 downloads at the time of
   writing). It is a plausible replacement, not a proven one.
3. **We cannot verify it without hardware.** A real FTDI cable + Vivado
   programming run is needed before we could call it "confirmed usable". This
   repository's CI has no board.

You can try it at any time without changing the default:

```sh
# needs Rust >= 1.91
cargo install xvc-server-usb --version 0.1.1 --locked
VIVADO_XVC_BIN="$HOME/.cargo/bin/xvc-usb" zsh ./scripts/start_container.sh
```

If it works with your cable, we can switch the default: build a pinned arm64
`xvc-usb` binary from the same source, vendor it with its MIT license, and keep
vendored xvcd only as a fallback (or drop it). Until then xvcd stays the default
because it is prebuilt, dependency-free and already used by this project.

## Updating this directory

1. Sync `src/` with upstream `ftdi`.
2. Re-apply the macOS `src/Makefile` changes.
3. Run `./build.sh`.
4. Update `UPSTREAM` with the new SHA/date and this file's "Current state"
   section if the maintenance status changed.
5. Commit source, binary and docs in one commit.
