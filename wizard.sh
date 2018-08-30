#! /bin/bash

# configuration wizard for bb-scripts

set -e
cd "${0%/*}"

echo Stop! 
echo
echo Who would cross the BlackBoard of Death must answer me these questions three, 
echo ere the other side he see.
echo
echo What... is your username?
read -p "User: " BBUSER 
./bblogin2.sh "$BBUSER"

death() {
	echo "What... is the airspeed-velocity of an unladen swallow?"
	read -p "(African or European swallow): "
	sleep 1
	echo "..."
	sleep 1
	echo "You have to know these things when you are a king, you know."
	exit 1
}

echo
echo What... is your quest?

CURL="curl --silent --cookie bb.cookie"
BBCOURSES="https://blackboard.ru.nl/webapps/blackboard/execute/globalCourseNavMenuSection?cmd=view"

QUESTS="$($CURL "$BBCOURSES" | sed -n '/a href/s/.*Course[^_]*_\([0-9]\+\)_1[^>]*>\([^<]*\).*/\2|\1/p' | grep "^\(..\)\?$(date +%y)" | sort -r | tr ' ' _)"
select course in $QUESTS; do
	BBCOURSEID="${course#*|}"
	course="$(echo "$course" | sed 'y/_/ /;s/[[:space:]]*([^)]*)//')"
	if [ -z "$BBCOURSEID" ]; then
	    death
	else
	    break
	fi
done

echo
read -p "What... is your favorite editor: " -i "$EDITOR" edit

echo '# email addresses of all participating assistants' > bb.mail
grep '^email' elroy.sh >> bb.mail
which "${edit:-vi}" || death
${edit:-vi} bb.mail

MAILFMT='email\[.*]=.*@.*'
if grep -q -v -e "^\($MAILFMT\|\)$" -e "^#" bb.mail || ! grep -q "$MAILFMT" bb.mail; then
	death
fi

sed -i "/^email/d;/^typeset -A email/rbb.mail" elroy.sh
sed -i "0,/^BBUSER=.*$/s//BBUSER=$BBUSER/" elroy.sh
sed -i "0,/^BBCOURSEID=[0-9]\+/s//BBCOURSEID=$BBCOURSEID/" elroy.sh upload.sh
sed -i "0,/BBCOURSEID:=[0-9]\+/s//BBCOURSEID:=$BBCOURSEID/" getsch.sh
sed -i "0,/^SUBJECT=.*$/s//SUBJECT=\"${course%|*}: \"/" elroy.sh

echo Go on. Off you go.
rm -f bb.mail

echo You still have to set up dupes.sh
echo
death
