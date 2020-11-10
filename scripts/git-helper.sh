#!/bin/bash

##############################################################
# 说明：git 协助命令
##############################################################

source ./scripts/git-utils.sh

if [[ $# -gt 0 ]]; then
  case $1 in
      --current-branch)
        getCurrentBranch
        ;;
      --enable-merge-back-branches)
        getAllEnableMergeBackBranches "$2"
        ;;
      --is-current-branch-clean)
        isCurrentBranchClean
        ;;
      --pull-current-branch)
        pullCurrentBranch
        ;;
      --push-current-branch)
        pushCurrentBranch
        ;;
      --merge-from)
        mergeFrom $1 $2 $3
        ;;
      --standard-version)
        standardVersion
        ;;
  esac
fi
