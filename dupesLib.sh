DIFF="diff --ignore-all-space --minimal --side-by-side --width=160 --left-column"

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

# fingerprint nicelisted files with specified extensions
# arg1: NICELISTDIR
# arg2: niceListFileExts
# arg3: name of assc array
#https://unix.stackexchange.com/questions/462068/bash-return-an-associative-array-from-a-function-and-then-pass-that-associative
initNiceList() {
    #local declaration, call-by-name passing
    #have to use a different name because of https://stackoverflow.com/questions/33775996/circular-name-reference
    declare -n _nicelist="$3"
    while read -r -d $'\0' file; do
	_nicelist[$(fingerprint "$file")]="$file"
    done < <(eval $(buildFindString "$1" "$2"))
    # ^^we need a clever workaround to not lose the map to a subshell:
    # http://mywiki.wooledge.org/ProcessSubstitution
}

# arg1: dir
# arg2: niceListFileExts
buildFindString() {
    local findString="find \"$1\""
    for ext in $2
    do
	findString=${findString}" -type f -name '*.$ext' -print0 -o"
    done
    findString=${findString: 0:-3} #remove trailing -o
    echo $findString
}
