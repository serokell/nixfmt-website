# © 2019-2024 Serokell <hi@serokell.io>
# © 2019-2024 Lars Jellema <lars.jellema@gmail.com>
#
# SPDX-License-Identifier: MPL-2.0
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixfmt-src.url = "github:NixOS/nixfmt";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, nixfmt-src, ...}@inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };

      inherit (pkgs) haskell lib;

      ghcjsPackages = pkgs.haskell.packages.ghcjs810.override (old: {
        overrides = (self: super: {
          QuickCheck = haskell.lib.dontCheck super.QuickCheck;
          tasty-quickcheck = haskell.lib.dontCheck super.tasty-quickcheck;
          scientific = haskell.lib.dontCheck super.scientific;
          temporary = haskell.lib.dontCheck super.temporary;
          time-compat = haskell.lib.dontCheck super.time-compat;
          text-short = haskell.lib.dontCheck super.text-short;
          vector = haskell.lib.dontCheck super.vector;
          aeson = super.aeson_1_5_6_0;
          nixfmt = super.callCabal2nix "nixfmt" nixfmt-src {};
        });
      });

    in {
      packages = {
        nixfmt-js = ghcjsPackages.callCabal2nix "nixfmt" ./. { };
        nixfmt-webdemo = pkgs.runCommandNoCC "nixfmt-webdemo" { } ''
          mkdir $out
          cp ${./js/index.html} $out/index.html
          cp ${./js/404.html} $out/404.html
          cp ${self.packages.${system}.nixfmt-js}/bin/js-interface.jsexe/{rts,lib,out,runmain}.js $out
          substituteInPlace $out/index.html --replace ../dist/build/js-interface/js-interface.jsexe/ ./
        '';
        inherit (pkgs) awscli;
      };
    });
}
