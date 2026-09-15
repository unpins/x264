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
unpin x264 --crf 23 -o out.mkv input.y4m
unpin x264 --input-res 1920x1080 --fps 30 -o out.264 input.yuv
```

It reads Y4M or raw YUV video and writes H.264 as a raw `.264` stream, or in an
`.mkv` or `.flv` file.

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
nix run github:unpins/x264 -- --version
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/x264/releases) page has standalone binaries for manual download.

## Build notes

- **Windows:** a single `.exe`, no companion DLLs.
- **No MP4 output:** writing `.mp4` needs the L-SMASH or GPAC library, which
  this build doesn't include. Write `.mkv` or a raw `.264` stream instead.
- **No input from other containers:** reading MP4, MKV and similar files needs
  FFmpeg libraries, which this build doesn't include; convert to Y4M first.
- **No man pages** — x264 ships none; run with `--help` or `--fullhelp`.
