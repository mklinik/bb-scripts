#!/usr/bin/env bash

MYDIR="${0%/*}"
DIFF="diff --ignore-all-space --minimal --side-by-side --width=160 --left-column"

# All nicelisted files should be in this directory, one level up of the current working directory.
# It should not be in the CWD to not be confused with a student submission.
# It is okay if this directory does not exist, the nicelist feature is then not used.
NICELISTDIR="../plagiarism-nicelist"

author() {
    echo "${1%%/*}"
}

cvt() {
    #iconv -f windows-1252 | col
    tr -c '[:print:][:cntrl:]' '?' | col
}

remove_comments() {
    tr -cd '[:print:][:cntrl:]' | sed -rn ':0 N;${s:/\*([^*]|\*[^/])*\*/: :g;p};b0' | sed 's://.*$::'
}

collapse_string_constants() {
    #sed 's/""//g;s/"[^"]\+"/"/g'
    #sed 's/"[^"]*"//g'
    sed "s/'.'/'/g"';s/"\(\\.\|[^"]\)*"/"/g'
}

fingerprint() {
    echo -n 0
    cat "$1" | remove_comments | collapse_string_constants | sed 's/[><=]=/<>/g;s/</>/g;s/\(package\|import\) [A-Za-z0-9_.]\+;//g;s/return/!!/g;s/public/$/g;s/class/#/g;s/private/$/g;s/final//g;s/\(if\|switch\)/?/g;s/\(for\|while\)/?/g;s/\<[A-Z][A-Za-z0-9_]*\>/I/g;s/\<[a-z][A-Za-z0-9_]\+\>/i/g;s/[0-9]\+/i/g' | tr -cd '5!?iI#<>\n:~*$\\[]{}()"' | tr ' \t\n\\"' 'abcde' | sed -r 's/c+/c/g;s/c$//'
}

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

# enable recursive globbing **/*.java
shopt -s globstar

# for now, exit if plagiarism nicelist directory does not exist
test -e "$NICELISTDIR" || { echo "plagiarism nicelist does not exist"; exit 1; }

for file in "$NICELISTDIR"/**/*; do
    # if there are no nicelisted files we get the glob expression, because shell programming
    # also we glob directories, which we also want to avoid checking
    test -f "$file" || break
    nicelist[`fingerprint "$file"`]="$file"
done

echo Dupechecking
for arg in "$@"; do
    for file in "$arg"/**/*; do
	#check we are indeed dealing with a file and it is not an archive contents list
        test -f "$file" && [ "${file: -9}" != ".contents" ] || continue
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
    done
done

