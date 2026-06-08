# x264

[x264](https://www.videolan.org/developers/x264.html) — VideoLAN's H.264/AVC encoder. A single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/x264/actions/workflows/x264.yml/badge.svg)](https://github.com/unpins/x264/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install x264`.

## Usage

Run the `x264` program with [unpin](https://github.com/unpins/unpin):

```bash
unpin x264 -o out.264 input.y4m
```

To install it onto your PATH:

```bash
unpin install x264
```

## Build locally

```bash
nix build github:unpins/x264
./result/bin/x264 --version
```

Or run directly:

```bash
nix run github:unpins/x264
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/x264/releases) page has standalone binaries for manual download.

## Build notes

- Single binary — the `x264` encoder, with its own libx264 linked statically
  in. The standalone CLI reads raw YUV / y4m, so the closure is just nasm + the
  C library (no ffmpeg/lavf input layer).
- **Windows** is built with mingw: x264 is a first-class Windows codec and its
  own `configure` cross-compiles cleanly. The `.exe` is fully static — it
  imports only system DLLs (`KERNEL32`/`SHELL32`/`msvcrt`), no libx264 DLL and
  no libgcc/winpthread runtime.
- No man page: neither nixpkgs nor the upstream tarball ships one (upstream docs
  are plain text), so none is embedded.
