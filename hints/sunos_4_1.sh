# hints/sunos_4_1.sh
# Last modified:  Thu Feb  8 11:46:05 EST 1996
# Andy Dougherty  <doughera@lafcol.lafayette.edu>

case "$cc" in
*gcc*)	usevfork=false 
	# GNU as and GNU ld might not work.  See the INSTALL file.
	;;
*)	usevfork=true ;;
esac

# Configure will issue a WHOA warning.  The problem is that
# Configure finds getzname, not tzname.  If you're in the System V
# environment, you can set d_tzname='define' since tzname[] is
# available in the System V environment.
d_tzname='undef'

# Configure will issue a WHOA warning.  The problem is that unistd.h
# contains incorrect prototypes for some functions in the usual
# BSD-ish environment.  In particular, it has
# extern int	getgroups(/* int gidsetsize, gid_t grouplist[] */);
# but groupslist[] ought to be of type int, not gid_t.
# This is only really a problem for perl if the
# user is using gcc, and not running in the SysV environment.
# The gcc fix-includes script exposes those incorrect prototypes.
# There may be other examples as well.  Volunteers are welcome to
# track them all down :-).  In the meantime, we'll just skip unistd.h
# for SunOS.
i_unistd='undef'

cat << 'EOM' >&4

You will probably see  *** WHOA THERE!!! ***  messages from Configure for
d_tzname and i_unistd.  Keep the recommended values.  See
hints/sunos_4_1.sh for more information.
EOM

# SunOS 4.1.3 has two extra fields in struct tm.  This works around
# the problem.  Other BSD platforms may have similar problems.
POSIX_cflags='ccflags="$ccflags -DSTRUCT_TM_HASZONE"'

# check if user is in a bsd or system 5 type environment
if cat -b /dev/null 2>/dev/null
then # bsd
      groupstype='int'
else # sys5
      groupstype='gid_t'
fi
 
