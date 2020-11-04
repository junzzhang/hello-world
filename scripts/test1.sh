
# 将 master 代码合并至 指定分支；return 0 表示成功，return 1 表示失败
function mergeIntoFromMaster() {
    remoteBranch=$1
    localBranchName=$2
    allLocalBranches=$3

    # 检测是否存在与远程分支对应的本地分支，不存在就拉下来
    if [[ ! " ${allLocalBranches[@]} " =~ " ${localBranchName} " ]]
    then

        echo "迁出远程分支 ${remoteBranch}..."
        git branch --no-track $localBranchName refs/remotes/${remoteBranch}
        if [[ $? -eq 0 ]]; then
          git branch --set-upstream-to=$remoteBranch
        fi
        echo "切到分支 ${localBranchName}..."
        git checkout $localBranchName

    else

        echo "切到分支 ${localBranchName}..."
        git checkout $localBranchName
        echo "同步远程仓库..."
        git pull

    fi

    echo "将 master 代码合并至分支 ${localBranchName}..."
    merge_info=`git merge master 2>&1`

    if [[ $merge_info =~ "Automatic merge failed" ]]
    then
        echo "分支 ${localBranchName} 代码合并失败，取消合并操作..."
        git reset --hard HEAD --

        return 1
    else
        echo "将分支 $localBranchName 合过来的 commit 推荐至远程仓库..."
        git push

        return 0
    fi
}

# 将 master 代码合并至 开发分支、测试分支、hotfix分支
function mergeIntoBranchesFromMaster() {
    echo "将 master 代码合并至所有开发及测试分支"
    remoteBranchNamePrefix='origin/'
    allRemoteBranches=$(git branch --remotes --format='%(refname:short)')
    allLocalBranches=($(git branch --format='%(refname:short)'))

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
                    mergeIntoFromMaster $remoteBranch $localBranchName ${allLocalBranches[@]}
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

    if [ ${#otherBranches[*]} -gt 0 ]; then
        # 打印分格
        echo "----------------"

        echo "没有执行合并操作的分支有 ${#otherBranches[*]} 个，如下所示："
        for name in ${otherBranches[*]}; do
          echo $name
        done

        return 1
    fi

    if [ ${#failBranches[*]} -gt 0 ]; then
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

mergeIntoBranchesFromMaster
