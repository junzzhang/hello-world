function margeAndPushLocalBranch() {
  result=1

  git push
  echo "xixi = $?"
  return $result
}

margeAndPushLocalBranch
echo "haha = $?"
