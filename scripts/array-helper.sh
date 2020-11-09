#!/bin/bash

##############################################################
# 说明：Array 通用函数方法
##############################################################

# 函数功能：取两个数据的差集（相对补集）
# 输入参数：
#         targetArray - 被减数组
#         removeArray - 减数
# 返回值：
#         0 表示成功
#         1 表示失败
function differenceArray() {
  local targetArray
  local removeArray
  local item

  targetArray=($1)
  removeArray=($2)

  for item in ${targetArray[@]}; do
    if [[ ! " ${removeArray[*]} " =~ " ${item} " ]]; then
      echo $item
    fi
  done

  return 0
}
