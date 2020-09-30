#this declares `email` as an associative array
typeset -A email

#enter the emails of the correctors here.
#The string used as the key will also be used as a dirname, so be aware of that.
email[jon]="jon.doe@example.com"

SUBJECT="`whoami` could not be bothered to configure SUBJECT"

#specify files of _which_ extension in nicelistdir should be considered
#this is to exclude e.g. binary, IDE files.
niceListFileExts="hs java cpp"

# All nicelisted files should be in this directory, e.g. one level up of the current working directory.
# It should not be in the CWD to not be confused with a student submission.
# It is okay if this directory does not exist, the nicelist feature is then not used.
NICELISTDIR="../plagiarism-nicelist"
