This file contains patches to dist 3 (PL 51) that I used to generate
Configure for perl.

These patches do the following:

Oldconfig.U
    Clean up and extend the $osvers detection for DEC OSF/1 on the Alpha.
archname.U
    Protect against spaces in the output of uname -m.
sig_name.U
    Look in <linux/signals.h> too.
usrinc.U
    Ensure that the ./mips file exists.  libpth.U calls it.
    
	Andy Dougherty		doughera@lafcol.lafayette.edu
	Dept. of Physics
	Lafayette College,	Easton, PA  18042  USA

Index: Oldconfig.U
Prereq:  3.0.1.7 
*** mcon/U/Oldconfig.U	Thu Feb 16 09:52:38 1995
--- /home2/doughera/lib/dist/U/Oldconfig.U	Thu Feb 16 16:26:25 1995
***************
*** 264,275 ****
  			osvers="$3"
  			;;
  		osf1)	case "$5" in
! 				alpha)  osname=dec_osf
! 					case "$3" in
! 						[vt]1\.*) osvers=1 ;;
! 						[vt]2\.*) osvers=2 ;;
! 						[vt]3\.*) osvers=3 ;;
! 					esac
  					;;
  			hp*)	osname=hp_osf1	;;
  			mips)	osname=mips_osf1 ;;
--- 264,274 ----
  			osvers="$3"
  			;;
  		osf1)	case "$5" in
! 				alpha)
! ?X: DEC OSF/1 myuname -a output looks like:  osf1 xxxx t3.2 123.4 alpha
! ?X: where the version number can be either vn.n or tn.n.
! 					osname=dec_osf
! 					osvers=`echo "$3" | sed 's/^[vt]//'`
  					;;
  			hp*)	osname=hp_osf1	;;
  			mips)	osname=mips_osf1 ;;
Index: archname.U
Prereq:  3.0.1.1 
*** mcon/U/archname.U	Thu Feb 16 09:52:31 1995
--- /home2/doughera/lib/dist/U/archname.U	Mon Feb 27 15:24:22 1995
***************
*** 12,18 ****
  ?RCS: Revision 3.0.1.1  1995/02/15  14:14:21  ram
  ?RCS: patch51: created
  ?RCS:
! ?MAKE:archname myarchname: cat Loc Myread Oldconfig osname test rm
  ?MAKE:	-pick add $@ %<
  ?S:archname:
  ?S:	This variable is a short name to characterize the current
--- 12,18 ----
  ?RCS: Revision 3.0.1.1  1995/02/15  14:14:21  ram
  ?RCS: patch51: created
  ?RCS:
! ?MAKE:archname myarchname: sed Loc Myread Oldconfig osname test rm
  ?MAKE:	-pick add $@ %<
  ?S:archname:
  ?S:	This variable is a short name to characterize the current
***************
*** 43,49 ****
  	tarch=`arch`"-$osname"
  elif xxx=`./loc uname blurfl $pth`; $test -f "$xxx" ; then
  	if uname -m > tmparch 2>&1 ; then
! 		tarch=`$cat tmparch`"-$osname"
  	else
  		tarch="$osname"
  	fi
--- 43,49 ----
  	tarch=`arch`"-$osname"
  elif xxx=`./loc uname blurfl $pth`; $test -f "$xxx" ; then
  	if uname -m > tmparch 2>&1 ; then
! 		tarch=`$sed -e 's/ /_/g' -e 's/$/'"-$osname/" tmparch`
  	else
  		tarch="$osname"
  	fi
Index: sig_name.U
Prereq:  3.0.1.2 
*** mcon/U/sig_name.U	Wed Jun 22 01:20:22 1994
--- /home2/doughera/lib/dist/U/sig_name.U	Mon Feb 27 14:54:05 1995
***************
*** 40,46 ****
  case "$sig_name" in
  '')
  	echo "Generating a list of signal names..." >&4
! 	xxx=`./findhdr signal.h`" "`./findhdr sys/signal.h`
  	set X `cat $xxx 2>&1 | $awk '
  $1 ~ /^#define$/ && $2 ~ /^SIG[A-Z0-9]*$/ && $3 ~ /^[1-9][0-9]*$/ {
  	sig[$3] = substr($2,4,20)
--- 40,46 ----
  case "$sig_name" in
  '')
  	echo "Generating a list of signal names..." >&4
! 	xxx=`./findhdr signal.h`" "`./findhdr sys/signal.h`" "`./findhdr linux/signal.h`
  	set X `cat $xxx 2>&1 | $awk '
  $1 ~ /^#define$/ && $2 ~ /^SIG[A-Z0-9]*$/ && $3 ~ /^[1-9][0-9]*$/ {
  	sig[$3] = substr($2,4,20)
Index: usrinc.U
Prereq:  3.0.1.1 
*** mcon/U/usrinc.U	Sun May  8 22:14:36 1994
--- /home2/doughera/lib/dist/U/usrinc.U	Tue Feb 21 11:00:10 1995
***************
*** 60,71 ****
  	fi
  	$rm -f usr.c usr.out
  	echo "and you're compiling with the $mips_type compiler and libraries."
  else
  	echo "Doesn't look like a MIPS system."
  	echo "exit 1" >mips
- 	chmod +x mips
- 	$eunicefix mips
  fi
  echo " "
  case "$usrinc" in
  '') ;;
--- 60,72 ----
  	fi
  	$rm -f usr.c usr.out
  	echo "and you're compiling with the $mips_type compiler and libraries."
+ 	echo "exit 0" >mips
  else
  	echo "Doesn't look like a MIPS system."
  	echo "exit 1" >mips
  fi
+ chmod +x mips
+ $eunicefix mips
  echo " "
  case "$usrinc" in
  '') ;;
