#!/bin/bash

cd $(dirname $0)/..

status_info=`git status 2>&1`
if [[ $status_info =~ "working tree clean" && $status_info =~ "Your branch is up to date with" ]]
then
    current_branch=`git branch --show-current`
    echo "确定要发布当前分支 $current_branch 吗？（yes, no）"
    read is_publish

    if [[ $is_publish = "yes" ]]
    then
          status_info=`git status 2>&1`
          
          echo "正在升级版本号，生成更新日志 CHANGELOG.md ..."
          npm run release --skip.tag

          if [[ $current_branch != "master" ]]
          then
              echo "将当前分支 $current_branch 代码推至远程代码仓库..."
              git push

              echo "切至 master 分支"
              git checkout master

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

          echo "发布完成。"
    else
        echo "您取消了发布当前分支。"
    fi
else
    echo "请确保当前分支是干净的并且与远程代码同步，才可发布当前分支。"
fi
