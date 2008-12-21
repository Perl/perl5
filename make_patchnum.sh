#!/bin/sh

Existing=`cat .patchnum 2>/dev/null`
if [ -e ".patch" ]; then
	Current=`awk '{print $4}' .patch`
else
	# we should do something better here
	Current=`git describe`
	Changed=`git diff-index --name-only HEAD`
	if [ -n "$Changed" ]; then
		Current="$Current-with-uncommitted-changes"
	fi
fi

if [ "$Existing" != "$Current" ]; then
	echo "Updating .patchnum"
	echo $Current > .patchnum
else
	echo "Reusing .patchnum" 
fi
