package Test::Harness;

use Exporter;
use Benchmark;
@ISA=(Exporter);
@EXPORT= qw(&runtests &test_lib);
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
    local($ENV{'PERL5LIB'}) = join(':', @INC); # pass -I flags to children

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
          warn "Failed 1 test, $pct% okay.\n";
      } else {
          die "Failed $bad/$total tests, $pct% okay.\n";
      }
    }
    printf("Files=%d,  Tests=%d, %s\n", $files,$totmax, timestr($t_total, 'nop'));
}

1;
