#!/bin/bash

##############################################################
# 说明：本脚用于上线后的代码合打tag及回合代码至指定开发、测试及hotfix分支
# 功能：
#    1. 生成 Change logs
#    2. 归档合并 ：release 分支代码 合并至 Master 分支
#    3. 打 tag  ：在 Master 上打指定产品版本号的 tag
#    4. 回合代码 ：Master 分支回合至 指定的开发、测试及 hotfix 分支
##############################################################

source ./scripts/release/array-utils.copy.sh
source ./scripts/release/git-utils.sh

function release_main() {
  local current_branch
  local is_publish
  local isClean
  local new_tag
  local preMergeBranches
  local mergeSuccessBranches
  local mergeFailBranches
  local name

  current_branch=`git branch --show-current 2>&1`
  is_publish=""

  while [[ $is_publish != "yes" && $is_publish != "no" ]]; do
    read -p "确定要发布当前分支 $current_branch 吗？（yes, no）：" is_publish
  done

  if [[ $is_publish = "no" ]]; then
    echo -e "\n\033[31m 发布失败：您取消了发布当前分支。 \033[0m\n"
    return 1
  fi

  isClean=$(isCurrentBranchClean)
  if [[ $? -ne 0 || $isClean == false ]]; then
    echo -e "\n\033[31m 发布失败：请确保当前分支是干净的并且与远程代码同步，才可发布当前分支。 \033[0m\n"
    return 1
  fi

  new_tag=""
  while [[ -z $new_tag ]]; do
    read -p "请输入 tag 号：" new_tag
  done

  # 选择要回合的分支（将 master 代码合并至所有开发及测试分支）
  preMergeBranches=($(select_branches_for_merge "${current_branch}"))
  if [[ $? -ne 0 ]]; then
    echo -e "\n\033[31m 回合分支选择异常，请重新发布。 \033[0m\n"
    return 1
  fi

  echo "更新远程仓库状态..."
  git pull
  if [[ $? -ne 0 ]]; then
    echo -e "\n\033[31m 发布失败：当前分支 $current_branch 更新失败，请手动处理完冲突，再重新发布。 \033[0m\n"
    return 1
  fi

  echo "正在升级版本号，生成更新日志 CHANGELOG.md ..."
  standard-version --skip.tag

  if [[ $? -ne 0 ]]; then
    echo -e "\n\033[31m 发布失败：升级版本号，生成更新日志失败，解决完此问题，可重新发布。 \033[0m\n"
    return 1
  fi

  if [[ $current_branch != "master" ]]
  then
    echo "将当前分支 $current_branch 代码推至远程代码仓库..."
    git push

    if [[ $? -ne 0 ]]; then
      echo -e "\n\033[31m 发布失败：当前分支 $current_branch 代码没有成功推入远程仓库，接下来你最好手动进行发版操作。 \033[0m\n"
      return 1
    fi

    # 将当前分支 合并至 master 分支
    mergeFrom "master" $current_branch

    if [[ $? -ne 0 ]]; then
      echo -e "\n\033[31m 发布失败：分支 $current_branch 代码没有成功合并入 master 分支，接下来你最好手动进行发版操作。 \033[0m\n"
      return 1
    fi
  fi

  echo "正在创建本地 tag $new_tag"
  # git tag -a $new_tag -m $new_tag
  # 下面一行省略了 -m $new_tag，则强制弹出 tag 备注信息输入文本框
  git tag -a $new_tag

  echo "将代码推至远程代码仓库"
  git push --follow-tags origin master

  if [[ $? -ne 0 ]]; then
    echo -e "\n\033[31m 发布失败：分支 master 代码没有成功推到远程仓库，接下来你最好手动进行发版操作。 \033[0m\n"
    return 1
  fi

  if [[ $current_branch != 'master' ]]; then
      removeRemoteBranch $current_branch
      if [[ $? -ne 0 ]]; then
        echo -e "\033[31m 远程分支 $current_branch 删除失败，稍后请稍后手动删除。 \033[0m"
      fi
      removeLocalBranch $current_branch
      if [[ $? -ne 0 ]]; then
        echo -e "\033[31m 本地分支 $current_branch 删除失败，稍后请稍后手动删除。 \033[0m"
      fi
  fi

  echo -e "正在回合代码..."

  mergeSuccessBranches=($(mergeFromMaster "${preMergeBranches[*]}"))
  echo -e "\n\033[32m 合并成功的分支有 ${#mergeSuccessBranches[*]} 个，如下所示： \033[0m\n"
  name=""
  for name in ${mergeSuccessBranches[*]}; do
    echo -e "\033[32m $name \033[0m"
  done

  mergeFailBranches=($(differenceArray "${preMergeBranches[*]}" "${mergeSuccessBranches[*]}"))
  if [[ ${#mergeFailBranches[*]} -gt 0 ]]; then
    echo -e "\n\033[31m 合并失败的分支有 ${#mergeFailBranches[*]} 个，如下所示： \033[0m\n"
    for name in ${mergeFailBranches[*]}; do
      echo -e "\033[31m $name \033[0m"
    done

    echo -e "\n\033[31m 发布完成，请将合并失败的分支进行手动合并操作。 \033[0m\n"
    return 1
  fi

  echo -e "\n\033[32m 发布完成 \033[0m\n"
}

# 转到工作目录，git 根目录
cd $(dirname $0)/../..

# 执行发版操作
release_main

exit 0
