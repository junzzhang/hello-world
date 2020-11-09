#!/bin/bash

source ./scripts/array-helper.sh
source ./scripts/git-helper.sh

current_branch="release/5.13.1.10"
preMergeBranches=($(select_branches_for_merge "${current_branch}"))

echo ${preMergeBranches[@]}
