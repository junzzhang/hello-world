#!/bin/bash

##############################################################
# 说明：本脚用于上线后的代码合打tag及回合代码至指定开发、测试及hotfix分支
# 功能：
#    1. 生成 Change logs
#    2. 归档合并 ：release 分支代码 合并至 Master 分支
#    3. 打 tag  ：在 Master 上打指定产品版本号的 tag
#    4. 回合代码 ：Master 分支回合至 指定的开发、测试及 hotfix 分支
##############################################################

source ./scripts/array-utils.sh
source ./scripts/git-utils.sh

function release_main() {
  local current_branch
  local new_tag
  local new_tag_message
  local preMergeBranches
  local mergeSuccessBranches
  local mergeFailBranches
  local name

  current_branch=$1
  new_tag=$2
  new_tag_message=$3
  preMergeBranches=($4)



  echo "正在创建本地 tag $new_tag"
  # git tag -a $new_tag -m $new_tag
  # 下面一行省略了 -m $new_tag，则强制弹出 tag 备注信息输入文本框
  git tag -a $new_tag -m "${new_tag_message}"

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
cd $(dirname $0)/..

# 执行发版操作
release_main $1 $2 "$3" "$4"

exit 0
