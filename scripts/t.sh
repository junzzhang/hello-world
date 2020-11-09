#!/bin/bash


function func() {
  return 1
}

function func1() {
  local info

  info=`func`
  echo $?
}

func1
