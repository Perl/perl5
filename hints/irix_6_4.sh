# hints/irix_6_4.sh
#
# Created by John Stoffel (jfs@fluent.com), 01/13/1997
# Based on the Irix 6.2 hints file, but simplified.

# Configure can't parse 'nm' output on Irix 6.4
usenm='n'

# This keeps optimizer warnings quiet.
ccflags="$ccflags -Olimit 3000"

# Gets rid of some extra libs that don't seem to be really needed.
# See the Irix 6.2 hints file for some justifications.
set `echo X "$libswanted "|sed -e 's/ sun / /' -e 's/ crypt / /' -e 's/ bsd / /' -e 's/ PW / /' -e 's/ dl / /' -e 's/ socket / /' -e 's/ nsl / /'`
shift
libswanted="$*"
