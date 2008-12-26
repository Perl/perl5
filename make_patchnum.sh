#!/bin/sh

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
	echo "Updating .patchnum and .sha1"
	echo -n $Current > .patchnum
	echo -n $Sha1 > .sha1
else
	echo "Reusing .patchnum and .sha1" 
fi
