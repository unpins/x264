{
  description = "the x264 H.264 encoder as a single self-contained binary";

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
      #
      # engineFold additionally gives -flto to the CLI objects. nix-lib pins
      # x264 to the lto=false engine stdenv SET-WIDE (its AVX
      # `override-stack-alignment=64` collides with a bitcode consumer's LTO
      # module at link). That is right for the LIBRARY, but here x264 also IS
      # the folded program: with every object native, no `main` reaches the
      # bitcode module and the hook's entry trampoline — itself bitcode calling
      # `extern main` — binds to the dispatcher's own `main`, so every
      # invocation tail-loops forever. Compiling the main-bearing CLI object
      # with -flto puts `main` in module.bc; libx264.a stays native and rides
      # the sidecar, asm kernels included.
      #
      # The minimum differs per OS: the hook's `ld.lld -r` is the ELF driver,
      # and a loose Mach-O object is fatal there ("unknown file type") where on
      # ELF it is merely dropped into the sidecar. So darwin sends every own
      # object ($(OBJCLI), all plain C) to bitcode; only libx264.a stays Mach-O,
      # and an ARCHIVE member the ELF driver can't read is skipped with a
      # warning and rescued — the case the hook is built for.
      mk = { engineFold }: scope:
        scope.x264.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + "\n" + ''
            for o in $outputs; do
              d="''${!o}"
              rm -rf "$d/share" "$d/lib" "$d/include"
              find "$d/bin" -mindepth 1 -maxdepth 1 \
                ! -name 'x264' ! -name 'x264.exe' -delete 2>/dev/null || true
            done
          '';
        } // scope.lib.optionalAttrs engineFold {
          # nixpkgs' makeFlags name explicit targets (install-bashcompletion
          # install-lib-shared), so the default `all` never runs and the CLI is
          # only linked by `make install` — i.e. during installPhase. The module
          # hook is a postBuild, so it would find no link sidecar at all. Build
          # the CLI in buildPhase; the install then just copies it.
          buildFlags = [ "cli" ];
          postPatch = (old.postPatch or "") + ''
            echo '${if scope.stdenv.hostPlatform.isDarwin then "$(OBJCLI)" else "x264.o"}: CFLAGS += -flto' >> Makefile
          '';
        });

      # A `--version` smoke passes an encoder whose output is wrong, so the
      # native build encodes for real: a lossless 8-bit and 10-bit encode must
      # decode (with ffmpeg) back to the exact input, and encoding through
      # stdin/stdout must match encoding files. The input is generated with awk.
      # Runs wherever the build machine can execute the result.
      withRoundTrip = pkgs: drv: drv.overrideAttrs (old: {
        doInstallCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;
        nativeInstallCheckInputs = (old.nativeInstallCheckInputs or [ ])
          ++ [ pkgs.buildPackages.ffmpeg-headless ];
        installCheckPhase = ''
          runHook preInstallCheck
          x="''${bin:-$out}/bin/x264"
          fail() { echo "installCheck: $*"; exit 1; }
          LC_ALL=C awk 'BEGIN {
            for (f = 0; f < 5; f++) {
              for (i = 0; i < 64 * 48; i++) printf "%c", (i * 7 + f * 13 + int(i / 64) * 5) % 256
              for (i = 0; i < 32 * 24 * 2; i++) printf "%c", (i * 3 + f * 29) % 256
            }
          }' > src.yuv
          test "$(wc -c < src.yuv)" -eq 23040 || fail "probe input has the wrong size"
          in="--input-res 64x48 --fps 25"
          "$x" --quiet --threads 1 --qp 0 $in -o ll.264 src.yuv || fail "cannot encode"
          ffmpeg -v error -i ll.264 -f rawvideo -pix_fmt yuv420p back.yuv
          cmp -s src.yuv back.yuv || fail "lossless 8-bit encode is not exact"
          "$x" --quiet --threads 1 --qp 0 --output-depth 10 $in -o ll10.264 src.yuv || fail "cannot encode 10-bit"
          ffmpeg -v error -i ll10.264 -f rawvideo -pix_fmt yuv420p back10.yuv
          cmp -s src.yuv back10.yuv || fail "lossless 10-bit encode is not exact"
          "$x" --quiet --threads 1 --crf 23 $in -o crf.264 src.yuv || fail "cannot encode at --crf"
          "$x" --quiet --threads 1 --crf 23 $in -o - - < src.yuv > piped.264 || fail "cannot encode through a pipe"
          cmp -s crf.264 piped.264 || fail "encoding through stdin/stdout differs from files"
          echo "installCheck: lossless 8/10-bit round trips exact, stdin/stdout match files"
          runHook postInstallCheck
        '';
      });
    in
    ulib.mkStandaloneFlake {
      inherit self;
      name = "x264";

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      multicall = {
        # The `.exe` on the engine too, not the nixpkgs mingw-gcc cross — which
        # is why windowsBuild now folds like the native one below.
        windows = true;
        programs = [{ name = "x264"; }];
      };
      embedMan = false;
      smoke = [ "--version" ];
      smokePattern = "x264";
      build = pkgs: withRoundTrip pkgs (mk { engineFold = true; } pkgs.pkgsStatic);
      windowsBuild = pkgs: mk { engineFold = true; } (ulib.mingwStaticCross pkgs);
    };
}
