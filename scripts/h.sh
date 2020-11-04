#!/bin/bash

function xixi() {
    arr=$1;

    echo "${arr[@]}"
}

allLocalBranches=$(git branch --format='%(refname:short)')

echo "${allLocalBranches[*]}"
xixi "${allLocalBranches[@]}"

