#! /bin/bash

# TODO: 
# - distribution of csv files to TA's is not currently handled
#   what is blocking: figure out the best way to enter grades
# - groepcheck is disabled
#   what is blocking: figure out the best way to handle grades/feedback in bs
#   for the user(s) that did not submit the original file
# - assigning students to fixed TA's
#   what is blocking: figure out how to use group info provided by BrightSpace
# ---------------------- configuratie ------------------------#

typeset -A email
email[marc]="mschool@science.ru.nl"
#email[ko]="kstoffelen@science.ru.nl"
#email[pol]="paubel@science.ru.nl"

SUBJECT="`whoami` could not be bothered to configure SUBJECT"

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

if [ "$CSV" ]; then
        echo Identifying submissions
        "$MYDIR"/identify.sh "$CSV" */
fi

echo 
echo Trial compilation
"$MYDIR"/trialc.sh */

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

# now we have divided the workload, send it out to the ta's
humor=$(iching.sh)
for ta in "${!email[@]}"
do
    cp -n "$MYDIR"/{pol.sh,rgrade.sh,collectplag.sh} "$ta"
    if [ "$CSV" ]; then
        echo "OrgDefinedId,$grade,End-of-Line Indicator" > "$ta/grades.csv"
        cp -n "$MYDIR"/{grades.sh,feedback.sh} "$ta"
        sed -f - "$MYDIR"/mailto.sh > "${ta}/mailto.sh" <<-...
            /^FROM=/c\
            FROM="${email[$ta]}"
            /^PREFIX=/c\
            PREFIX="${SUBJECT}: $assignment"
	...
        chmod +x "${ta}"/mailto.sh
    fi
    if [ "${email[$ta]}" ]; then
        echo Mailing "$ta"
        pkt="$ta-${zip%.zip}.7z"
        7za a -ms=on -mx=9 "$pkt" "$ta" > /dev/null
        #echo "$humor" | mailx -n -s "${SUBJECT} ${zip%.zip}" -a "$pkt" "${email[$ta]}" 
        echo "$humor" | mutt -s "${SUBJECT}: ${zip%.zip}" -a "$pkt" -- "${email[$ta]}" 
        rm -f "$pkt"
    fi
done
