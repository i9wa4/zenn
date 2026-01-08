{
  description = "Zenn content";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    dotfiles = {
      url = "github:i9wa4/dotfiles";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    dotfiles,
  }: let
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # nix fmt
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      customPkgs = dotfiles.packages.${system};
    in {
      default = pkgs.mkShell {
        packages = [
          # nixpkgs
          pkgs.actionlint
          pkgs.gitleaks
          pkgs.pre-commit
          pkgs.zizmor
          # custom packages from dotfiles
          customPkgs.ghalint
          customPkgs.ghatm
          customPkgs.pinact
          customPkgs.rumdl
        ];
      };
    });
  };
}
