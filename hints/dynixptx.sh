# Sequent Dynix/Ptx v. 4 hints
# Created 1996/03/15 by Brad Howerter, bhower@wgc.woodward.com

# Modified 1998/11/10 by Martin J. Bligh, mbligh@sequent.com
# to incorporate work done by Kurtis D. Rader & myself.

# Use Configure -Dcc=gcc to use gcc.

# cc wants -G for dynamic loading
lddlflags='-G'

# Remove inet to avoid this error in Configure, which causes Configure
# to be unable to figure out return types:
# dynamic linker: ./ssize: can't find libinet.so,
# link with -lsocket instead of -linet

libswanted=`echo $libswanted | sed -e 's/ inet / /'`

# Configure defaults to usenm='y', which doesn't work very well
usenm='n'

# for performance, apparently this makes a huge difference (~krader)

d_vfork='define'
optimize='-Wc,-O3 -W0,-xstring'

case "$osvers" in
4.4*) # configure doesn't find sockets, as they're in libsocket, not libc
        d_socket='define'
        d_oldsock='undef'
        d_sockpair='define'
        ;;
4.2*) # on ptx/TCP 4.2, we can use BSD sockets, but they're not the default.
        cppflags='-Wc,+bsd-socket'
        ccflags='-Wc,+bsd-socket'
        ldflags='-Wc,+bsd-socket'
        d_socket='define'
        d_oldsock='undef'
        d_sockpair='define'
    ;;
esac
