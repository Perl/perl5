#!/bin/sh

Existing=`cat .patchnum 2>/dev/null`
if [ -e ".patch" ]; then
	Current=`awk '{print $4}' .patch`
else
	Current=`git describe`
fi

if [ "$Existing" != "$Current" ]; then
	echo "Updating .patchnum"
	echo $Current > .patchnum
else
	echo "Reusing .patchnum" 
fi
