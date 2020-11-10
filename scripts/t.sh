#!/bin/bash

function test() {
  echo "errrrr" >& 2
  return 1
}

test
