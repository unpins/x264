{
  description = "Standalone build of x264";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # x264 ships a single CLI (the `x264` H.264 encoder), so this is a plain
  # single-binary build. Windows goes through mingw — x264 is a first-class
  # Windows codec and its own configure detects the mingw cross cleanly.
  #
  # No man page: neither nixpkgs nor the upstream tarball install one (upstream
  # docs are plain text under doc/), so embedMan is off.
  #
  # The build only links its own static libx264 (the standalone CLI reads raw
  # YUV / y4m — no ffmpeg/lavf input), so the closure is just nasm + libc.
  outputs = { self, unpins-lib }:
    let
      ulib = unpins-lib.lib;
      # Keep only the encoder binary: the regular build also drops a
      # bash-completion file (and, when shared, a libx264 dylib/dll) into the
      # output, which a single-binary package doesn't ship.
      prune = old: {
        postInstall = (old.postInstall or "") + "\n" + ''
          for o in $outputs; do
            d="''${!o}"
            rm -rf "$d/share" "$d/lib" "$d/include"
            find "$d/bin" -mindepth 1 -maxdepth 1 \
              ! -name 'x264' ! -name 'x264.exe' -delete 2>/dev/null || true
          done
        '';
      };
    in
    ulib.mkStandaloneFlake {
      inherit self;
      name = "x264";
      embedMan = false;
      smoke = [ "--version" ];
      smokePattern = "x264";
      build = pkgs: pkgs.pkgsStatic.x264.overrideAttrs prune;
      windowsBuild = pkgs: (ulib.mingwStaticCross pkgs).x264.overrideAttrs prune;
    };
}
