#!/bin/sh

# Written: Nov 1994 Wayne Scott (wscott@ichips.intel.com)

# Create the export list for perl based on 'old_global.sym'.
# Needed by AIX to do dynamic linking.

# This simple program relys on 'old_global.sym' being up to date
# with all of the global symbols that a dynamicly link library
# might want to access.

# All symbols have a Perl_ prefix because that's what embed.h
# sticks in front of them.

echo "Extracting perl.exp"

rm -f perl.exp
echo "#!" > perl.exp

sed -n '/^[A-Za-z]/ s/^/Perl_/p' old_global.sym >> perl.exp

#
# also add symbols from interp.sym
# They are only needed if -DMULTIPLICITY is not set but it
# doesn't hurt to include them anyway.
sed -n '/^[A-Za-z]/ p' interp.sym >> perl.exp

# extra globals not included above.
cat <<END >> perl.exp
perl_init_i18nl10n
perl_init_i18nl14n
perl_new_collate
perl_new_ctype
perl_new_numeric
perl_numeric_local
perl_numeric_standard
perl_alloc
perl_construct
perl_destruct
perl_free
perl_parse
perl_run
perl_get_sv
perl_get_av
perl_get_hv
perl_get_cv
perl_call_argv
perl_call_pv
perl_call_method
perl_call_sv
perl_requirepv
END
