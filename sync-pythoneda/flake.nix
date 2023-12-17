# sync-pythoneda/flake.nix
#
# This file packages sync-pythoneda script as a Nix flake.
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
      url = "github:rydnr/dry-wit/3.0.14?dir=nix";
    };
    pythoneda-shared-pythoneda-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-pythoneda-def/banner/0.0.39";
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
        version = "0.0.18";
        pkgs = import nixos { inherit system; };
        description =
          "dry-wit script to update PythonEDA projects' dependencies to their latest dependencies";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        shared = import "${pythoneda-shared-pythoneda-banner}/nix/shared.nix";
        sync-pythoneda-for = { dry-wit }:
          pkgs.stdenv.mkDerivation rec {
            inherit pname version;
            src = ../.;
            propagatedBuildInputs = [ dry-wit ];
            phases = [ "unpackPhase" "installPhase" ];

            installPhase = ''
              mkdir -p $out/bin
              cp sync-pythoneda/sync-pythoneda.sh sync-pythoneda-project/sync-pythoneda-project.sh $out/bin
              chmod +x $out/bin/sync-pythoneda.sh $out/bin/sync-pythoneda-project.sh
              cp sync-pythoneda/README.md LICENSE $out/
              substituteInPlace $out/bin/sync-pythoneda.sh \
                --replace "#!/usr/bin/env dry-wit" "#!/usr/bin/env ${dry-wit}/dry-wit" \
                --replace "__SYNC_PYTHONEDA_PROJECT__" "${out}/bin/sync-pythoneda-project.sh";
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        apps = rec {
          default = sync-pythoneda-default;
          sync-pythoneda-default = sync-pythoneda-bash5;
          sync-pythoneda-bash5 = shared.app-for {
            package = packages.sync-pythoneda-bash5;
            entrypoint = "sync-pythoneda";
          };
          sync-pythoneda-zsh = shared.app-for {
            package = packages.sync-pythoneda-zsh;
            entrypoint = "sync-pythoneda";
          };
          sync-pythoneda-fish = shared.app-for {
            package = packages.sync-pythoneda-fish;
            entrypoint = "sync-pythoneda";
          };
        };
        defaultApp = apps.default;
        defaultPackage = packages.default;
        packages = rec {
          default = sync-pythoneda-default;
          sync-pythoneda-default = sync-pythoneda-bash5;
          sync-pythoneda-bash5 = sync-pythoneda-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-bash5;
            release-tag = release-tag.packages.${system}.release-tag-bash5;
            update-latest-inputs-nix-flake =
              update-latest-inputs-nix-flake.packages.${system}.update-latest-inputs-nix-flake-bash5;
            update-sha256-nix-flake =
              update-sha256-nix-flake.packages.${system}.update-sha256-nix-flake-sync;
          };
          bash5-pythoneda-projects-zsh = sync-pythoneda-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-zsh;
            release-tag = release-tag.packages.${system}.release-tag-zsh;
            update-latest-inputs-nix-flake =
              update-latest-inputs-nix-flake.packages.${system}.update-latest-inputs-nix-flake-zsh;
            update-sha256-nix-flake =
              update-sha256-nix-flake.packages.${system}.update-sha256-nix-flake-zsh;
          };
          sync-pythoneda-fish = sync-pythoneda-for {
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
