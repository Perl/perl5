require 5.004;
use strict;
use Config qw(%Config);
use ExtUtils::MakeMaker;

my @extra;
#@extra = (DEFINE => "-DU32_ALIGNMENT_REQUIRED") unless free_u32_alignment();

WriteMakefile(
    'NAME'	   => 'Digest::MD5',
    'VERSION_FROM' => 'MD5.pm',
    @extra,
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
exit;

#--------------


sub free_u32_alignment
{
    $|=1;
    print "Testing alignment requirements for U32... ";
    return 1 if $^O eq 'VMS';

    open(ALIGN_TEST, ">u32align.c") or die "$!";
    print ALIGN_TEST <<'EOT'; close(ALIGN_TEST);
/*--------------------------------------------------------------*/
/*  This program allocates a buffer of U8 (char) and then tries */
/*  to access it through a U32 pointer at every offset.  The    */
/*  program  is expected to die with a bus error/seg fault for  */
/*  machines that do not support unaligned integer read/write   */
/*--------------------------------------------------------------*/

#include <stdio.h>
#include "EXTERN.h"
#include "perl.h"

int main(int argc, char** argv, char** env)
{
#if BYTEORDER == 0x1234 || BYTEORDER == 0x4321
    U8 buf[] = "\0\0\0\1\0\0\0\0";
    U32 *up;
    int i;

    if (sizeof(U32) != 4) {
	printf("sizeof(U32) is not 4, but %d\n", sizeof(U32));
	exit(1);
    }

    fflush(stdout);

    for (i = 0; i < 4; i++) {
	up = (U32*)(buf + i);
	if (! ((*up == 1 << (8*i)) ||   /* big-endian */
	       (*up == 1 << (8*(3-i)))  /* little-endian */
	      )
	   )
	{
	    printf("read failed (%x)\n", *up);
	    exit(2);
	}
    }

    /* write test */
    for (i = 0; i < 4; i++) {
	up = (U32*)(buf + i);
	*up = 0xBeef;
	if (*up != 0xBeef) {
	    printf("write failed (%x)\n", *up);
	    exit(3);
	}
    }

    printf("no restrictions\n");
    exit(0);
#else
    printf("unusual byteorder, playing safe\n");
    exit(1);
#endif
    return 0;
}
/*--------------------------------------------------------------*/
EOT

    my $cc_cmd = "$Config{cc} $Config{ccflags} -I$Config{archlibexp}/CORE";
    my $exe = "u32align$Config{_exe}";
    if ($^O eq 'MSWin32') {
        $cc_cmd .= ' -DWIN32IO_IS_STDIO';
    } else {
	$cc_cmd .= " -o $exe";
    }
    my $rc;
    $rc = system("$cc_cmd $Config{ldflags} u32align.c $Config{libs}");
    if ($rc) {
	print "Can't compile test program\n";
	unlink("u32align.c", $exe, "u32align$Config{_o}");
	return;
    }

    $rc = system("./$exe");
    unlink("u32align.c", $exe, "u32align$Config{_o}");

    return 1 unless $rc;

    if ($rc > 0x80) {
	$rc >>= 8;
	print "Test program exit status was $rc\n";
    } else {
	if ($rc & 0x80) {
	    $rc &= ~0x80;
	    print "Core dump deleted\n";
	    unlink("core");
	}
	print "signal $rc\n";
    }
    return;
}
