{
  description = "Nix flake packaging for wgo";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs systems;
      mkForSystem =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          common = {
            pname = "wgo";
            version = "unstable-2026-04-29";
            src = ./.;
            subPackages = [ "." ];
            vendorHash = "sha256-6ZJNXw/ahaIziQGVNgjbTbm53JiO3dYCqJtdB///cmo=";

            meta = {
              description = "Live reload for Go apps";
              homepage = "https://github.com/bokwoon95/wgo";
              license = lib.licenses.mit;
              mainProgram = "wgo";
              platforms = lib.platforms.linux;
            };
          };
          wgo = pkgs.buildGoModule (common // {
            doCheck = false;
          });
          wgoTest = pkgs.buildGoModule (common // {
            doCheck = true;
            checkPhase = ''
              runHook preCheck
              go test . -race -skip 'TestWgoCmd_(FileEvent|Polling)$'
              runHook postCheck
            '';
          });
        in
        {
          inherit pkgs wgo wgoTest;
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          s = mkForSystem system;
        in
        {
          default = s.wgo;
        }
      );

      checks = forAllSystems (
        system:
        let
          s = mkForSystem system;
        in
        {
          build = s.wgo;
          test = s.wgoTest;
        }
      );

      devShells = forAllSystems (
        system:
        let
          s = mkForSystem system;
        in
        {
          default = s.pkgs.mkShell {
            packages = [
              s.pkgs.go
              s.pkgs.nixfmt
            ];
          };
        }
      );
    };
}
