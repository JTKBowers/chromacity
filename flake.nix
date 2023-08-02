{
  description = "A very basic flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-bubblewrap = {
      url = "github:JTKBowers/nix-bubblewrap";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nix-bubblewrap,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [rust-overlay.overlays.default];
        };
        runtimeDeps = with pkgs; [
          vulkan-loader
          wayland
          wayland-protocols
          libxkbcommon
        ];
        cargo = nix-bubblewrap.lib.wrapPackage pkgs {
          pkg = pkgs.cargo;
          name = "cargo";
          bindCwd = true;
          shareNet = true;
          presets = ["ssl"];
          envs = {
            HOME = "$HOME";
            CARGO_TERM_COLOR = "always";
            RUST_BACKTRACE = "\"$RUST_BACKTRACE\"";
            XDG_RUNTIME_DIR = "$XDG_RUNTIME_DIR";
            WAYLAND_DISPLAY = "$WAYLAND_DISPLAY";
            LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath runtimeDeps}";
          };
          extraBindPaths = [
            {
              mode = "rw";
              path = "$HOME/.cargo";
            }
            "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
          ];
          extraDepPkgs = with pkgs;
            [
              rustc
              gcc
              mold
              rustfmt
              clippy
            ]
            ++ runtimeDeps;
          runtimeStorePaths = [
            "/run/opengl-driver"
          ];
          extraArgs = [
            "--proc /proc"
            "--tmpfs /tmp"
            "--dev /dev"
            "--dev-bind /dev/dri /dev/dri"
            "--dev-bind /dev/null /dev/null"
            "--dev-bind /dev/urandom /dev/urandom"
          ];
        };
      in {
        packages = {
          hello = pkgs.hello;
          default = pkgs.hello;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.openssl
            pkgs.pkg-config
            cargo
          ];
        };
      }
    );
}
