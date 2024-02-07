# flake.nix
#
# This file packages pythoneda-shared/domain as a Nix flake.
#
# Copyright (C) 2023-today rydnr's pythoneda-shared-def/domain
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
  description = "Support for event-driven architectures in Python";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixos.url = "github:NixOS/nixpkgs/23.11";
    pythoneda-shared-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-def/banner/0.0.47";
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
        org = "pythoneda-shared";
        repo = "domain";
        version = "0.0.26";
        sha256 = "06px7683vv640c91lisfjhz5xpczw046xx4c7rkkd2cacxzwfdz3";
        pname = "${org}-${repo}";
        pkgs = import nixos { inherit system; };
        description = "Support for event-driven architectures in Python";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/pythoneda-shared/domain";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        archRole = "S";
        space = "D";
        layer = "D";
        nixosVersion = builtins.readFile "${nixos}/.version";
        nixpkgsRelease =
          builtins.replaceStrings [ "\n" ] [ "" ] "nixos-${nixosVersion}";
        shared = import "${pythoneda-shared-banner}/nix/shared.nix";
        pythoneda-shared-domain-for = { python }:
          let
            pnameWithUnderscores =
              builtins.replaceStrings [ "-" ] [ "_" ] pname;
            pythonpackage = "pythoneda.shared";
            pythonVersionParts = builtins.splitVersion python.version;
            pythonMajorVersion = builtins.head pythonVersionParts;
            pythonMajorMinorVersion =
              "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
            wheelName =
              "${pnameWithUnderscores}-${version}-py${pythonMajorVersion}-none-any.whl";
          in python.pkgs.buildPythonPackage rec {
            inherit pname version;
            projectDir = ./.;
            scripts = ./scripts;
            pyprojectTemplateFile = ./pyprojecttoml.template;
            pyprojectTemplate = pkgs.substituteAll {
              authors = builtins.concatStringsSep ","
                (map (item: ''"${item}"'') maintainers);
              desc = description;
              inherit homepage pname pythonMajorMinorVersion pythonpackage
                version;
              package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
              src = pyprojectTemplateFile;
            };
            src = pkgs.fetchFromGitHub {
              owner = org;
              rev = version;
              inherit repo sha256;
            };

            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [ pip poetry-core ];
            propagatedBuildInputs = with python.pkgs; [ ];

            pythonImportsCheck = [ pythonpackage ];

            unpackPhase = ''
              cp -r ${src} .
              sourceRoot=$(ls | grep -v env-vars)
              chmod +w $sourceRoot
              cp ${pyprojectTemplate} $sourceRoot/pyproject.toml
            '';

            postInstall = ''
              pushd /build/$sourceRoot
              for f in $(find . -name '__init__.py'); do
                if [[ ! -e $out/lib/python${pythonMajorMinorVersion}/site-packages/$f ]]; then
                  cp $f $out/lib/python${pythonMajorMinorVersion}/site-packages/$f;
                fi
              done
              popd
              mkdir $out/dist
              cp -r ${scripts} $out/dist/scripts
              cp dist/${wheelName} $out/dist
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        defaultPackage = packages.default;
        devShells = rec {
          default = pythoneda-shared-domain-default;
          pythoneda-shared-domain-default = pythoneda-shared-domain-python311;
          pythoneda-shared-domain-python38 = shared.devShell-for {
            banner = "${
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python38
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-shared-domain-python38;
            pythoneda-shared-domain = packages.pythoneda-shared-domain-python38;
            pythoneda-shared-banner =
              pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python38;
            python = pkgs.python38;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-shared-domain-python39 = shared.devShell-for {
            banner = "${
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python39
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-shared-domain-python39;
            pythoneda-shared-domain = packages.pythoneda-shared-domain-python39;
            pythoneda-shared-banner =
              pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python39;
            python = pkgs.python39;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-shared-domain-python310 = shared.devShell-for {
            banner = "${
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python310
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-shared-domain-python310;
            pythoneda-shared-domain =
              packages.pythoneda-shared-domain-python310;
            pythoneda-shared-banner =
              pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python310;
            python = pkgs.python310;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-shared-domain-python311 = shared.devShell-for {
            banner = "${
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python311
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-shared-domain-python311;
            pythoneda-shared-domain =
              packages.pythoneda-shared-domain-python311;
            pythoneda-shared-banner =
              pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python311;
            python = pkgs.python311;
            inherit archRole layer org pkgs repo space;
          };
        };
        packages = rec {
          default = pythoneda-shared-domain-default;
          pythoneda-shared-domain-default = pythoneda-shared-domain-python311;
          pythoneda-shared-domain-python38 =
            pythoneda-shared-domain-for { python = pkgs.python38; };
          pythoneda-shared-domain-python39 =
            pythoneda-shared-domain-for { python = pkgs.python39; };
          pythoneda-shared-domain-python310 =
            pythoneda-shared-domain-for { python = pkgs.python310; };
          pythoneda-shared-domain-python311 =
            pythoneda-shared-domain-for { python = pkgs.python311; };
        };
      });
}
