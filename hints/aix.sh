d_fchmod=undef
d_setrgid='undef'
d_setruid='undef'
alignbytes=8

# Changes for dynamic linking by Wayne Scott (wscott@ichips.intel.com)
#
# Tell perl which symbols to export for dynamic linking.
ccdlflags='-bE:perl.exp'

# The first 3 options would not be needed if dynamic libs. could be linked
# with the compiler instead of ld.
# -bI:$(PERL_INC)/perl.exp  Read the exported symbols from the perl binary
# -bE:$(BASEEXT).exp        Export these symbols.  This file contains only one
#                           symbol: boot_$(EXP)  can it be auto-generated?
lddlflags='-H512 -T512 -bhalt:4 -bM:SRE -bI:$(PERL_INC)/perl.exp -bE:$(BASEEXT).exp -e _nostart -lc'

ccflags='-D_ALL_SOURCE'
# Make setsockopt work correctly.  See man page.
# ccflags='-D_BSD=44'
