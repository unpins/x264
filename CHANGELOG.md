# Changelog

## [Unreleased]

### Changed

- The Windows binary is now built by the same compiler as the Linux and macOS
  ones (2.54 MB to 2.30 MB). Checked on Windows 10 against the previous binary:
  `--version`, and encoding a raw video gives a byte-identical H.264 file.

  It now uses the Universal C Runtime, which is part of Windows 10 and later.
  On Windows 7 or 8.1 that runtime has to be installed first — it comes through
  Windows Update. The previous binary did not need it.
