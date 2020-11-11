#!/bin/bash

##############################################################
# 说明：本脚用于上线后的代码合打tag及回合代码至指定开发、测试及hotfix分支
# 功能：
#    1. 生成 Change logs
#    2. 归档合并 ：release 分支代码 合并至 Master 分支
#    3. 打 tag  ：在 Master 上打指定产品版本号的 tag
#    4. 回合代码 ：Master 分支回合至 指定的开发、测试及 hotfix 分支
##############################################################

source ./scripts/release/array-utils.sh
source ./scripts/release/git-utils.sh

function release_main() {
  local preMergeBranches
  local mergeSuccessBranches
  local mergeFailBranches
  local name

  preMergeBranches=($1)

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
release_main "$1"

exit 0
