set `echo "$libswanted" | sed -e 's/ PW / /' -e 's/ x / /'`
libswanted="$*"
ccflags="$ccflags -DCRIPPLED_CC -DDEBUGGING"
