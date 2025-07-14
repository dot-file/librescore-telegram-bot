{
  description = "Telegram bot that allows you to download pdf, midi and mp3 from musescore.com";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages = {
        librescore-telegram-bot = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.librescore-telegram-bot;
      };
    })
    //
    {
      nixosModules = {
        librescore-telegram-bot = import ./nixos.nix;
        default = self.nixosModules.librescore-telegram-bot;
      };
    };
}
