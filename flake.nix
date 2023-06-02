{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:

    let system = "x86_64-darwin";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        name = "language model dev environment";

        packages = [
          pkgs.python310
          pkgs.python310Packages.tokenizers
          pkgs.python310Packages.prompt-toolkit
          pkgs.python310Packages.torch
        ];
      };
    };
}
