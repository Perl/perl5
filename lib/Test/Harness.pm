package Test::Harness;

use Exporter;
use Benchmark;
use Config;

$Is_OS2 = $Config{'osname'} =~ m|^os/?2$|i ;

$ENV{EMXSHELL} = 'sh' if $Is_OS2; # to run commands
$path_s = $Is_OS2 ? ';' : ':' ;

@ISA=(Exporter);
@EXPORT= qw(&runtests);
@EXPORT_OK= qw($verbose $switches);

$verbose = 0;
$switches = "-w";

sub runtests {
    my(@tests) = @_;
    local($|) = 1;
    my($test,$te,$ok,$next,$max,$totmax, $files,$pct);
    my $bad = 0;
    my $good = 0;
    my $total = @tests;
    local($ENV{'PERL5LIB'}) = join($path_s, @INC); # pass -I flags to children

    my $t_start = new Benchmark;
    while ($test = shift(@tests)) {
      $te = $test;
      chop($te);
      print "$te" . '.' x (20 - length($te));
      my $fh = "RESULTS";
      open($fh,"$^X $switches $test|") || (print "can't run. $!\n");
      $ok = 0;
      $next = 0;
      while (<$fh>) {
	  if( $verbose ){
		  print $_;
	  }
          unless (/^#/) {
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
                  }
              }
          }
      }
      close($fh); # must close to reap child resource values
      $next -= 1;
      if ($ok && $next == $max) {
          print "ok\n";
          $good += 1;
      } else {
          $next += 1;
          print "FAILED on test $next\n";
          $bad += 1;
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
          die "Failed 1 test, $pct% okay.\n";
      } else {
          die "Failed $bad/$total tests, $pct% okay.\n";
      }
    }
    printf("Files=%d,  Tests=%d, %s\n", $files,$totmax, timestr($t_total, 'nop'));
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

See L<Benchmerk> for the underlying timing routines.

=head1 BUGS

Test::Harness uses $^X to determine the perl binary to run the tests
with. Test scripts running via the shebang (C<#!>) line may not be portable
because $^X is not consistent for shebang scripts across
platforms. This is no problem when Test::Harness is run with an
absolute path to the perl binary.

=cut
