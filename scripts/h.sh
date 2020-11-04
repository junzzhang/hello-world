#!/bin/bash

function xixi() {
    remoteBranch=$1
    localBranchName=$2
    allLocalBranches=$3

    echo "remoteBranch: $remoteBranch"
    echo "localBranchName: $localBranchName"
    echo "allLocalBranches: ${allLocalBranches[@]}"

    # 检测是否存在与远程分支对应的本地分支，不存在就拉下来
    if [[ ! " ${allLocalBranches[@]} " =~ " ${localBranchName} " ]]
    then

        echo "迁出远程分支 ${remoteBranch}...${localBranchName}"


    else

        echo "切到分支 ${localBranchName}..."

    fi
}

allLocalBranches=($(git branch --format='%(refname:short)'))
xixi "origin/release/2.0.0" "release/2.0.0" ${allLocalBranches[@]}

