{
  description = "Playwright development environment with Chromium dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

          # FHS environment that contains all dependencies
          fhs = pkgs.buildFHSEnv {
            name = "playwright-env";
            targetPkgs = pkgs: (with pkgs; [
              # Node (full, not slim — npm needs the lib directory)
              nodejs
              pnpm

              # Keytar dependencies for secure credential storage
              libsecret
              pkg-config

              # All the dependencies Chromium needs
            alsa-lib
            at-spi2-atk
            atk
            cairo
            cups
            curl
            dbus
            expat
            fontconfig
            freetype
            libgbm
            glib
            glibc
            gtk3
            libdrm
            libxkbcommon
            mesa
            nspr
            nss
            pango
            pipewire
            stdenv.cc.cc
            systemd
            xorg.libX11
            xorg.libXcomposite
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXrandr
            xorg.libxcb
            xorg.libxshmfence

            # Wayland
            wayland

            # Electron
            electron
            libGL
            libGLU
          ]);
            profile = ''
              # Set environment variables for Playwright
              export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
              export PLAYWRIGHT_BROWSERS_PATH="$PWD/assets/pw-browsers"
              
              # Set PKG_CONFIG_PATH for keytar compilation
              export PKG_CONFIG_PATH="${pkgs.libsecret}/lib/pkgconfig:$PKG_CONFIG_PATH"
            '';
          runScript = pkgs.writeScript "fhs-run" ''
            #!/bin/bash
            if [ "$#" -gt 0 ]; then
              exec "$@"
            else
              exec bash
            fi
          '';
        };

        # Helper to wrap tools to run inside FHS
        wrap = name: pkgs.writeShellScriptBin name ''
          exec ${fhs}/bin/playwright-env ${name} "$@"
        '';

      in {
        devShells.default = pkgs.mkShell {
          packages = [
            fhs
            (wrap "node")
            (wrap "npm")
            (wrap "npx")
          ];

          shellHook = ''
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
            export PLAYWRIGHT_BROWSERS_PATH="$PWD/assets/pw-browsers"

            mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"

            echo "Ensuring Playwright browsers are installed..."
            # This runs via the wrapped npx, so it happens inside FHS
            npx playwright install chromium
            echo "Environment is ready."
          '';
        };
      }
    );
}
