#!/bin/sh
#
# Written: Nov 1994 Wayne Scott <wscott@ichips.intel.com>
#
# Updated: 1997-8 Jarkko Hietaniemi <jhi@iki.fi>
#
# Create the export list for perl.
# Needed by AIX to do dynamic linking.
#
# This simple program relies on global.sym and few other *.sym files
# and the *var*.h files being up to date with all of the global
# symbols that a dynamic link library might want to access.
#
# Most symbols have a Perl_ or PL_prefix because that's what embed.h
# sticks in front of them.
#
# AIX requires the list of external symbols (variables or functions)
# that are made available for another executable object file the import.
# The list is called the export file and it is a simple text file.
# The first line must be
#!
# That is, hash-bang, pound-shout, however you want to call it.
# The remainder of the file are the names of the symbols, one per line.
# The file is then given to the system loader (cc/xlc command line)
# as -bE:export.file.

case $CONFIGDOTSH in
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

# No compat3 since 5.004_50.
# No interp.sym since 5.005_03.
# perlio.sym will added later if needed.

syms="global.sym pp.sym"

cat $syms                                              >> perl.exp
sed -n '/^[A-Za-z]/ s/^/PL_/p'   globvar.sym           >> perl.exp

sed -n 's/^PERLVAR.*(G\([^[,]*\).*/PL_\1/p' perlvars.h >> perl.exp
sed -n 's/^PERLVAR.*(I\([^[,]*\).*/PL_\1/p' intrpvar.h >> perl.exp
sed -n 's/^PERLVAR.*(T\([^[,]*\).*/PL_\1/p' thrdvar.h  >> perl.exp

# 
# If we use the PerlIO abstraction layer, add its symbols.
#

if [ "X$useperlio" = "Xdefine" ]
then
	grep '^[A-Za-z]' perlio.sym >> perl.exp
fi

#
# Extra globals not included above (including a few that might
# not actually be defined, but there's no harm in that).
#

#cat >>perl.exp <<END
#END

# The shebang line nicely sorts as the first one.
sort -o perl.exp -u perl.exp

# eof
