package Test::Harness;

use Exporter;
use Benchmark;
use Config;
require 5.002;

$VERSION = $VERSION = "1.02";

@ISA=('Exporter');
@EXPORT= qw(&runtests);
@EXPORT_OK= qw($verbose $switches);


$Test::Harness::verbose = 0;
$Test::Harness::switches = "-w";

sub runtests {
    my(@tests) = @_;
    local($|) = 1;
    my($test,$te,$ok,$next,$max,$totmax, $files,$pct,@failed);
    my $bad = 0;
    my $good = 0;
    my $total = @tests;
    local($ENV{'PERL5LIB'}) = join($Config{path_sep}, @INC); # pass -I flags to children

    my $t_start = new Benchmark;
    while ($test = shift(@tests)) {
	$te = $test;
	chop($te);
	print "$te" . '.' x (20 - length($te));
	my $fh = "RESULTS";
	open($fh,"$^X $Test::Harness::switches $test|") || (print "can't run. $!\n");
	$ok = $next = $max = 0;
	@failed = ();
	while (<$fh>) {
	    if( $Test::Harness::verbose ){
		print $_;
	    }
	    unless (/^\#/) {
		if (/^1\.\.([0-9]+)/) {
		    $max = $1;
		    $totmax += $max;
		    $files++;
		    $next = 1;
		} elsif ($max) {
		    if (/^not ok ([0-9]*)/){
			push @failed, $next;
		    } elsif (/^ok (.*)/ && $1 == $next) {
			$ok++;
		    }
		    $next = $1 + 1;
		}
	    }
	}
	close($fh); # must close to reap child resource values
	my $wstatus = $?;
	my $estatus = $wstatus >> 8;
	$next-- if $next;
	if ($ok == $max && $next == $max && ! $wstatus) {
	    print "ok\n";
	    $good++;
	} else {
	    if (@failed) {
		print canonfailed($max,@failed);
	    } else {
		if ($next == 0) {
		    print "FAILED before any test output arrived\n";
		} else {
		    print canonfailed($max,$next+1..$max);
		}
	    }
	    if ($wstatus) {
		print "\tTest returned status $estatus (wstat $wstatus)\n";
	    }
	    $bad++;
	    $_ = $test;
	}
    }
    my $t_total = timediff(new Benchmark, $t_start);
    
    if ($bad == 0) {
	if ($ok) {
	    print "All tests successful.\n";
	} else {
	    die "FAILED--no tests were run for some reason.\n";
	}
    } else {
	$pct = sprintf("%.2f", $good / $total * 100);
	if ($bad == 1) {
	    die "Failed 1 test script, $pct% okay.\n";
	} else {
	    die "Failed $bad/$total test scripts, $pct% okay.\n";
	}
    }
    printf("Files=%d,  Tests=%d, %s\n", $files, $totmax, timestr($t_total, 'nop'));
}

sub canonfailed ($@) {
    my($max,@failed) = @_;
    my $failed = @failed;
    my @result = ();
    my @canon = ();
    my $min;
    my $last = $min = shift @failed;
    if (@failed) {
	for (@failed, $failed[-1]) { # don't forget the last one
	    if ($_ > $last+1 || $_ == $last) {
		if ($min == $last) {
		    push @canon, $last;
		} else {
		    push @canon, "$min-$last";
		}
		$min = $_;
	    }
	    $last = $_;
	}
	local $" = ", ";
	push @result, "FAILED tests @canon\n";
    } else {
	push @result, "FAILED test $last\n";
    }

    push @result, "\tFailed $failed/$max tests, ";
    push @result, sprintf("%.2f",100*(1-$failed/$max)), "% okay\n";
    join "", @result;
}

1;
__END__

=head1 NAME

Test::Harness - run perl standard test scripts with statistics

=head1 SYNOPSIS

use Test::Harness;

runtests(@tests);

=head1 DESCRIPTION

Perl test scripts print to standard output C<"ok N"> for each single
test, where C<N> is an increasing sequence of integers. The first line
output by a standard test scxript is C<"1..M"> with C<M> being the
number of tests that should be run within the test
script. Test::Harness::runscripts(@tests) runs all the testscripts
named as arguments and checks standard output for the expected
C<"ok N"> strings.

After all tests have been performed, runscripts() prints some
performance statistics that are computed by the Benchmark module.

=head1 EXPORT

C<&runscripts> is exported by Test::Harness per default.

=head1 DIAGNOSTICS

=over 4

=item C<All tests successful.\nFiles=%d,  Tests=%d, %s>

If all tests are successful some statistics about the performance are
printed.

=item C<Failed 1 test, $pct% okay.>

=item C<Failed %d/%d tests, %.2f%% okay.>

If not all tests were successful, the script dies with one of the
above messages.

=back

=head1 SEE ALSO

See L<Benchmark> for the underlying timing routines.

=head1 AUTHORS

Either Tim Bunce or Andreas Koenig, we don't know. What we know for
sure is, that it was inspired by Larry Wall's TEST script that came
with perl distributions for ages. Current maintainer is Andreas
Koenig.

=head1 BUGS

Test::Harness uses $^X to determine the perl binary to run the tests
with. Test scripts running via the shebang (C<#!>) line may not be portable
because $^X is not consistent for shebang scripts across
platforms. This is no problem when Test::Harness is run with an
absolute path to the perl binary.

=cut
