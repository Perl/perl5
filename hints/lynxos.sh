#
# LynxOS hints
#
# These hints were submitted by:
#   Greg Seibert
#   seibert@Lynx.COM
#

cc='gcc'
so='none'
usemymalloc='n'

# When LynxOS runs a script with "#!" it sets argv[0] to the script name
toke_cflags='ccflags="$ccflags -DARG_ZERO_IS_SCRIPT"'
