#!/bin/sh

. config.sh

Existing=`cat .patchnum 2>/dev/null`
Existing_Sha1=`cat .sha1 2>/dev/null`

if [ -e ".patch" ]; then
	Current=`awk '{print $4}' .patch`
	Sha1=`awk '{print $3}' .patch`
elif [ -d ".git" ]; then
	# we should do something better here
	Current=`git describe`
	Sha1=`git rev-parse HEAD`
	Changed=`git diff-index --name-only HEAD`
	[ -n "$Changed" ] && Current="$Current-with-uncommitted-changes"
fi

if [ "$Existing" != "$Current" -o "$Existing_Sha1" != "$Sha1" ]; then
	(echo "hi there\c" ; echo " ") >.echotmp
	if $contains c .echotmp >/dev/null 2>&1 ; then
		n='-n'
		c=''
	else
		n=''
		c='\c'
	fi
	rm -f .echotmp
	echo "Updating .patchnum and .sha1"
	echo $n "$Current$c" > .patchnum
	echo $n "$Sha1$c" > .sha1

else
	echo "Reusing .patchnum and .sha1" 
fi
