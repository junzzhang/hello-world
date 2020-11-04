#!/bin/bash

# 将 master 代码合并至 指定分支；return 0 表示成功，return 1 表示失败
function mergeIntoFromMaster() {
    remoteBranch=$1
    localBranchName=$2
    allLocalBranches=$3

    # 检测是否存在与远程分支对应的本地分支，不存在就拉下来
    if [[ ! " ${allLocalBranches[@]} " =~ " ${localBranchName} " ]]
    then

        echo "迁出远程分支 ${remoteBranch}..."
        git branch --no-track $localBranchName refs/${remoteBranch}
        git branch --set-upstream-to=$remoteBranch
        echo "切到分支 ${localBranchName}..."
        git checkout $localBranchName

    else

        echo "切到分支 ${localBranchName}..."
        git checkout $localBranchName
        echo "同步远程仓库..."
        git pull

    fi

    echo "将 master 代码合并至分支 ${localBranchName}..."
    merge_info=`git merge master`

    if [ $merge_info =~ "Automatic merge failed" ]
    then
        echo "分支 ${localBranchName} 代码合并失败，取消合并操作..."
        git reset --hard HEAD --

        return 1

        # echo "稍后请手动将 master 代码合并至分支 ${localBranchName}"
        # failBranches[${#failBranches[*]}]=$$localBranchName
    else
        echo "将分支 $localBranchName 合过来的 commit 推荐至远程仓库..."
        git push

        return 0
        # successBranches[${#successBranches[*]}]=$$localBranchName
    fi
}

# 将 master 代码合并至 开发分支、测试分支、hotfix分支
function mergeIntoBranchesFromMaster() {
    echo "将 master 代码合并至所有开发及测试分支"
    remoteBranchNamePrefix='origin/'
    allRemoteBranches=$(git branch --remotes --format='%(refname:short)')
    allLocalBranches=$(git branch --format='%(refname:short)')

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

                if [ $needMerge = "yes" ]; then
                    mergeIntoFromMaster $remoteBranch $localBranchName $allLocalBranches
                    if [ $? == 0 ]; then
                        successBranches[${#successBranches[*]}]=$localBranchName
                    else
                        echo "稍后请手动将 master 代码合并至分支 ${localBranchName}"
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

    echo "合并成功的分支有 ${#successBranches[*]} 个，如下所示："
    for name in ${successBranches[*]}; do
      echo $name
    done

    if [ ${#otherBranches[*]} > 0 ]; then
        # 打印分格
        echo "----------------"

        echo "没有执行合并操作的分支有 ${#otherBranches[*]} 个，如下所示："
        for name in ${otherBranches[*]}; do
          echo $name
        done

        return 1
    fi

    if [ ${#failBranches[*]} > 0 ]; then
        # 打印分格
        echo "----------------"

        echo "合并失败的分支有 ${#failBranches[*]} 个，如下所示："
        for name in ${failBranches[*]}; do
          echo $name
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
    current_branch=`git branch --show-current`
    echo "确定要发布当前分支 $current_branch 吗？（yes, no）"
    read is_publish

    if [[ $is_publish = "yes" ]]
    then
          echo "正在升级版本号，生成更新日志 CHANGELOG.md ..."
          npm run release --skip.tag

          if [[ $current_branch != "master" ]]
          then
              echo "将当前分支 $current_branch 代码推至远程代码仓库..."
              git push

              echo "切至 master 分支"
              git checkout master

              echo "同步远程仓库..."
              git pull

              echo "将刚才的分支合并至 master 分支"
              git merge $current_branch
          fi

          echo "请输入 tag 号"
          read new_tag

          echo "正在创建本地 tag $new_tag"
          git tag -a $new_tag -m $new_tag

          echo "将代码推至远程代码仓库"
          git push --follow-tags origin master

          if [[ $current_branch != 'master' ]]
          then
              echo "删除远程分支 $current_branch"
              git push origin --delete $current_branch

              echo "删除本地分支 $current_branch"
              git branch -d $current_branch
          fi

          # 将 master 代码合并至所有开发及测试分支
          mergeIntoBranchesFromMaster

          if [ $? == 0 ]; then
            echo "发布完成。"
          else
            echo "发布完成，请将回并失败的支持进行手动合并操作。"
          fi
    else
        echo "您取消了发布当前分支。"
    fi
else
    echo "请确保当前分支是干净的并且与远程代码同步，才可发布当前分支。"
fi
