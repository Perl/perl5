#!/bin/sh
#
# Written: Nov 1994 Wayne Scott (wscott@ichips.intel.com)
#
# Create the export list for perl.
# Needed by AIX to do dynamic linking.
#
# This simple program relys on 'global.sym' and other *.sym files
# being up to date with all of the global symbols that a dynamic
# link library might want to access.
#
# Most symbols have a Perl_ prefix because that's what embed.h sticks
# in front of them.  Variations depend on binary compatibility with
# Perl 5.003.
#

case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac

echo "Extracting perl.exp"

rm -f perl.exp
echo "#!" > perl.exp

# No compat3 since and including the 5.004_50.
# perlio.sym added later if needed.
syms=`ls -1 *.sym|egrep -v 'compat3|perlio'`

sed -n '/^[A-Za-z]/ s/^/Perl_/p' $syms                  >> perl.exp

sed -n 's/^PERLVAR.*(G\([^,[]*\).*/Perl_\1/p' perlvars.h >> perl.exp
sed -n 's/^PERLVAR.*(T\([^,[]*\).*/Perl_\1/p' thrdvar.h  >> perl.exp

# 
# If we use the PerlIO abstraction layer, add its symbols
#

if [ $useperlio = "define" ]
then
	grep '^[A-Za-z]' perlio.sym >> perl.exp
fi

#
# Extra globals not included above (including a few that might
# not actually be defined, but there's no harm in that).
#

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
perl_eval_pv
perl_eval_sv
perl_require_pv
Mymalloc
Mycalloc
Myremalloc
Myfree
Perl_malloc
Perl_calloc
Perl_realloc
Perl_free
END

# The shebang line nicely sorts as the first one.
sort -o perl.exp -u perl.exp

# eof
