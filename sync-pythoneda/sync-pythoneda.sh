#!/usr/bin/env dry-wit
# Copyright 2023-today Automated Computing Machinery S.L.
# Distributed under the terms of the GNU General Public License v3

DW.import file
DW.import nix-flake
DW.import git

# fun: main
# api: public
# txt: Main logic. Gets called by dry-wit.
# txt: Returns 0/TRUE always, but may exit due to errors.
# use: main
function main() {

  local _projects=()
  _projects+=("${PYTHONEDA_PROJECTS[@]}")
  _projects+=("${TESTS[@]}")
  _projects+=("${RYDNR_PROJECTS[@]}")
  _projects+=("${ACMSL_PROJECTS[@]}")

  # from sync-pythoneda-project.sh -vv -h
  local -i _skippedProject=24

  resolveVerbosity
  local _commonArgs=(${RESULT})
  if ! isEmpty "${GITHUB_TOKEN}"; then
    _commonArgs+=("-t" "${GITHUB_TOKEN}")
  fi
  _commonArgs+=("${_commonArgs[@]}" "-R" "${RELEASE_NAME}")
  if ! isEmpty "${COMMIT_MESSAGE}"; then
    _commonArgs+=("-c" "${COMMIT_MESSAGE}")
  fi
  if ! isEmpty "${TAG_MESSAGE}"; then
    _commonArgs+=("-m" "${TAG_MESSAGE}")
  fi
  if ! isEmpty "${GPG_KEY_ID}"; then
    _commonArgs+=("-g" "${GPG_KEY_ID}")
  fi
  local _updatedProjects=()
  local _upToDateProjects=()
  local _failedProjects=()
  local _project
  local _defOwner
  local _repo
  local -i _rescode
  local _output
  local -i _index=0
  local -i _totalProjects=${#_projects[@]}
  local _rootFolder

  createTempFile
  local _syncPythonedaProjectOutput="${RESULT}"

  if isNotEmpty "${START_FROM}"; then
    local -i _startFromIndex=0
    local -i _found=${FALSE}
    for _project in "${_projects[@]}"; do
      if areEqual "${_project}" "${START_FROM}"; then
        _found=${TRUE}
        break
      fi
      _startFromIndex=$((_startFromIndex + 1))
    done
    if isFalse ${_found}; then
      exitWithErrorCode UNKNOWN_PROJECT "${START_FROM}"
    fi
    _projects=("${_projects[@]:${_startFromIndex}}")
    _totalProjects=${#_projects[@]}
  fi

  local _origIFS="${IFS}"
  IFS="${DWIFS}"
  for _project in "${_projects[@]}"; do
    IFS="${_origIFS}"
    if extract_owner "${_project}"; then
      _defOwner="${RESULT}-def"
    else
      exitWithErrorCode CANNOT_EXTRACT_THE_OWNER_OF_PROJECT "${_project}"
    fi
    if extract_repo "${_project}"; then
      _repo="${RESULT}"
    else
      exitWithErrorCode CANNOT_EXTRACT_THE_REPOSITORY_NAME_OF_PROJECT "${_project}"
    fi
    _index=$((_index + 1))

    if root_folder_for "${_project}"; then
      _root_folder="${RESULT}"
    else
      exitWithErrorCode UNKNOWN_PROJECT "${_project}"
    fi
    logInfo "[${_index}/${_totalProjects}] Processing ${_defOwner}/${_repo}"
    "${SYNC_PYTHONEDA_PROJECT}" "${_commonArgs[@]}" -p "${_root_folder}/${_defOwner}/${_repo}" | tee "${_syncPythonedaProjectOutput}"
    _rescode=$?
    if isTrue ${_rescode}; then
      _updatedProjects+=("${_defOwner}/${_repo}")
    elif areEqual ${_rescode} ${_skippedProject}; then
      _upToDateProjects+=("${_defOwner}/${_repo}")
    else
      logInfo "Error processing ${_defOwner}/${_repo}"
      _output="$(<"${_syncPythonedaProjectOutput}")"
      if ! isEmpty "${_output}"; then
        logDebug "${_output}"
      fi
      _failedProjects+=("${_defOwner}/${_repo}")
      if isTrue "${CONTINUE_ON_ERROR}"; then
        continue
      else
        break
      fi
    fi
    IFS="${_origIFS}"
  done
  IFS="${_origIFS}"

  if isNotEmpty "${_failedProjects[@]}"; then
    logInfo -n "Number of projects that couldn't be updated"
    logInfoResult SUCCESS "${#_failedProjects[@]}"
    IFS="${DWIFS}"
    for _project in "${_failedProjects[@]}"; do
      IFS="${_origIFS}"
      logInfo "${_project}"
    done
    IFS="${_origIFS}"
  fi

  if isNotEmpty "${_upToDateProjects[@]}"; then
    logInfo -n "Number of projects already up to date"
    logInfoResult SUCCESS "${#_upToDateProjects[@]}"
    IFS="${DWIFS}"
    for _project in "${_upToDateProjects[@]}"; do
      IFS="${_origIFS}"
      logInfo "${_project}"
    done
    IFS="${_origIFS}"
  fi

  if isNotEmpty "${_updatedProjects[@]}"; then
    logInfo -n "Number of projects updated"
    logInfoResult SUCCESS "${#_updatedProjects[@]}"
    IFS="${DWIFS}"
    for _project in "${_updatedProjects[@]}"; do
      IFS="${_origIFS}"
      logInfo "${_project}"
    done
    IFS=','
    echo "[ ${_updatedProjects[*]} ]"
    IFS="${_origIFS}"
  fi
}

# fun: root_folder_for project
# api: public
# txt: Returns the root folder for given project.
# opt: project: The project to check.
# txt: Returns 0/TRUE if the project is known; 1/FALSE otherwise.
# txt: If the function returns 0/TRUE, the variable RESULT will contain the root folder.
# use: if root_folder_for "pythoneda-shared/banner"; then
# use:   echo "root folder: ${RESULT}";
# use: fi
function root_folder_for() {
  local _project="${1}"
  checkNotEmpty project "${_project}" 1

  local -i _rescode=${FALSE}
  local _result

  if arrayContains "${_project}" "${PYTHONEDA_PROJECTS[@]}"; then
    _rescode=${TRUE}
    _result="${PYTHONEDA_ROOT_FOLDER}"
  elif arrayContains "${_project}" "${TESTS[@]}"; then
    _rescode=${TRUE}
    _result="${TESTS_ROOT_FOLDER}"
  elif arrayContains "${_project}" "${RYDNR_PROJECTS[@]}"; then
    _rescode=${TRUE}
    _result="${RYDNR_ROOT_FOLDER}"
  elif arrayContains "${_project}" "${ACMSL_PROJECTS[@]}"; then
    _rescode=${TRUE}
    _result="${ACMSL_ROOT_FOLDER}"
  fi

  if isTrue ${_rescode}; then
    export RESULT="${_result}"
  fi

  return ${_rescode}
}

# fun: extract_owner project
# api: public
# txt: Extracts the owner from given project name.
# opt: project: The project name.
# txt: Returns 0/TRUE if the owner could be extracted; 1/FALSE otherwise.
# txt: If the function returns 0/TRUE, the variable RESULT will contain the owner.
# use: if extract_owner "pythoneda-shared-pythonlang/domain"; then echo "Owner: ${RESULT}"; fi
function extract_owner() {
  local _project="${1}"
  checkNotEmpty project "${_project}" 1

  local -i _rescode=${FALSE}
  local _result

  _result="$(echo "${_project}" | cut -d '/' -f 1 2>/dev/null)"
  _rescode=$?

  if isEmpty "${_result}"; then
    _rescode=${FALSE}
  fi
  if isTrue ${_rescode}; then
    export RESULT="${_result}"
  fi

  return ${_rescode}
}

# fun: extract_repo project
# api: public
# txt: Extracts the repository from given project name.
# opt: project: The project name.
# txt: Returns 0/TRUE if the repository could be extracted; 1/FALSE otherwise.
# txt: If the function returns 0/TRUE, the variable RESULT will contain the repository name.
# use: if extract_repo "pythoneda-shared-pythonlang/domain"; then echo "Repo: ${RESULT}"; fi
function extract_repo() {
  local _project="${1}"
  checkNotEmpty project "${_project}" 1

  local -i _rescode=${FALSE}
  local _result

  _result="$(command echo "${_project}" | command cut -d '/' -f 2 2>/dev/null)"
  _rescode=$?
  if isEmpty "${_result}"; then
    _rescode=${FALSE}
  fi
  if isTrue ${_rescode}; then
    export RESULT="${_result}"
  fi

  return ${_rescode}
}

## Script metadata and CLI settings.
setScriptDescription "Synchronizes PythonEDA projects"
setScriptLicenseSummary "Distributed under the terms of the GNU General Public License v3"
setScriptCopyright "Copyleft 2023-today Automated Computing Machinery S.L."

DW.getScriptName
SCRIPT_NAME="${RESULT}"
addCommandLineFlag "pythonedaRootFolder" "pr" "The root folder of PythonEDA definition projects" MANDATORY EXPECTS_ARGUMENT "${HOME}/github/pythoneda-def"
addCommandLineFlag "testsRootFolder" "tr" "The root folder of the definition repositories of tests" MANDATORY EXPECTS_ARGUMENT "${HOME}/github/pythoneda-tests-def"
addCommandLineFlag "rydnrRootFolder" "rr" "The root folder of Rydnr definition projects" MANDATORY EXPECTS_ARGUMENT "${HOME}/github/rydnr"
addCommandLineFlag "acmslRootFolder" "ar" "The root folder of ACM-SL definition projects" MANDATORY EXPECTS_ARGUMENT "${HOME}/github/acmslcom"
addCommandLineFlag "githubToken" "t" "The github token" OPTIONAL EXPECTS_ARGUMENT
addCommandLineFlag "releaseName" "R" "The release name" MANDATORY EXPECTS_ARGUMENT
addCommandLineFlag "gpgKeyId" "g" "The id of the GPG key" OPTIONAL EXPECTS_ARGUMENT
addCommandLineFlag "commitMessage" "c" "The commit message" OPTIONAL EXPECTS_ARGUMENT "Commit created with ${SCRIPT_NAME}"
addCommandLineFlag "tagMessage" "m" "The tag message" OPTIONAL EXPECTS_ARGUMENT "Tag created with ${SCRIPT_NAME}"
addCommandLineFlag "force" "f" "Force the release" OPTIONAL NO_ARGUMENT "${FALSE}"
addCommandLineFlag "continueOnError" "e" "Continue on error" OPTIONAL NO_ARGUMENT "${FALSE}"
addCommandLineFlag "startFrom" "s" "Start from given project" OPTIONAL EXPECTS_ARGUMENT

checkReq jq
checkReq sed
checkReq grep

addError PYTHONEDA_ROOT_FOLDER_DOES_NOT_EXIST "Given root folder for definition projects does not exist:"
addError TESTS_ROOT_FOLDER_DOES_NOT_EXIST "Given root folder for definition projects for tests does not exist:"
addError RYDNR_ROOT_FOLDER_DOES_NOT_EXIST "Given rydnr root folder for definition projects does not exist:"
addError ACMSL_ROOT_FOLDER_DOES_NOT_EXIST "Given acmsl root folder for definition projects does not exist:"
addError PROJECT_FOLDER_DOES_NOT_EXIST "Project folder does not exist:"
addError CANNOT_EXTRACT_THE_OWNER_OF_PROJECT "Cannot extract the owner of project:"
addError CANNOT_EXTRACT_THE_REPOSITORY_NAME_OF_PROJECT "Cannot extract the repository name of project:"
addError CANNOT_UPDATE_LATEST_INPUTS "Cannot update inputs to its latest versions in"
addError CANNOT_RELEASE_TAG "Cannot create a new release tag in"
addError UNKNOWN_PROJECT "Unknown project:"

PYTHONEDA_PROJECTS=(
  "pythoneda-shared-pythonlang/banner"
  "pythoneda-shared-pythonlang/domain"
  "pythoneda-shared-pythonlang/infrastructure"
  "pythoneda-shared-artifact/events"
  "pythoneda-shared-artifact/artifact-events"
  "pythoneda-shared-pythonlang/shell"
  "pythoneda-shared-git/shared"
  "pythoneda-shared-nix-flake/shared"
  "pythoneda-shared-artifact/shared"
  "pythoneda-shared-pythonlang/application"
  "pythoneda-shared-artifact/artifact-shared"
  "pythoneda-shared-artifact/events-infrastructure"
  "pythoneda-shared-artifact/artifact-events-infrastructure"
  "pythoneda-shared-artifact/artifact-infrastructure"
  "pythoneda-shared-artifact/infrastructure"
  "pythoneda-shared-artifact/application"
  "pythoneda-shared-code-requests/shared"
  "pythoneda-shared-code-requests/events"
  "pythoneda-shared-code-requests/events-infrastructure"
  "pythoneda-shared-code-requests/jupyterlab"
  "pythoneda-shared-artifact/code-events"
  "pythoneda-shared-artifact/code-events-infrastructure"
  "pythoneda-external-artf/flakeutils"
  "pythoneda-external-artf/nixpkgs"
  "pythoneda-realm-rydnr/events"
  "pythoneda-realm-rydnr/events-infrastructure"
  "pythoneda-realm-rydnr/realm"
  "pythoneda-realm-rydnr/infrastructure"
  "pythoneda-realm-rydnr/application"
  "pythoneda-realm-unveilingpartner/realm"
  "pythoneda-realm-unveilingpartner/infrastructure"
  "pythoneda-realm-unveilingpartner/application"
  "pythoneda-sandbox/python-dep"
  "pythoneda-sandbox/python"
  "pythoneda-sandbox-artifact/python-dep"
  "pythoneda-sandbox-artifact/python"
  "pythoneda-sandbox-artifact/python-artifact"
  "pythoneda-sandbox-artifact/python-infrastructure"
  "pythoneda-sandbox-artifact/python-application"
  "pythoneda-artifact/git"
  "pythoneda-artifact/git-infrastructure"
  "pythoneda-artifact/git-application"
  "pythoneda-artifact/nix-flake"
  "pythoneda-artifact/nix-flake-infrastructure"
  "pythoneda-artifact/nix-flake-application"
  "pythoneda-artifact/code-request-infrastructure"
  "pythoneda-artifact/code-request-application"
  "pythoneda-shared-pythonlang-artf/domain"
  "pythoneda-shared-pythonlang-artf/infrastructure"
  "pythoneda-shared-pythonlang-artf/application"
  "pythoneda-shared-git/github"
  "pythoneda-shared-runtime/lifecycle-events"
  "pythoneda-shared-runtime/lifecycle-events-infrastructure"
  "pythoneda-shared-runtime-infra/eventstoredb-events"
  "pythoneda-shared-runtime-infra/eventstoredb-events-infrastructure"
  "pythoneda-runtime-infrastructure/eventstoredb"
  "pythoneda-runtime-infrastructure/eventstoredb-infrastructure"
  "pythoneda-runtime-infrastructure/eventstoredb-application"
  "pythoneda-runtime/boot"
  "pythoneda-runtime/boot-infrastructure"
  "pythoneda-runtime/boot-application"
  "pythoneda-shared-iac/events"
  "pythoneda-shared-iac/shared"
  "pythoneda-shared-iac/pulumi-azure"
  "pythoneda-tools-artifact/git-hook"
  "pythoneda-tools-artifact/new-domain"
  "pythoneda-sandbox/flow-sample"
)

TESTS=(
  "pythoneda-sandbox/flow-sample-tests"
)

RYDNR_PROJECTS=()
#  "tools/nix-flake-to-graphviz"
#  "learn/basics-pytorch"
#  "learn/leetcode-python"
#  "grammars/nix-flake-python-antlr4-parser"
#)

ACMSL_PROJECTS=(
  "acmsl/licdata-events"
  "acmsl/licdata-events-infrastructure"
  "acmsl/licdata-domain"
  "acmsl/licdata-infrastructure"
  "acmsl/licdata-application"
  "acmsl/licdata-artifact-events"
  "acmsl/licdata-artifact-events-infrastructure"
  "acmsl/licdata-artifact-domain"
  "acmsl/licdata-artifact-infrastructure"
  "acmsl/licdata-artifact-application"
  "acmsl/licdata-iac-domain"
  "acmsl/licdata-iac-infrastructure"
  "acmsl/licdata-iac-application"
)

## deps
export SYNC_PYTHONEDA_PROJECT="__SYNC_PYTHONEDA_PROJECT__"
if areEqual "${SYNC_PYTHONEDA_PROJECT}" "$(command echo -n '__SYNC_PYTHONEDA' && command echo '_PROJECT__')"; then
  export SYNC_PYTHONEDA_PROJECT="sync-pythoneda-project.sh"
fi

function dw_check_pythonedaRootFolder_cli_flag() {
  if ! fileExists "${PYTHONEDA_ROOT_FOLDER}"; then
    exitWithErrorCode PYTHONEDA_ROOT_FOLDER_DOES_NOT_EXIST "${PYTHONEDA_ROOT_FOLDER}"
  fi
}

function dw_parse_pythonedaRootFolder_cli_flag() {
  export PYTHONEDA_ROOT_FOLDER="${1}"
}

function dw_check_testsRootFolder_cli_flag() {
  if ! fileExists "${TESTS_ROOT_FOLDER}"; then
    exitWithErrorCode TESTS_ROOT_FOLDER_DOES_NOT_EXIST "${TESTS_ROOT_FOLDER}"
  fi
}

function dw_parse_testsRootFolder_cli_flag() {
  export TESTS_ROOT_FOLDER="${1}"
}

function dw_check_rydnrRootFfolder_cli_flag() {
  if ! fileExists "${RYDNR_ROOT_FOLDER}"; then
    exitWithErrorCode RYDNR_ROOT_FOLDER_DOES_NOT_EXIST "${RYDNR_ROOT_FOLDER}"
  fi
}

function dw_parse_rydnrRootFolder_cli_flag() {
  export RYDNR_ROOT_FOLDER="${1}"
}

function dw_check_acmslRootFfolder_cli_flag() {
  if ! fileExists "${ACMSL_ROOT_FOLDER}"; then
    exitWithErrorCode ACMSL_ROOT_FOLDER_DOES_NOT_EXIST "${ACMSL_ROOT_FOLDER}"
  fi
}

function dw_parse_acmslRootFolder_cli_flag() {
  export ACMSL_ROOT_FOLDER="${1}"
}
# vim: syntax=sh ts=2 sw=2 sts=4 sr noet
