#!/bin/bash

source ./scripts/array-helper.sh

targetArray=(1 2 3 4 5 6)
removeArray=(2 5)

newArr=($(differenceArray "${targetArray[*]}" "${removeArray[*]}"))

echo ${newArr[*]}
