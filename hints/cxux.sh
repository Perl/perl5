# Hints for the CX/UX 7.1 operating system running on Harris NightHawk
# machines.  written by Tom.Horsley@mail.hcsc.com
#
# This config is setup for dynamic linking and the Harris C compiler.

# Check some things and print warnings if this isn't going to work...
#
case ${SDE_TARGET:-ELF} in
   [Cc][Oo][Ff][Ff]|[Oo][Cc][Ss]) echo ''
      echo ''
      echo WARNING: Do not build perl 5 with the SDE_TARGET set to
      echo generate coff object - perl 5 must be built in the ELF
      echo environment.
      echo ''
      echo '';;
   [Ee][Ll][Ff]) : ;;
   *) echo ''
      echo 'Unknown SDE_TARGET value: '$SDE_TARGET
      echo '';;
esac

case `uname -r` in
   [789]*) : ;;
   *) echo ''
      echo ''
      echo WARNING: Perl 5 requires shared library support, it cannot
      echo be built on releases of CX/UX prior to 7.0 with this hints
      echo file. You\'ll have to do a separate port for the statically
      echo linked COFF environment.
      echo ''
      echo '';;
esac

# Internally at Harris, we use a source management tool which winds up
# giving us read-only copies of source trees that are mostly symbolic links.
# That upsets the perl build process when it tries to edit opcode.h and
# embed.h or touch perly.c or perly.h, so turn those files into "real" files
# when Configure runs. (If you already have "real" source files, this won't
# do anything).
#
if [ -x /usr/local/mkreal ]
then
   for i in '.' '..'
   do
      for j in embed.h opcode.h perly.h perly.c
      do
         if [ -h $i/$j ]
         then
            ( cd $i ; /usr/local/mkreal $j ; chmod 666 $j )
         fi
      done
   done
fi

# We DO NOT want -lmalloc
#
libswanted=`echo ' '$libswanted' ' | sed -e 's/ malloc / /'`

# Stick the low-level elf library path in first.
#
glibpth="/usr/sde/elf/usr/lib $glibpth"

# Need to use Harris cc for most of these options to be meaningful (if you
# want to get this to work with gcc, you're on your own :-). Passing
# -Bexport to the linker when linking perl is important because it leaves
# the interpreter internal symbols visible to the shared libs that will be
# loaded on demand (and will try to reference those symbols). The -u
# option to drag 'sigaction' into the perl main program is to make sure
# it gets defined for the posix shared library (for some reason sigaction
# is static, rather than being defined in libc.so.1).
#
cc='/bin/cc -Xa'
cccdlflags='-Zelf -Zpic'
ccdlflags='-Zelf -Zlink=dynamic -Wl,-Bexport -u sigaction'
lddlflags='-G'

# Configure imagines that stdio.h is "standard", but it really isn't.
# Things like the -T and -B file test operators (on file handles) fail when
# it tries to treat it as "standard"
#
d_stdstdio='undef'

# Configure imagines that it sees a pw_quota field, but it is really in a
# different structure than the one it thinks it is looking at.  WARNING:
# Setting this here in the hints file doesn't help. You need to fix this by
# editing config.sh after Configure asks you to fix things with a shell
# escape! (Maybe Configure should actually try to compile a routine to
# test each field, but what a pain that would be...).
#
# Perhaps I should create a config.over file and add this to it now?
#
d_pwquota='undef'
echo ''
echo ''
echo WARNING: Edit config.sh when Configure offers to let you do so at the
echo end of the configuration process and manually change d_pwquota from
echo define to undef \(or you may want to create a config.over file now\).
echo ''
echo ''

# The following silly shell variable is set just so it will be printed out
# immediately prior to asking the user to edit config.sh :-).
#
dont_forget_to_fix_d_pwquota_in_config_to_be_undef="really"


# Configure sometime finds what it believes to be ndbm header files on the
# system and imagines that we have the NDBM library, but we really don't.
# There is something there that once resembled ndbm, but it is purely
# for internal use in some tool and has been hacked beyond recognition
# (or even function :-)
#
i_ndbm='undef'

# Don't use the perl malloc
#
d_mymalloc='undef'
usemymalloc='n'
