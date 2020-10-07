#!/usr/bin/env bash

MYDIR="${0%/*}"
. $MYDIR/loadConfig.sh
. $MYDIR/dupesLib.sh
if [ -z "$*" ]; then
        echo usage: dupes.sh dir >& 2
        exit
fi

if [ ! -d "$1" ]; then
        fingerprint "$1"
        exit
fi

# the fingerprints of all student submissions
declare -A fingerprints

# the fingerprints of the nicelisted files
declare -A nicelist

# for now, exit if plagiarism nicelist directory does not exist
test -e "$NICELISTDIR" || { echo "plagiarism nicelist does not exist"; exit 1; }

echo Dupechecking
initNiceList "$NICELISTDIR" "$niceListFileExts" nicelist
for arg in "$@"; do
    while read -r -d $'\0' file; do
        code=`fingerprint "$file"`
        # only if length of fingerprint exceeds a certain size, and the file is not nicelisted
        if [ "${#code}" -ge 42 ] && [ -z "${nicelist[$code]}" ]; then
            found="${fingerprints[$code]}"
            if [ -z "$found" ]; then
                fingerprints[$code]="$file"
            elif [ "${found%%/*}" = "${file%%/*}" ]; then
                # not a duplicate, because it is from the same hand-in
                true
            else
                echo 1>&2 "$file ?= $found"
                echo "[$found | `author "$found"`] <==> [$file | `author "$file"`]" > "${file}.WARNING"
                $DIFF "$found" "$file" | cvt >> "${file}.WARNING"
                echo "" >> "${file}.WARNING"

                test -e "${found}.WARNING" && echo "===========================================" >> "${found}.WARNING"
                echo "[$file | `author "$file"`] <==> [$found | `author "$found"`]" >> "${found}.WARNING"
                $DIFF "$file" "$found" | cvt >> "${found}.WARNING"
                echo "" >> "${found}.WARNING"
            fi
        fi
    done < <(eval $(buildFindString "$arg" "$niceListFileExts"))
done

