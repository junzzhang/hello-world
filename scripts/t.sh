#!/bin/bash

echo length = $#
for name in $@; do
  echo -e $name
done
