# Sequent Dynix/Ptx v. 4 hints
# Created 1996/03/15 by Brad Howerter, bhower@wgc.woodward.com
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

