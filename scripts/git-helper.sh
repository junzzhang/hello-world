#!/bin/bash

##############################################################
# 说明：git 操作工具函数方法
##############################################################


# 函数功能：检测当前分支是否与远程仓库同步，没做过任何改动
# 返回值：
#         0 表示成功
#         1 表示失败
function isCurrentBranchClean() {
  local statusInfo=`git status -s -b`
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  local arrStatusInfo=(${statusInfo//\#/''})

  if [[ ${#arrStatusInfo[@]} -eq 1 ]]; then
    echo true
  fi

  echo false
  return 0
}

# 函数功能：检测当前分支是否需要更新远程仓库代码
# 返回值：
#         0 表示成功
#         1 表示失败
function isCurrentBranchBehindOrigin() {
  local statusInfo=`git status -s -b`
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  if [[ -z $(echo "red greed behind  12" | grep -E "\bbehind\b\s+\d+") ]]; then
    echo false
  fi

  echo true

  return 0
}

# 函数功能：检测当前分支是否有已 commit 且 push 的代码
# 返回值：
#         0 表示成功
#         1 表示失败
function isCurrentBranchAheadOfOrigin() {
  local statusInfo=`git status -s -b`
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  if [[ -z $(echo "red greed behind  12" | grep -E "\bahead\b\s+\d+") ]]; then
    echo false
  fi

  echo true

  return 0
}

# 函数功能：检测是否是当前分支
# 输入参数：
#         targetBranch - 要检测的分支名称
# 返回值：
#         0 表示成功
#         1 表示失败
function isCurrentBranch() {
  # 读取参数
  local targetBranch=$1

  # 获取当前分支
  local current_branch=`git branch --show-current 2>&1`

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

# 函数功能：检测是否存在指定的分支
# 输入参数：
#         targetBranch - 要检测的分支名称
# 返回值：
#         0 表示成功
#         1 表示失败
function existsBranch() {
  # 读取参数
  local targetBranch=$1

  # 检索想要签出的本地分支
  local targetBranchSearchResult=$(git branch -a --list ${targetBranch})
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
    # 读取参数
    local targetBranch=$1
    local isPullFromOrigin=$1

    # 检测目标本地分支是否存在
    local existsTargetBranch=$(existsBranch $targetBranch)
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
    local isCurrent=$(isCurrentBranch $targetBranch)
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

    local isBehind=$(isCurrentBranchBehindOrigin)
    if [[ $? -ne 0 ]]; then
      return 1
    fi
    if [[ $isBehind == true ]]; then
      # 同步远程仓库...
      git pull

      if [[ $? -ne 0 ]]; then
        git reset --hard HEAD --
        if [[ $? -ne 0 ]]; then
          return 2
        fi

        return 1
      fi
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
function margeFrom() {
  # 目标分支
  local targetBranch=$1
  # 来源分支
  local fromBranch=$2
  # 合并后是否执行 push 操作，默认值为 false
  local isPushToOrigin=$3

  local result

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
  git merge --no-edit $fromBranch

  result=$?
  if [[ $result -ne 0 ]]; then
    echo -e "\033[31m 将分支 ${fromBranch} 合并至分支 ${targetBranch} 失败，取消合并操作... \033[0m"
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

# 函数功能：删除本地分支
# 输入参数：
#         targetBranch - 目标分支
# 返回值：
#         0 表示成功
function removeLocalBranch() {
    local targetBranch=$1

    local existsBranch=$(existsBranch $targetBranch)
    if [[ $? -ne 0 ]]; then
      return 1
    fi

    if [[ existsBranch == false ]]; then
      return 0
    fi

    # "删除本地分支 $targetBranch"
    git branch -d $targetBranch

    return $?
}

# 函数功能：删除远程分支
# 输入参数：
#         targetBranch - 目标远程分支的本地分支名称
# 返回值：
#         0 表示成功
function removeRemoteBranch() {
    local targetBranch=$1

    local existsBranch=$(existsBranch origin/$targetBranch)
    if [[ $? -ne 0 ]]; then
      return 1
    fi

    if [[ existsBranch == false ]]; then
      return 0
    fi

    # "删除远程分支 $targetBranch"
    git push origin --delete $targetBranch

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
    local targetBranch=$1

    removeRemoteBranch targetBranch
    local deleteRemoteResult=$?

    removeLocalBranch targetBranch
    local deleteLocalResult=$?

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
