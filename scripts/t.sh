#!/bin/bash

function test() {
  echo $1
}

abc="abc1234\n8uj"

test abc<<eof
${abc}
asfsfdsfdf
sfsldjfsdlkf
eof
