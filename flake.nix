# © 2019-2024 Serokell <hi@serokell.io>
# © 2019-2024 Lars Jellema <lars.jellema@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0
{
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    nixfmt-src.url = "github:NixOS/nixfmt";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, haskellNix, flake-utils, nixfmt-src, ...}@inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ haskellNix.overlay ];
        inherit (haskellNix) config;
      };

      inherit (pkgs.pkgsCross.ghcjs) haskell-nix;

      nixfmt-js = haskell-nix.cabalProject {
        compiler-nix-name = "ghc98";
        src = ./.;
        pkg-def-extras = [
          (_: {
            # override nixfmt with a newer version
            packages.nixfmt = {...}: (haskell-nix.cabalProject {
              compiler-nix-name = "ghc98";
              src = nixfmt-src;
              # we need base version to be at least 4.19, so we're relaxing the upper bound
              configureArgs = "--allow-newer base";
            }).pkg-set.config.packages.nixfmt;
          })
        ];
      };

    in {
      packages = {
        nixfmt-js = nixfmt-js.nixfmt-js.components.exes.js-interface;
        nixfmt-webdemo = pkgs.runCommandNoCC "nixfmt-webdemo" { } ''
          mkdir $out
          cp ${./js/index.html} $out/index.html
          cp ${./js/404.html} $out/404.html
          cp ${self.packages.${system}.nixfmt-js}/bin/js-interface $out/nixfmt.js
        '';
        inherit (pkgs) awscli;
      };
    });
}
