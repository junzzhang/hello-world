#!/bin/bash

##############################################################
# 说明：git 操作工具函数方法
##############################################################


# 函数功能：获取当前分支
# 返回值：
#         0 表示成功
#         1 表示失败
function getCurrentBranch() {
  local current_branch

  current_branch=`git branch --show-current 2>&1`
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  echo $current_branch
  return 0
}

# 函数功能：拉取最新代码至工作区
# 返回值：
#         0 表示成功
#         1 表示失败
#         2 表示撤销 merge 失败
function pullCurrentBranch() {
  # 同步远程仓库...
  git pull

  if [[ $? -ne 0 ]]; then
    git reset --hard HEAD --
    if [[ $? -ne 0 ]]; then
      return 2
    fi

    return 1
  fi

  return 0
}

# 函数功能：推送当前分支
# 返回值：
#         0 表示成功
#         1 表示失败
function pushCurrentBranch() {
  # 同步远程仓库...
  git push

  if [[ $? -ne 0 ]]; then
    return 1
  fi

  return 0
}

# 函数功能：检测是否是当前分支
# 输入参数：
#         targetBranch - 要检测的分支名称
# 返回值：
#         0 表示成功
#         1 表示失败
function isCurrentBranch() {
  local targetBranch
  local current_branch

  # 读取参数
  targetBranch=$1

  # 获取当前分支
  current_branch=`git branch --show-current 2>&1`

  if [[ $? -ne 0 ]]; then
    return 1
  fi

  if [[ $current_branch = $targetBranch ]]; then
    echo true
  else
    echo false
  fi

  return 0
}

