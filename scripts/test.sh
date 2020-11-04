#!/bin/bash

function checkoutAndPullLocalBranch() {
    localBranch=$1
    allLocalBranches=($(git branch --format='%(refname:short)'))

    # 检测是否存在与远程分支对应的本地分支，不存在就拉下来
    if [[ ! " ${allLocalBranches[@]} " =~ " ${localBranch} " ]]
    then

        echo "迁出远程分支 origin/${localBranch}..."
        git branch --no-track $localBranch refs/remotes/origin/${localBranch}
        if [[ $? -eq 0 ]]; then
          git branch --set-upstream-to="origin/${localBranch}" $localBranch
        fi
        echo "切到分支 ${localBranch}..."
        git checkout $localBranch
        return $?
    else

        echo "切到分支 ${localBranch}..."
        git checkout $localBranch

        if [[ $? -eq 0 ]]; then
          echo "同步远程仓库..."
          git pull
          return $?
        fi

        return $?
    fi
}

# 将源分支合并至目的分支: 返回值为 0 表示成功，否则表示 失败
# 1. 保证源本地分支必须存在 2. 只做 merge ，不做 push
function margeLocalBranch() {
    # 源分支
    fromBranch=$1
    # 目的分支
    destBranch=$2

    checkoutAndPullLocalBranch $destBranch

    if [[ $? -eq 0 ]]; then
        echo "将分支 ${fromBranch} 合并至 ${destBranch} 分支"
        git merge $fromBranch

        result=$?
        if [[ $result -ne 0 ]]; then
            echo -e "\033[31m 将分支 ${fromBranch} 合并至分支 ${destBranch} 失败，取消合并操作... \033[0m"
            git reset --hard HEAD --
        fi

        return $result
    fi

    return 1
}

function margeAndPushLocalBranch() {
  margeLocalBranch $1 $2
  result=$?

  git push

  return $result
}

# 删除本地及远程分支
function removeLocalBranch() {
    deleteBranch=$1

    echo "删除远程分支 $deleteBranch"
    git push origin --delete $deleteBranch

    if [[ $? -ne 0 ]]; then
        echo -e "\033[31m 远程分支 $deleteBranch 删除失败，请稍后手动删除。 \033[0m"
    fi

    echo "删除本地分支 $deleteBranch"
    git branch -d $deleteBranch

    if [[ $? -ne 0 ]]; then
        echo -e "\033[31m 本地分支 $deleteBranch 删除失败，请稍后手动删除。 \033[0m"
        return $?
    fi
    return 0
}

# 将 master 代码合并至 开发分支、测试分支、hotfix分支
function mergeIntoBranchesFromMaster() {
    echo "将 master 代码合并至所有开发及测试分支"
    remoteBranchNamePrefix='origin/'
    allRemoteBranches=$(git branch --remotes --format='%(refname:short)')

    successBranches=()
    failBranches=()
    otherBranches=()

    for remoteBranch in ${allRemoteBranches[@]}; do
        # 检查是否是 HEAD 指针
        if [ $remoteBranch != $remoteBranchNamePrefix'HEAD' ]
        then
            localBranchName=${remoteBranch:${#remoteBranchNamePrefix}}

            # 只处理 开发分支 develop/ 开头、测试分支 release/ 开头、hotfix分支 hotfix/ 开头
            if [ ${localBranchName:0:8} = "develop/" -o ${localBranchName:0:8} = "release/" -o ${localBranchName:0:7} = "hotfix/" ]; then
                echo "是否将 master 的最新代码合并至分支 $localBranchName ？（yes, no）"
                read needMerge

                if [[ $needMerge = "yes" ]]; then
                    margeAndPushLocalBranch master $localBranchName
                    echo "xixi = \"$?\""
                    if [[ $? -eq 0 ]]; then
                        successBranches[${#successBranches[*]}]=$localBranchName
                    else
                        echo -e "\033[31m 稍后请手动将 master 代码合并至分支 ${localBranchName} \033[0m"
                        failBranches[${#failBranches[*]}]=$localBranchName
                    fi
                else
                    otherBranches[${#otherBranches[*]}]=$localBranchName
                fi
            else
                otherBranches[${#otherBranches[*]}]=$localBranchName
            fi
        fi
    done

    echo -e "\n\033[32m 合并成功的分支有 ${#successBranches[*]} 个，如下所示： \033[0m\n"
    for name in ${successBranches[*]}; do
      echo -e "\033[32m $name \033[0m"
    done

    if [ ${#otherBranches[*]} -gt 0 ]; then
        # 打印分格
        echo -e "\n ----------------\n"
        echo -e "没有执行合并操作的分支有 ${#otherBranches[*]} 个，如下所示：\n"
        for name in ${otherBranches[*]}; do
          echo $name
        done
    fi

    if [ ${#failBranches[*]} -gt 0 ]; then
        # 打印分格
        echo -e "\n ----------------\n"

        echo -e "\033[31m 合并失败的分支有 ${#failBranches[*]} 个，如下所示： \033[0m\n"
        for name in ${failBranches[*]}; do
          echo -e "\033[31m $name \033[0m"
        done

        return 1
    fi

    return 0
}



cd $(dirname $0)/..

echo "同步远程仓库..."
git pull

status_info=`git status 2>&1`
if [[ $status_info =~ "working tree clean" && $status_info =~ "Your branch is up to date with" ]]
then
    current_branch=`git branch --show-current 2>&1`
    echo "确定要发布当前分支 $current_branch 吗？（yes, no）"
    read is_publish

    if [[ $is_publish = "yes" ]]
    then
        echo "正在升级版本号，生成更新日志 CHANGELOG.md ..."
        npm run release --skip.tag

        # 0 表示成功
        mergeSuccess=0
        if [[ $current_branch != "master" ]]
        then
            echo "将当前分支 $current_branch 代码推至远程代码仓库..."
            git push

            # 将当前分支 合并至 master 分支
            margeLocalBranch $current_branch "master"
            mergeSuccess=$?
        fi

        if [[ $mergeSuccess -eq 0 ]]; then
            echo "请输入 tag 号"
            read new_tag

            echo "正在创建本地 tag $new_tag"
            git tag -a $new_tag -m $new_tag

            echo "将代码推至远程代码仓库"
            git push --follow-tags origin master

            if [[ $current_branch != 'master' ]]; then
                removeLocalBranch $current_branch
            fi

            # 将 master 代码合并至所有开发及测试分支
            mergeIntoBranchesFromMaster

            if [[ $? -eq 0 ]]; then
                echo -e "\n\033[32m 发布完成 \033[0m\n"
            else
                echo -e "\n\033[31m 发布完成，请将合并失败的分支进行手动合并操作。 \033[0m\n"
            fi
        else
            echo -e "\n\033[31m 发布失败：分支 $current_branch 代码没有成功合并入 master 分支，接下来你最好手动进行发版操作。 \033[0m\n"
        fi
    else
        echo -e "\n\033[31m 发布失败：您取消了发布当前分支。 \033[0m\n"
    fi
else
    echo -e "\n\033[31m 发布失败：请确保当前分支是干净的并且与远程代码同步，才可发布当前分支。 \033[0m\n"
fi
