# irix_6.sh
# from Krishna Sethuraman, krishna@mit.edu
# Date: Wed Jan 18 11:40:08 EST 1995
# added `-32' to force compilation in 32-bit mode.
# otherwise, copied from irix_5.sh.

# Perl built with this hints file under IRIX 6.0.1 passes 
# all tests (`make test').

i_time='define'
cc="cc -32"
ccflags="$ccflags -D_POSIX_SOURCE -ansiposix -D_BSD_TYPES -Olimit 3000"
lddlflags="-32 -shared"
set `echo X "$libswanted "|sed -e 's/ socket / /' -e 's/ nsl / /' -e 's/ dl /
/'`
shift
libswanted="$*"

# The following might be of interest if you wish to try 64-bit mode:
# irix_6.sh
# Krishna Sethuraman, krishna@mit.edu
# This will build a 64-bit perl 5 executable under IRIX 6.x.
# I had to remove socket, sun, crypt, nsl, and dl from the 
# link line because there are no 64-bit libraries with these
# names (as of IRIX 6.0.1).

# I don't know if this will actually build a fully working perl because I
# can't tell if the symbols normally provided by these libraries
# are provided by other libraries which remain on the link line.
# In any case, perl does build with this file without unresolved
# symbol complaints.

# i_time='define'
# ccflags="$ccflags -D_POSIX_SOURCE -ansiposix -D_BSD_TYPES -Olimit 3000"
# lddlflags="-shared"
# set `echo X "$libswanted "|sed -e 's/ socket / /' -e 's/ sun / /' -e 's/ crypt / /' -e 's/ nsl / /' -e 's/ dl / /'`
# shift
# libswanted="$*"
