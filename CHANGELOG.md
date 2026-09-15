# Changelog

## [Unreleased]

### Fixed

- The Linux ppc64le binary encoded broken video: its PowerPC-optimized code
  paths produced wrong pictures (a lossless `--qp 0` encode did not decode back
  to its input, and `--crf 23` came out at a fraction of the quality at four
  times the size). The rebuilt binary encodes correctly. Measured under
  emulation; the other Linux binaries, the Intel macOS binary and the Windows
  binary encode correctly.

### Changed

- The Windows binary is now built by the same compiler as the Linux and macOS
  ones (2.54 MB to 2.30 MB). Checked on Windows 10 against the previous binary:
  `--version`, and encoding a raw video gives a byte-identical H.264 file.

  It now uses the Universal C Runtime, which is part of Windows 10 and later.
  On Windows 7 or 8.1 that runtime has to be installed first — it comes through
  Windows Update. The previous binary did not need it.
