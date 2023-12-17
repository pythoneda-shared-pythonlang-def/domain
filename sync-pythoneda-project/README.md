# Synchronize a PythonEDA project

[dry-wit](https://github.com/rydnr/dry-wit "dry-wit")(Bash) script that synchronizes versions of dependencies in a PythonEDA project.

## Usage

``` sh
sync-pythoneda-project.sh [-v|--debug] [-vv|--trace] [-q|--quiet] [-h|--help] -r|--rootFolder arg [-t|--githubToken arg] -R|--releaseName arg [-g|--gpgKeyId arg]
Copyleft 2023-today Automated Computing Machinery S.L.
Distributed under the terms of the GNU General Public License v3

Synchronizes dependencies of a PythonEDA project

Where:
  * -r|--rootFolder arg: The root folder of PythonEDA definition projects. Mandatory.
  * -v|--debug: Display debug messages. Optional.
  * -vv|--trace: Display trace messages. Optional.
  * -q|--quiet: Be silent. Optional.
  * -h|--help: Display information about how to use the script. Optional.
  * -t|--githubToken arg: The github token. Optional.
  * -R|--releaseName arg: The release name. Mandatory.
  * -g|--gpgKeyId arg: The id of the GPG key. Optional.
  * -c|--commitMessage: The commit message. Optional.
  * -m|--tagMessage: The tag message. Optional.
```
