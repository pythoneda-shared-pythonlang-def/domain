# sync-pythoneda-project/flake.nix
#
# This file packages sync-pythoneda-project script as a Nix flake.
#
# Copyright (C) 2008-today rydnr's https://github.com/pythoneda-shared-pythonlang-def/domain
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
{
  description =
    "Nix flake for pythoneda-shared-pythonlang/domain/sync-pythoneda-project";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixos.url = "github:NixOS/nixpkgs/24.05";
    dry-wit = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:rydnr/dry-wit/3.0.24?dir=nix";
    };
    pythoneda-shared-pythonlang-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-pythonlang-def/banner/0.0.61";
    };
    release-tag = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.dry-wit.follows = "dry-wit";
      url = "github:rydnr/nix-dry-wit-scripts/0.0.37?dir=release-tag";
    };
    update-latest-inputs-nix-flake = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.dry-wit.follows = "dry-wit";
      url =
        "github:rydnr/nix-dry-wit-scripts/0.0.37?dir=update-latest-inputs-nix-flake";
    };
    update-sha256-nix-flake = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.dry-wit.follows = "dry-wit";
      url =
        "github:rydnr/nix-dry-wit-scripts/0.0.37?dir=update-sha256-nix-flake";
    };
  };
  outputs = inputs:
    with inputs;
    let
      defaultSystems = flake-utils.lib.defaultSystems;
      supportedSystems = if builtins.elem "armv6l-linux" defaultSystems then
        defaultSystems
      else
        defaultSystems ++ [ "armv6l-linux" ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        org = "pythoneda-shared-pythonlang-def";
        repo = "domain";
        pname = "${org}-${repo}-sync-pythoneda-project";
        version = "0.0.76";
        pkgs = import nixos { inherit system; };
        description =
          "dry-wit script to update a PythonEDA project' dependencies to their latest versions";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        shared = import "${pythoneda-shared-pythonlang-banner}/nix/shared.nix";
        sync-pythoneda-project-for = { dry-wit, release-tag
          , update-latest-inputs-nix-flake, update-sha256-nix-flake }:
          pkgs.stdenv.mkDerivation rec {
            inherit pname version;
            src = ../.;
            propagatedBuildInputs = [
              dry-wit
              release-tag
              update-latest-inputs-nix-flake
              update-sha256-nix-flake
            ];
            phases = [ "unpackPhase" "installPhase" ];

            installPhase = ''
              mkdir -p $out/bin
              cp sync-pythoneda-project/sync-pythoneda-project.sh $out/bin
              chmod +x $out/bin/sync-pythoneda-project.sh
              cp sync-pythoneda-project/README.md LICENSE $out/
              substituteInPlace $out/bin/sync-pythoneda-project.sh \
                --replace "#!/usr/bin/env dry-wit" "#!/usr/bin/env ${dry-wit}/dry-wit" \
                --replace "__RELEASE_TAG__" "${release-tag}/bin/release-tag.sh" \
                --replace "__UPDATE_LATEST_INPUTS_NIX_FLAKE__" "${update-latest-inputs-nix-flake}/bin/update-latest-inputs-nix-flake.sh" \
                --replace "__UPDATE_SHA256_NIX_FLAKE__" "${update-sha256-nix-flake}/bin/update-sha256-nix-flake.sh";
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        apps = rec {
          default = sync-pythoneda-project-default;
          sync-pythoneda-project-default = sync-pythoneda-project-bash5;
          sync-pythoneda-project-bash5 = shared.app-for {
            package = packages.sync-pythoneda-project-bash5;
            entrypoint = "sync-pythoneda-project";
          };
          sync-pythoneda-project-zsh = shared.app-for {
            package = packages.sync-pythoneda-project-zsh;
            entrypoint = "sync-pythoneda-project";
          };
          sync-pythoneda-project-fish = shared.app-for {
            package = packages.sync-pythoneda-project-fish;
            entrypoint = "sync-pythoneda-project";
          };
        };
        defaultApp = apps.default;
        defaultPackage = packages.default;
        packages = rec {
          default = sync-pythoneda-project-default;
          sync-pythoneda-project-default = sync-pythoneda-project-bash5;
          sync-pythoneda-project-bash5 = sync-pythoneda-project-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-bash5;
            release-tag = release-tag.packages.${system}.release-tag-bash5;
            update-latest-inputs-nix-flake =
              update-latest-inputs-nix-flake.packages.${system}.update-latest-inputs-nix-flake-bash5;
            update-sha256-nix-flake =
              update-sha256-nix-flake.packages.${system}.update-sha256-nix-flake-bash5;
          };
          bash5-pythoneda-projects-zsh = sync-pythoneda-project-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-zsh;
            release-tag = release-tag.packages.${system}.release-tag-zsh;
            update-latest-inputs-nix-flake =
              update-latest-inputs-nix-flake.packages.${system}.update-latest-inputs-nix-flake-zsh;
            update-sha256-nix-flake =
              update-sha256-nix-flake.packages.${system}.update-sha256-nix-flake-zsh;
          };
          sync-pythoneda-project-fish = sync-pythoneda-project-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-fish;
            release-tag = release-tag.packages.${system}.release-tag-fish;
            update-latest-inputs-nix-flake =
              update-latest-inputs-nix-flake.packages.${system}.update-latest-inputs-nix-flake-fish;
            update-sha256-nix-flake =
              update-sha256-nix-flake.packages.${system}.update-sha256-nix-flake-fish;
          };
        };
      });
}
