@rem = '
@echo off
if exist perl.exe goto perlhere
echo Cannot run without perl.exe in current directory!!	Did you build it?
pause
goto endofperl
:perlhere
if exist perlglob.exe goto perlglobhere
echo Cannot run without perlglob.exe in current directory!!	Did you build it?
pause
goto endofperl
:perlglobhere
perl %0.bat %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';

#Portions (C) 1995 Microsoft Corporation. All rights reserved. 
#        Developed by hip communications inc., http://info.hip.com/info/


# This is written in a peculiar style, since we're trying to avoid
# most of the constructs we'll be testing for.

$| = 1;

if ($ARGV[0] eq '-v') {
    $verbose = 1;
    shift;
}


# WYT 1995-05-02
chdir 't' if -f 't/TESTNT';


if ($ARGV[0] eq '') {
#    @ARGV = split(/[ \n]/,
#      `echo base/*.t comp/*.t cmd/*.t io/*.t; echo op/*.t lib/*.t`);
#      `ls base/*.t comp/*.t cmd/*.t io/*.t op/*.t lib/*.t`);

# WYT 1995-05-02 wildcard expansion,
#    `perl -e "print( join( ' ', \@ARGV ) )" base/*.t comp/*.t cmd/*.t io/*.t op/*.t lib/*.t nt/*.t`);

# WYT 1995-06-01 removed all dependency on perlglob
# WYT 1995-11-28 hacked up to cope with braindead Win95 console.
    push( @ARGV, `dir/s/b base` );
    push( @ARGV, `dir/s/b comp` );
    push( @ARGV, `dir/s/b cmd` );
    push( @ARGV, `dir/s/b io` );
    push( @ARGV, `dir/s/b op` );
    push( @ARGV, `dir/s/b lib` );
    push( @ARGV, `dir/s/b nt` );

    grep( chomp, @ARGV );
    @ARGV = grep( /\.t$/, @ARGV );
    grep( s/.*t\\//, @ARGV );
}

$sharpbang = 0;

$bad = 0;
$good = 0;
$total = @ARGV;
while ($test = shift) {
    if ($test =~ /^$/) {
	next;
    }
    $te = $test;
# chop off 't' extension
    chop($te);
    print "$te" . '.' x (15 - length($te));
    if ($sharpbang) {
	open(results,"./$test |") || (print "can't run.\n");
    } else {
	    $switch = '';
#	open(results,"./perl$switch $test |") || (print "can't run.\n");
	open(results,"perl$switch $test |") || (print "can't run.\n");
    }
    $ok = 0;
    $next = 0;
    while (<results>) {
	if ($verbose) {
	    print $_;
	}
        unless (/^#/||/^$/) {
	    if (/^1\.\.([0-9]+)/) {
		$max = $1;
		$totmax += $max;
		$files += 1;
		$next = 1;
		$ok = 1;
	    } else {
		$next = $1, $ok = 0, last if /^not ok ([0-9]*)/;
		if (/^ok (.*)/ && $1 == $next) {
		    $next = $next + 1;
		} else {
		    $ok = 0;
		}
	    }
	}
    }
    $next = $next - 1;
    if ($ok && $next == $max) {
	print "ok\n";
	$good = $good + 1;
    } else {
	$next += 1;
	print "FAILED on test $next\n";
	$bad = $bad + 1;
	$_ = $test;
	if (/^base/) {
	    die "Failed a basic test--cannot continue.\n";
	}
    }
}

if ($bad == 0) {
    if ($ok) {
	print "All tests successful.\n";
    } else {
	die "FAILED--no tests were run for some reason.\n";
    }
} else {
    $pct = sprintf("%.2f", $good / $total * 100);
    if ($bad == 1) {
	warn "Failed 1 test, $pct% okay.\n";
    } else {
	die "Failed $bad/$total tests, $pct% okay.\n";
    }
}


# WYT 1995-05-03 times not implemented.
#($user,$sys,$cuser,$csys) = times;
#print sprintf("u=%g  s=%g  cu=%g  cs=%g  files=%d  tests=%d\n",
#    $user,$sys,$cuser,$csys,$files,$totmax);

#`del /f Cmd_while.tmp Comp.try null 2>NULL`;

unlink 'Cmd_while.tmp', 'Comp.try', 'null';

__END__
:endofperl
