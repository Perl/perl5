#!/bin/sh

# Written: Nov 1994 Wayne Scott (wscott@ichips.intel.com)

# Create the export list for perl.
# Needed by AIX to do dynamic linking.

# NOTE: If you're using 'old_embed.pl', don't use this script!
#       Use 'old_perl_exp.SH' instead.

# This simple program relys on 'global.sym' being up to date
# with all of the global symbols that a dynamicly link library
# might want to access.

# All symbols have a Perl_ prefix because that's what embed.h
# sticks in front of them.

echo "Extracting perl.exp"

rm -f perl.exp
echo "#!" > perl.exp

case "$bincompat3" in
y*)
	global=/tmp/exp$$g
	interp=/tmp/exp$$i
	compat3=/tmp/exp$$c
	trap 'rm -f $global $interp $compat3' 0
	trap 'exit 1' 1 2 3 13 15
	grep '^[A-Za-z]' global.sym | sort >$global
	grep '^[A-Za-z]' interp.sym | sort >$interp
	grep '^[A-Za-z]' compat3.sym | sort >$compat3
	comm -23 $global $compat3 | sed 's/^/Perl_/p' >> perl.exp
	comm -12 $global $compat3 >> perl.exp
	comm -12 $interp $compat3 | sed 's/^/Perl_/p' >> perl.exp
	comm -23 $interp $compat3 >> perl.exp
	;;
*)
	sed -n '/^[A-Za-z]/ s/^/Perl_/p' global.sym interp.sym >> perl.exp
	;;
esac

# extra globals not included above.
cat <<END >> perl.exp
perl_init_i18nl10n
perl_init_i18nl14n
perl_new_collate
perl_new_ctype
perl_new_numeric
perl_set_numeric_local
perl_set_numeric_standard
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
