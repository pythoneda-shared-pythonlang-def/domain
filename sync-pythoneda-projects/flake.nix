# sync-pythoneda-projects/flake.nix
#
# This file packages sync-pythoneda-projects script as a Nix flake.
#
# Copyright (C) 2008-today rydnr's nix-dry-wit-scripts
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
    "dry-wit script to update PythonEDA projects' dependencies to their latest dependencies";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixos.url = "github:NixOS/nixpkgs/23.11";
    dry-wit = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:rydnr/dry-wit/3.0.10?dir=nix";
    };
    pythoneda-shared-pythoneda-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-pythoneda-def/banner/0.0.37";
    };
    update-latest-inputs-nix-flake = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.dry-wit.follows = "dry-wit";
      url =
        "github:rydnr/nix-dry-wit-scripts/0.0.7?dir=update-latest-inputs-nix-flake";
    };
    release-tag = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.dry-wit.follows = "dry-wit";
      url = "github:rydnr/nix-dry-wit-scripts/0.0.7?dir=release-tag";
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
        org = "rydnr";
        repo = "nix-dry-wit-scripts";
        pname = "${org}-${repo}";
        version = "0.0.13";
        pkgs = import nixos { inherit system; };
        description =
          "dry-wit script to update PythonEDA projects' dependencies to their latest dependencies";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        shared = import "${pythoneda-shared-pythoneda-banner}/nix/shared.nix";
        sync-pythoneda-projects-for =
          { dry-wit, release-tag, update-latest-inputs-nix-flake }:
          pkgs.stdenv.mkDerivation rec {
            inherit pname version;
            src = ../.;
            propagatedBuildInputs =
              [ dry-wit release-tag update-latest-inputs-nix-flake ];
            phases = [ "unpackPhase" "installPhase" ];

            installPhase = ''
              mkdir -p $out/bin
              cp sync-pythoneda-projects/sync-pythoneda-projects.sh $out/bin
              chmod +x $out/bin/sync-pythoneda-projects.sh
              cp sync-pythoneda-projects/README.md LICENSE $out/
              substituteInPlace $out/bin/sync-pythoneda-projects.sh \
                --replace "#!/usr/bin/env dry-wit" "#!/usr/bin/env ${dry-wit}/dry-wit" \
                --replace "__RELEASE_TAG__" "${release-tag}/bin/release-tag.sh" \
                --replace "__UPDATE_LATEST_INPUTS_NIX_FLAKE__" "${update-latest-inputs-nix-flake}/bin/update-latest-inputs-nix-flake.sh";
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        apps = rec {
          default = sync-pythoneda-projects-default;
          sync-pythoneda-projects-default = sync-pythoneda-projects-bash5;
          sync-pythoneda-projects-bash5 = shared.app-for {
            package = packages.sync-pythoneda-projects-bash5;
            entrypoint = "sync-pythoneda-projects";
          };
          sync-pythoneda-projects-zsh = shared.app-for {
            package = packages.sync-pythoneda-projects-zsh;
            entrypoint = "sync-pythoneda-projects";
          };
          sync-pythoneda-projects-fish = shared.app-for {
            package = packages.sync-pythoneda-projects-fish;
            entrypoint = "sync-pythoneda-projects";
          };
        };
        defaultApp = apps.default;
        defaultPackage = packages.default;
        packages = rec {
          default = sync-pythoneda-projects-default;
          sync-pythoneda-projects-default = sync-pythoneda-projects-bash5;
          sync-pythoneda-projects-bash5 = sync-pythoneda-projects-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-bash5;
            release-tag = release-tag.packages.${system}.release-tag-bash5;
            update-latest-inputs-nix-flake =
              update-latest-inputs-nix-flake.packages.${system}.update-latest-inputs-nix-flake-bash5;
          };
          sync-pythoneda-projects-zsh = sync-pythoneda-projects-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-zsh;
            release-tag = release-tag.packages.${system}.release-tag-zsh;
            update-latest-inputs-nix-flake =
              update-latest-inputs-nix-flake.packages.${system}.update-latest-inputs-nix-flake-zsh;
          };
          sync-pythoneda-projects-fish = sync-pythoneda-projects-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-fish;
            release-tag = release-tag.packages.${system}.release-tag-fish;
            update-latest-inputs-nix-flake =
              update-latest-inputs-nix-flake.packages.${system}.update-latest-inputs-nix-flake-fish;
          };
        };
      });
}
