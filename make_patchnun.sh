#!/bin/sh

Existing=`cat .patchnum 2>/dev/null`
Current=`git describe`

if [ "$Existing" != "$Current" ]; then
	echo "Updating .patchnum"
	echo $Current > .patchnum
else
	echo "Reusing .patchnum" 
fi
