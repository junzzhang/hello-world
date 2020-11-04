
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

    for remoteBranch in ${allRemoteBranches[@]}; do
      # 检查是否是 HEAD 指针
      if [ $remoteBranch != $remoteBranchNamePrefix'HEAD' ]
      then
        localBranchName=${remoteBranch:${#remoteBranchNamePrefix}}

        # 只处理 开发分支 develop/ 开头、测试分支 release/ 开头、hotfix分支 hotfix/ 开头
        if [ ${localBranchName:0:8} = "develop/" -o ${localBranchName:0:8} = "release/" -o ${localBranchName:0:7} = "hotfix/" ]; then

            mergeIntoFromMaster $remoteBranch $localBranchName $allLocalBranches
            if [ $? == 0 ]; then
                successBranches[${#successBranches[*]}]=$$localBranchName
            else
                echo "稍后请手动将 master 代码合并至分支 ${localBranchName}"
                failBranches[${#failBranches[*]}]=$$localBranchName
            fi

        fi
      fi
    done

    echo "合并成功的分支有 ${#successBranches[*]} 个，如下所示："
    for name in $successBranches[*]; do
      echo $name
    done

    # 打印分格
    echo "----------------"

    echo "合并失败的分支有 ${#failBranches[*]} 个，如下所示："
    for name in $failBranches[*]; do
      echo $name
    done
}

