#!/bin/bash


function func() {
  return 0
}

info=$(func)
echo $?