# 函数功能：检测当前分支是否与远程仓库同步，没做过任何改动
# 返回值：
#         0 表示成功
#         1 表示失败
function isCurrentBranchClean() {
  local statusInfo
  local arrStatusInfo

  statusInfo=`git status -s -b`
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  arrStatusInfo=(${statusInfo//\#/''})

  if [[ ${#arrStatusInfo[@]} -eq 1 ]]; then
    echo true
  else
    echo false
  fi

  return 0
}

# 函数功能：检测当前分支是否需要更新远程仓库代码
# 返回值：
#         0 表示成功
#         1 表示失败
function isCurrentBranchBehindOrigin() {
  local statusInfo

  statusInfo=`git status -s -b`
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  if [[ -z $(echo ${statusInfo} | grep -E "(落后|\bbehind\b)\s+\d+") ]]; then
    echo false
  else
    echo true
  fi

  return 0
}

# 函数功能：检测当前分支是否有已 commit 且 push 的代码
# 返回值：
#         0 表示成功
#         1 表示失败
function isCurrentBranchAheadOfOrigin() {
  local statusInfo

  statusInfo=`git status -s -b`
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  if [[ -z $(echo ${statusInfo} | grep -E "(领先|\bahead\b)\s+\d+") ]]; then
    echo false
  else
    echo true
  fi

  return 0
}

# 函数功能：检测是否存在指定的分支
# 输入参数：
#         targetBranch - 要检测的分支名称
# 返回值：
#         0 表示成功
#         1 表示失败
function existsBranch() {
  local targetBranch
  local targetBranchSearchResult

  # 读取参数
  targetBranch=$1

  # 检索想要签出的本地分支
  targetBranchSearchResult=$(git branch -a --list ${targetBranch})
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  if [[ -z $targetBranchSearchResult ]]; then
    echo false
  else
    echo true
  fi

  return 0
}

# 函数功能：签出本地分支并拉取最新代码至工作区
# 输入参数：
#         targetBranch - 想要签出的本地分支名称
#         isPullFromOrigin - 签出后是否执行 pull 操作，默认 true
# 返回值：
#         0 表示成功
#         1 表示失败
#         2 表示撤销 merge 失败
function checkoutBranch() {
    local targetBranch
    local isPullFromOrigin
    local existsTargetBranch
    local isCurrent
    local isBehind

    # 读取参数
    targetBranch=$1
    isPullFromOrigin=$1

    # 检测目标本地分支是否存在
    existsTargetBranch=$(existsBranch $targetBranch)
    if [[ $? -ne 0 ]]; then
      return 1
    fi

    # 不存在就拉下来
    if [[ $existsTargetBranch == false ]]; then

        # 签出远程分支 origin/${targetBranch}...
        git branch --no-track $targetBranch refs/remotes/origin/${targetBranch}
        # 检测远程分支是否签出成功，若没有成功则返回 1
        if [[ $? -ne 0 ]]; then
          return 1
        else
          # 设置本地分支跟踪的远程分支
          git branch --set-upstream-to="origin/${targetBranch}" $targetBranch

          # 检查跟踪分支是否设置成功，若没有成功则返回 1
          if [[ $? -ne 0 ]]; then
            return 1
          fi
        fi
        # 切到分支 ${targetBranch}...
        git checkout $targetBranch

        return $?
    fi

    # 检测是否已经是当前活动分支
    isCurrent=$(isCurrentBranch $targetBranch)
    if [[ $? -ne 0 ]]; then
      return 1
    fi
    if [[ $isCurrent == false ]]; then
      # 切到分支 ${targetBranch}...
      git checkout $targetBranch
      # 检测是否签出成功，若不成功则返回 1
      if [[ $result -ne 0 ]]; then
        return 1
      fi
    fi

    # 检测是否需要 pull 操作，若不需要则直接返回 0
    if [[ $isPullFromOrigin == false ]]; then
      return 0
    fi

    isBehind=$(isCurrentBranchBehindOrigin)
    if [[ $? -ne 0 ]]; then
      return 1
    fi
    if [[ $isBehind == true ]]; then
      pullCurrentBranch
      return $?
    fi

    return 0
}

# 函数功能：将源分支合并至目标分支
# 输入参数：
#         targetBranch - 目标分支
#         fromBranch - 来源分支
#         isPushToOrigin - 合并后是否执行 push 操作，默认值为 false
# 返回值：
#         0 表示成功
#         1 表示失败
#         2 表示撤销 merge 失败
function mergeFrom() {
  local targetBranch
  local fromBranch
  local isPushToOrigin
  local result

  # 目标分支
  targetBranch=$1
  # 来源分支
  fromBranch=$2
  # 合并后是否执行 push 操作，默认值为 false
  isPushToOrigin=$3

  # 签出源分支，并 pull
  checkoutBranch $fromBranch
  result=$?
  if [[ $result -ne 0 ]]; then
    return $result
  fi

  # 签出目标分支，并 pull
  checkoutBranch $targetBranch
  result=$?
  if [[ $result -ne 0 ]]; then
    return $result
  fi

  # 将分支 ${fromBranch} 合并至 ${targetBranch} 分支
  git merge --no-ff --no-edit $fromBranch

  result=$?
  if [[ $result -ne 0 ]]; then
    # echo -e "\033[31m 将分支 ${fromBranch} 合并至分支 ${targetBranch} 失败，取消合并操作... \033[0m"
    git reset --hard HEAD --
    if [[ $? -ne 0 ]]; then
      return 2
    fi

    return 1
  fi

  if [[ $isPushToOrigin == true ]]; then
    git push
    if [[ $? -ne 0 ]]; then
      return 1
    fi
  fi

  return 0
}

# 函数功能：将 master 分支合并至目标分支
# 输入参数：
#         targetBranches - 目标分支数组
# 返回值：
#         0 表示成功
#         1 表示失败
#         2 表示撤销 merge 失败
function mergeFromMaster() {
  local targetBranches
  local localBranchName
  local info
  local mergeResult

  targetBranches=($1)

  for localBranchName in ${targetBranches[@]}; do
    info=$(mergeFrom $localBranchName master true)
    mergeResult=$?
    if [[ $mergeResult -eq 0 ]]; then
      echo $localBranchName
    elif [[ $mergeResult -eq 2 ]]; then
      return $mergeResult
    fi
  done

  return 0
}

# 函数功能：删除本地分支
# 输入参数：
#         targetBranch - 目标分支
# 返回值：
#         0 表示成功
function removeLocalBranch() {
    local targetBranch
    local existsBranch
    local info

    targetBranch=$1

    existsBranch=$(existsBranch $targetBranch)
    if [[ $? -ne 0 ]]; then
      return 1
    fi

    if [[ existsBranch == false ]]; then
      return 0
    fi

    # "删除本地分支 $targetBranch"
    info=$(git branch -d $targetBranch)

    return $?
}

# 函数功能：删除远程分支
# 输入参数：
#         targetBranch - 目标远程分支的本地分支名称
# 返回值：
#         0 表示成功
function removeRemoteBranch() {
    local targetBranch
    local existsBranch
    local info

    targetBranch=$1
    existsBranch=$(existsBranch origin/$targetBranch)
    if [[ $? -ne 0 ]]; then
      return 1
    fi

    if [[ existsBranch == false ]]; then
      return 0
    fi

    # "删除远程分支 $targetBranch"
    info=$(git push origin --delete $targetBranch)

    return $?
}

# 函数功能：删除本地及远程分支
# 输入参数：
#         targetBranch - 目标分支
# 返回值：
#         0 表示成功
#         1 表示远程分支删除失败
#         2 表示本也分支删除失败
#         4 表示本地和远程分支都删除失败
function removeBranch() {
    local targetBranch
    local deleteRemoteResult
    local deleteLocalResult
    local info

    targetBranch=$1

    info=$(removeRemoteBranch targetBranch)
    deleteRemoteResult=$?

    info=$(removeLocalBranch targetBranch)
    deleteLocalResult=$?

    if [[ $deleteLocalResult == 1 && $deleteRemoteResult == 1 ]]; then
      return 4
    elif [[ $deleteRemoteResult == 1 ]]; then
      return 1
    elif [[ $deleteLocalResult == 1 ]]; then
      return 2
    else
      return 0
    fi
}

# 函数功能：获取所有可回合的分支列表
# 输入参数：
#         excludeArray - 不能被选上的分支列表
# 返回值：
#         0 表示成功
#         1 表示远程分支删除失败
function getAllEnableMergeBackBranches() {
    local excludeArray
    local remoteBranchNamePrefix
    local allRemoteBranches
    local remoteBranch
    local localBranchName

    excludeArray=($1)

    remoteBranchNamePrefix='origin/'
    allRemoteBranches=$(git branch --remotes --format='%(refname:short)')
    if [[ $? -ne 0 ]]; then
      return 1
    fi

    for remoteBranch in ${allRemoteBranches[@]}; do
        localBranchName=${remoteBranch:${#remoteBranchNamePrefix}}
        # 检查是否是 HEAD 指针
        if [[ $remoteBranch = $remoteBranchNamePrefix'HEAD' || " ${excludeArray[*]} " =~ " ${localBranchName} " ]]; then
          continue
        fi

        # 只处理 开发分支 develop/ 开头、测试分支 release/ 开头、hotfix分支 hotfix/ 开头
        if [ ${localBranchName:0:8} = "develop/" -o ${localBranchName:0:8} = "release/" -o ${localBranchName:0:7} = "hotfix/" ]; then
          echo $localBranchName
        fi
    done

    return 0
}

# 函数功能：选择要回合的分支
# 输入参数：
#         excludeArray - 不能被选上的分支列表
# 返回值：
#         0 表示成功
#         1 表示远程分支删除失败
function select_branches_for_merge() {
  local excludeArray
  local remoteBranchNamePrefix
  local allRemoteBranches
  local remoteBranch
  local localBranchName
  local needMerge

  excludeArray=($1)

  remoteBranchNamePrefix='origin/'
  allRemoteBranches=$(git branch --remotes --format='%(refname:short)')
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  for remoteBranch in ${allRemoteBranches[@]}; do
      localBranchName=${remoteBranch:${#remoteBranchNamePrefix}}
      # 检查是否是 HEAD 指针
      if [[ $remoteBranch = $remoteBranchNamePrefix'HEAD' || " ${excludeArray[*]} " =~ " ${localBranchName} " ]]; then
        continue
      fi

      # 只处理 开发分支 develop/ 开头、测试分支 release/ 开头、hotfix分支 hotfix/ 开头
      if [ ${localBranchName:0:8} = "develop/" -o ${localBranchName:0:8} = "release/" -o ${localBranchName:0:7} = "hotfix/" ]; then
        needMerge=""
        while [[ $needMerge != "yes" && $needMerge != "no" ]]; do
            read -p "是否将 master 的最新代码合并至分支 $localBranchName ？（yes, no）：" needMerge
        done

        if [[ $needMerge = "yes" ]]; then
          echo $localBranchName
        fi
      fi
  done

  return 0
}

function standardVersion() {
  npm run standard-version

  if [[ $? -ne 0 ]]; then
    return 1
  fi

  return 0
}
