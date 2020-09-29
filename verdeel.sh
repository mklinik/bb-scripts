#!/usr/bin/env bash

# TODO: 
# - distribution of csv files to TA's is not currently handled
#   what is blocking: figure out the best way to enter grades
# - groepcheck is disabled
#   what is blocking: figure out the best way to handle grades/feedback in bs
#   for the user(s) that did not submit the original file
# - assigning students to fixed TA's
#   what is blocking: figure out how to use group info provided by BrightSpace
# ---------------------- configuratie ------------------------#

if [! -f config.sh]; then
    echo "Expecting configuration in config.sh. Refer to the template file config_template.sh"
    exit 1
fi
# This will input/source the contents of the config.sh file, which
# will not be tracked by git.

. config.sh

# ---------------------- end of config -----------------------#

# this script takes care of the distribution of workload over
# all the teaching assistants, after downloading the zip

for cmd in 7za mutt; do
        if ! command -v $cmd >/dev/null 2>&1; then
                echo "Who am I? Why am I here? Am I on lilo? $cmd is missing!" >& 2
                exit 1
        fi
done

shopt -s nullglob
set -e

MYDIR="${0%/*}"
PATH="${PATH}:${MYDIR}"

# first check whether the working dir is clean
for ta in "${!email[@]}"; do
        if [ -d "$ta" ]; then
                echo $ta exists. Clean up first.
                exit
        fi
done

# ----- from this point on everything is automatic -----#

echo Trying to adjust for student creativity.
"$MYDIR"/antifmt.sh */

echo
echo Doing a rough plagiarism check
"$MYDIR"/dupes.sh */ || exit 1

echo

test "${!email[*]}"
declare -A ballot

# since identify.sh identified groups: see if these match the names of TA's
# and move assignments there...
for ta in "${!email[@]}"; do
    mkdir -p ".$ta"
    progbar=""
    for file in */"#group:$ta"; do
        echo -n "Distributing assigned workload to $ta: `echo $progbar | wc -c`" $'\r'
        progbar="$progbar#"
        rm -f "$file"
        mv "${file%#group:$ta}" -t ".$ta"
    done
    if [ "$progbar" ]; then
	    echo
    else
	    ballot["$ta"]=".$ta" # TA did not get any, so it will participate in the lottery
    fi
done

unveil_ta() {
    for ta in "${!email[@]}"; do mv ".$ta" "$ta"; done
}

dirs=(*/)
echo Randomly distributing unassigned workload  "(${#dirs[@]})"
if [ "${#ballot[@]}" -gt 0 ]; then
    "$MYDIR"/hak3.sh "${ballot[@]}"
    unveil_ta
else
    #fallback: if all TA's are assigned to groups, then all of them are also in the lottery
    unveil_ta
    "$MYDIR"/hak3.sh "${!email[@]}"
fi
