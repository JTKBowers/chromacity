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
        cargo = nix-bubblewrap.lib.wrapPackage pkgs {
          pkg = pkgs.rust-bin.stable.latest.default;
          name = "cargo";
          bindCwd = "ro";
          envs = {
            "HOME" = "$HOME";
          };
          shareNet = true;
          extraArgs = [
            "--proc /proc"
          ];
          extraRoBindDirs = [
            "$WAYLAND_DISPLAY"
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
