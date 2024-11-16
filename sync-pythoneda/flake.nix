# sync-pythoneda/flake.nix
#
# This file packages sync-pythoneda script as a Nix flake.
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
    "Nix flake for pythoneda-shared-pythonlang/domain/sync-pythoneda";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixos.url = "github:NixOS/nixpkgs/24.05";
    dry-wit = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:rydnr/dry-wit/3.0.20?dir=nix";
    };
    pythoneda-shared-pythonlang-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-pythonlang-def/banner/0.0.61";
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
        pname = "${org}-${repo}-sync-pythoneda";
        version = "0.0.67";
        pkgs = import nixos { inherit system; };
        description =
          "dry-wit script to update PythonEDA projects' dependencies to their latest dependencies";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        shared = import "${pythoneda-shared-pythonlang-banner}/nix/shared.nix";
        sync-pythoneda-for = { dry-wit, sh }:
          pkgs.stdenv.mkDerivation rec {
            inherit pname version;
            src = ../.;
            propagatedBuildInputs = [ dry-wit ];
            phases = [ "unpackPhase" "installPhase" ];

            installPhase = ''
              mkdir -p $out/bin
              echo "#!/usr/bin/env ${sh}/bin/sh" > $out/bin/sync-pythoneda-project.sh
              echo "# Copyright 2023-today Automated Computing Machinery S.L." >> $out/bin/sync-pythoneda-project.sh
              echo "# Distributed under the terms of the GNU General Public License v3" >> $out/bin/sync-pythoneda-project.sh
              echo "" >> $out/bin/sync-pythoneda-project.sh
              echo "# This script is needed since sync-pythoneda-project has references to other scripts, and nix resolves them when building the flake" >> $out/bin/sync-pythoneda-project.sh
              echo "" >> $out/bin/sync-pythoneda-project.sh
              echo "${pkgs.nix}/bin/nix run github:${org}/${repo}/${version}?dir=sync-pythoneda-project -- \"\$@\"" >> $out/bin/sync-pythoneda-project.sh
              echo "# vim: syntax=sh ts=2 sw=2 sts=4 sr noet" >> $out/bin/sync-pythoneda-project.sh
              cp sync-pythoneda/sync-pythoneda.sh $out/bin/
              chmod +x $out/bin/sync-pythoneda.sh $out/bin/sync-pythoneda-project.sh
              cp sync-pythoneda/README.md LICENSE $out/
              substituteInPlace $out/bin/sync-pythoneda.sh \
                --replace "#!/usr/bin/env dry-wit" "#!/usr/bin/env ${dry-wit}/dry-wit" \
                --replace "__SYNC_PYTHONEDA_PROJECT__" "$out/bin/sync-pythoneda-project.sh";
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
            sh = pkgs.bash_5;
          };
          bash5-pythoneda-projects-zsh = sync-pythoneda-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-zsh;
            sh = pkgs.bash_zsh;
          };
          sync-pythoneda-fish = sync-pythoneda-for {
            dry-wit = dry-wit.packages.${system}.dry-wit-fish;
            sh = pkgs.bash_fish;
          };
        };
      });
}
