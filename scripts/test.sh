#!/bin/bash

cd $(dirname $0)/..

current_branch=`git branch --show-current`
echo "确定要发布当前分支 $current_branch 吗？（yes, no）"
read is_publish

if [[ $is_publish = "yes" ]]
then
  status_info=`git status 2>&1`
  if [[ $status_info =~ "working tree clean" ]]
  then
    echo "正在生成更新日志，升级版本号..."
    npm run release --skip.tag

    echo "将代码推至远程代码仓库"
    git push

    if [[ $current_branch != "master" ]]
    then
        echo "切至 master 分支"
        git checkout master

        echo "将刚才的分支合并至 master 分支"
        git merge $current_branch
    fi

    echo "请输入 tag 号"
    read new_tag

    echo "正在创建本地 tag $new_tag"
    git tag $new_tag

    echo "上传本地 tag 至 远程仓库"
    git push origin $new_tag
  else
    echo "请先提交完代码，才可发布当前分支。"
  fi
else
  echo "您取消了发布当前分支。"
fi
