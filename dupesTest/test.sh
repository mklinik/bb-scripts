#!/usr/bin/env bash
. ../dupesLib.sh
declare -A array
initNiceList "niceList dir" "java hs" array
if [ ${#array[@]} != 2 ]; then
    echo "Test failed"
    exit 1
fi
echo Success!
