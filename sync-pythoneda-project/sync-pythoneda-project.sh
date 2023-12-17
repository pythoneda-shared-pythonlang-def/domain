#!/usr/bin/env dry-wit
# Copyright 2023-today Automated Computing Machinery S.L.
# Distributed under the terms of the GNU General Public License v3

DW.import file;
DW.import nix-flake;
DW.import git;

# fun: main
# api: public
# txt: Main logic. Gets called by dry-wit.
# txt: Returns 0/TRUE always, but may exit due to errors.
# use: main
function main() {

  local -i _rescode;

  # from release_tag.sh -vv
  local -i _repositoryHasNoChanges=36;
  local -i _repositoryHasNoChangesInFlakeFiles=37;

  local -a _noChangesExitCodes=(${_repositoryHasNoChanges} ${_repositoryHasNoChangesInFlakeFiles});

  resolveVerbosity;
  local _commonArgs=(${RESULT});
  if ! isEmpty "${GITHUB_TOKEN}"; then
    _commonArgs+=("-t" "${GITHUB_TOKEN}");
  fi
  local _releaseTagArgs=("${_commonArgs[@]}" "-R" "${RELEASE_NAME}");
  if ! isEmpty "${COMMIT_MESSAGE}"; then
    _releaseTagArgs+=("-c" "${COMMIT_MESSAGE}");
  fi
  if ! isEmpty "${TAG_MESSAGE}"; then
    _releaseTagArgs+=("-m" "${TAG_MESSAGE}");
  fi
  if ! isEmpty "${GPG_KEY_ID}"; then
    _releaseTagArgs+=("-g" "${GPG_KEY_ID}");
  fi

  local _projectFolder="${PROJECT_FOLDER}";
  local _project="$(dirname ${_projectFolder}/$(basename ${_projectFolder}))";
  local _output;

  pushd "${_projectFolder}" >/dev/null 2>&1 || exitWithErrorCode PROJECT_FOLDER_DOES_NOT_EXIST "${_projectFolder}";
  # Updating the reference to the wrapped repository if needed
  createTempFile;
  local _updateSha256NixFlakeOutput="${RESULT}";
  "${UPDATE_SHA256_NIX_FLAKE}" "${_commonArgs[@]}" | tee "${_updateSha256NixFlakeOutput}";
  _rescode=$?;
  if isFalse ${_rescode}; then
    logInfo "Error updating the sha256 of in ${_projectFolder}";
    _output="$(<"${_updateSha256NixFlakeOutput}")";
    if ! isEmpty "${_output}"; then
      logDebug "${_output}";
    fi
  fi

  if isTrue ${_rescode}; then
    # updating inputs
    createTempFile;
    local _updateLatestInputsNixFlakeOutput="${RESULT}";
    "${UPDATE_LATEST_INPUTS_NIX_FLAKE}" "${_commonArgs[@]}" -f flake.nix -l flake.lock 2>&1 | tee "${_updateLatestInputsNixFlakeOutput}";
    _rescode=$?;
    _output="$(<"${_updateLatestInputsNixFlakeOutput}")";
    if ! isEmpty "${_output}"; then
      logDebug "${_output}";
    fi
  fi

  if isTrue ${_rescode}; then
    # releasing tag
    logInfo "Releasing a new version of ${_projectFolder}";
    createTempFile;
    local _releaseTagOutput="${RESULT}";
    "${RELEASE_TAG}" "${_releaseTagArgs[@]}" -r "${_projectFolder}" 2>&1 | tee "${_releaseTagOutput}";
    _rescode=$?;
    _output="$(<"${_releaseTagOutput}")";
    if ! isEmpty "${_output}"; then
      logDebug "${_output}";
    fi
    if arrayDoesNotContain ${_rescode} "${_noChangesExitCodes[@]}"; then
      exitWithErrorCode SKIPPED "${_projectFolder}";
    fi
  fi

  exit ${_rescode};
}

## Script metadata and CLI settings.
setScriptDescription "Synchronizes dependencies of a PythonEDA project";
setScriptLicenseSummary "Distributed under the terms of the GNU General Public License v3";
setScriptCopyright "Copyleft 2023-today Automated Computing Machinery S.L.";

DW.getScriptName
SCRIPT_NAME="${RESULT}"
addCommandLineFlag "projectFolder" "p" "The folder of a PythonEDA definition project" MANDATORY EXPECTS_ARGUMENT;
addCommandLineFlag "githubToken" "t" "The github token" OPTIONAL EXPECTS_ARGUMENT;
addCommandLineFlag "releaseName" "R" "The release name" MANDATORY EXPECTS_ARGUMENT;
addCommandLineFlag "gpgKeyId" "g" "The id of the GPG key" OPTIONAL EXPECTS_ARGUMENT;
addCommandLineFlag "commitMessage" "c" "The commit message" OPTIONAL EXPECTS_ARGUMENT "Commit created with ${SCRIPT_NAME}";
addCommandLineFlag "tagMessage" "m" "The tag message" OPTIONAL EXPECTS_ARGUMENT "Tag created with ${SCRIPT_NAME}";

checkReq jq;
checkReq sed;
checkReq grep;

## deps
export UPDATE_LATEST_INPUTS_NIX_FLAKE="__UPDATE_LATEST_INPUTS_NIX_FLAKE__";
if areEqual "${UPDATE_LATEST_INPUTS_NIX_FLAKE}" "__UPDATE_LATEST_INPUTS_NIX_FLAKE__"; then
  export UPDATE_LATEST_INPUTS_NIX_FLAKE="update-latest-inputs-nix-flake.sh";
fi
export RELEASE_TAG="__RELEASE_TAG__";
if areEqual "${RELEASE_TAG}" "__RELEASE_TAG__"; then
  export RELEASE_TAG="release-tag.sh";
fi
export UPDATE_SHA256_NIX_FLAKE="__UPDATE_SHA256_NIX_FLAKE__";
if areEqual "${UPDATE_SHA256_NIX_FLAKE}" "__UPDATE_SHA256_NIX_FLAKE__"; then
  export UPDATE_SHA256_NIX_FLAKE="update-sha256-nix-flake.sh";
fi

addError PROJECT_FOLDER_DOES_NOT_EXIST "Project folder does not exist:"
addError SKIPPED "Skipped project";

function dw_check_projectFolder_cli_flag() {
  if ! folderExists "${PROJECT_FOLDER}"; then
    exitWithErrorCode PROJECT_FOLDER_DOES_NOT_EXIST "${PROJECT_FOLDER}"
  fi
}
# vim: syntax=sh ts=2 sw=2 sts=4 sr noet
