# -*- Mode: cperl; cperl-indent-level: 4 -*-
# $Id: Harness.pm,v 1.11 2001/05/23 18:24:41 schwern Exp $

package Test::Harness;

require 5.004;
use Exporter;
use Benchmark;
use Config;
use strict;

use vars qw($VERSION $Verbose $Switches $Have_Devel_Corestack $Curtest
            $Columns $verbose $switches
            @ISA @EXPORT @EXPORT_OK
           );

# Backwards compatibility for exportable variable names.
*verbose  = \$Verbose;
*switches = \$Switches;

$Have_Devel_Corestack = 0;

$VERSION = "1.21";

$ENV{HARNESS_ACTIVE} = 1;

# Some experimental versions of OS/2 build have broken $?
my $Ignore_Exitcode = $ENV{HARNESS_IGNORE_EXITCODE};

my $Files_In_Dir = $ENV{HARNESS_FILELEAK_IN_DIR};


@ISA = ('Exporter');
@EXPORT    = qw(&runtests);
@EXPORT_OK = qw($verbose $switches);

$Verbose  = 0;
$Switches = "-w";
$Columns  = $ENV{HARNESS_COLUMNS} || $ENV{COLUMNS} || 80;
$Columns--;             # Some shells have trouble with a full line of text.


=head1 NAME

Test::Harness - run perl standard test scripts with statistics

=head1 SYNOPSIS

  use Test::Harness;

  runtests(@test_files);

=head1 DESCRIPTION

B<STOP!> If all you want to do is write a test script, consider using
Test::Simple.  Otherwise, read on.

(By using the Test module, you can write test scripts without
knowing the exact output this module expects.  However, if you need to
know the specifics, read on!)

Perl test scripts print to standard output C<"ok N"> for each single
test, where C<N> is an increasing sequence of integers. The first line
output by a standard test script is C<"1..M"> with C<M> being the
number of tests that should be run within the test
script. Test::Harness::runtests(@tests) runs all the testscripts
named as arguments and checks standard output for the expected
C<"ok N"> strings.

After all tests have been performed, runtests() prints some
performance statistics that are computed by the Benchmark module.

=head2 The test script output

The following explains how Test::Harness interprets the output of your
test program.

=over 4

=item B<'1..M'>

This header tells how many tests there will be.  It should be the
first line output by your test program (but its okay if its preceded
by comments).

In certain instanced, you may not know how many tests you will
ultimately be running.  In this case, it is permitted (but not
encouraged) for the 1..M header to appear as the B<last> line output
by your test (again, it can be followed by further comments).  But we
strongly encourage you to put it first.

Under B<no> circumstances should 1..M appear in the middle of your
output or more than once.


=item B<'ok', 'not ok'.  Ok?>

Any output from the testscript to standard error is ignored and
bypassed, thus will be seen by the user. Lines written to standard
output containing C</^(not\s+)?ok\b/> are interpreted as feedback for
runtests().  All other lines are discarded.

C</^not ok/> indicates a failed test.  C</^ok/> is a successful test.


=item B<test numbers>

Perl normally expects the 'ok' or 'not ok' to be followed by a test
number.  It is tolerated if the test numbers after 'ok' are
omitted. In this case Test::Harness maintains temporarily its own
counter until the script supplies test numbers again. So the following
test script

    print <<END;
    1..6
    not ok
    ok
    not ok
    ok
    ok
    END

will generate

    FAILED tests 1, 3, 6
    Failed 3/6 tests, 50.00% okay


=item B<$Test::Harness::verbose>

The global variable $Test::Harness::verbose is exportable and can be
used to let runtests() display the standard output of the script
without altering the behavior otherwise.

=item B<$Test::Harness::switches>

The global variable $Test::Harness::switches is exportable and can be
used to set perl command line options used for running the test
script(s). The default value is C<-w>.

=item B<Skipping tests>

If the standard output line contains the substring C< # Skip> (with
variations in spacing and case) after C<ok> or C<ok NUMBER>, it is
counted as a skipped test.  If the whole testscript succeeds, the
count of skipped tests is included in the generated output.
C<Test::Harness> reports the text after C< # Skip\S*\s+> as a reason
for skipping.  

  ok 23 # skip Insufficient flogiston pressure.

Similarly, one can include a similar explanation in a C<1..0> line
emitted if the test script is skipped completely:

  1..0 # Skipped: no leverage found

=item B<Todo tests>

If the standard output line contains the substring C< # TODO> after
C<not ok> or C<not ok NUMBER>, it is counted as a todo test.  The text
afterwards is the thing that has to be done before this test will
succeed.

  not ok 13 # TODO harness the power of the atom

These tests represent a feature to be implemented or a bug to be fixed
and act as something of an executable "thing to do" list.  They are
B<not> expected to succeed.  Should a todo test begin succeeding,
Test::Harness will report it as a bonus.  This indicates that whatever
you were supposed to do has been done and you should promote this to a
normal test.

=item B<Bail out!>

As an emergency measure, a test script can decide that further tests
are useless (e.g. missing dependencies) and testing should stop
immediately. In that case the test script prints the magic words

  Bail out!

to standard output. Any message after these words will be displayed by
C<Test::Harness> as the reason why testing is stopped.

=item B<Comments>

Additional comments may be put into the testing output on their own
lines.  Comment lines should begin with a '#', Test::Harness will
ignore them.

  ok 1
  # Life is good, the sun is shining, RAM is cheap.
  not ok 2
  # got 'Bush' expected 'Gore'

=item B<Anything else>

Any other output Test::Harness sees it will silently ignore B<BUT WE
PLAN TO CHANGE THIS!> If you wish to place additional output in your
test script, please use a comment.

=back


=head2 Failure

It will happen, your tests will fail.  After you mop up your ego, you
can begin examining the summary report:

  t/base..............ok                                                       
  t/nonumbers.........ok                                                      
  t/ok................ok                                                       
  t/test-harness......ok                                                       
  t/waterloo..........dubious                                                  
          Test returned status 3 (wstat 768, 0x300)
  DIED. FAILED tests 1, 3, 5, 7, 9, 11, 13, 15, 17, 19
          Failed 10/20 tests, 50.00% okay
  Failed Test  Stat Wstat Total Fail  Failed  List of Failed
  -----------------------------------------------------------------------
  t/waterloo.t    3   768    20   10  50.00%  1 3 5 7 9 11 13 15 17 19
  Failed 1/5 test scripts, 80.00% okay. 10/44 subtests failed, 77.27% okay.

Everything passed but t/waterloo.t.  It failed 10 of 20 tests and
exited with non-zero status indicating something dubious happened.

The columns in the summary report mean:

=over 4

=item B<Failed Test>

The test file which failed.

=item B<Stat>

If the test exited with non-zero, this is its exit status.

=item B<Wstat>

The wait status of the test I<umm, I need a better explanation here>.

=item B<Total>

Total number of tests expected to run.

=item B<Fail>

Number which failed, either from "not ok" or because they never ran.

=item B<Failed>

Percentage of the total tests which failed.

=item B<List of Failed>

A list of the tests which failed.  Successive failures may be
abbreviated (ie. 15-20 to indicate that tests 15, 16, 17, 18, 19 and
20 failed).

=back


=head2 Functions

Test::Harness currently only has one function, here it is.

=over 4

=item B<runtests>

  my $allok = runtests(@test_files);

This runs all the given @test_files and divines whether they passed
or failed based on their output to STDOUT (details above).  It prints
out each individual test which failed along with a summary report and
a how long it all took.

It returns true if everything was ok, false otherwise.

=for _private
This is just _run_all_tests() plus _show_results()

=cut

sub runtests {
    my(@tests) = @_;

    local ($\, $,);

    my($tot, $failedtests) = _run_all_tests(@tests);
    _show_results($tot, $failedtests);

    my $ok = ($tot->{bad} == 0 && $tot->{max});

    die q{Assert '$ok xor keys %$failedtests' failed!}
      unless $ok xor keys %$failedtests;

    return $ok;
}

=begin _private

=item B<_globdir>

  my @files = _globdir $dir;

Returns all the files in a directory.  This is shorthand for backwards
compatibility on systems where glob() doesn't work right.

=cut

sub _globdir { 
    opendir DIRH, shift; 
    my @f = readdir DIRH; 
    closedir DIRH; 

    return @f;
}

=item B<_run_all_tests>

  my($total, $failed) = _run_all_tests(@test_files);

Runs all the given @test_files (as runtests()) but does it quietly (no
report).  $total is a hash ref summary of all the tests run.  Its keys
and values are this:

    bonus           Number of individual todo tests unexpectedly passed
    max             Number of individual tests ran
    ok              Number of individual tests passed
    sub_skipped     Number of individual tests skipped

    files           Number of test files ran
    good            Number of test files passed
    bad             Number of test files failed
    tests           Number of test files originally given
    skipped         Number of test files skipped

If $total->{bad} == 0 and $total->{max} > 0, you've got a successful
test.

$failed is a hash ref of all the test scripts which failed.  Each key
is the name of a test script, each value is another hash representing
how that script failed.  Its keys are these:

    name        Name of the test which failed
    estat       Script's exit value
    wstat       Script's wait status
    max         Number of individual tests
    failed      Number which failed
    percent     Percentage of tests which failed
    canon       List of tests which failed (as string).

Needless to say, $failed should be empty if everything passed.

B<NOTE> Currently this function is still noisy.  I'm working on it.

=cut

sub _run_all_tests {
    my(@tests) = @_;
    local($|) = 1;
    my(%failedtests);

    # Test-wide totals.
    my(%tot) = (
                bonus    => 0,
                max      => 0,
                ok       => 0,
                files    => 0,
                bad      => 0,
                good     => 0,
                tests    => scalar @tests,
                sub_skipped  => 0,
                skipped  => 0,
                bench    => 0
               );

    # pass -I flags to children
    my $old5lib = $ENV{PERL5LIB};

    # VMS has a 255-byte limit on the length of %ENV entries, so
    # toss the ones that involve perl_root, the install location
    # for VMS
    my $new5lib;
    if ($^O eq 'VMS') {
	$new5lib = join($Config{path_sep}, grep {!/perl_root/i;} @INC);
	$Switches =~ s/-(\S*[A-Z]\S*)/"-$1"/g;
    }
    else {
        $new5lib = join($Config{path_sep}, @INC);
    }

    local($ENV{'PERL5LIB'}) = $new5lib;

    my @dir_files = _globdir $Files_In_Dir if defined $Files_In_Dir;
    my $t_start = new Benchmark;

    my $maxlen = 0;
    my $maxsuflen = 0;
    foreach (@tests) { # The same code in t/TEST
	my $suf    = /\.(\w+)$/ ? $1 : '';
	my $len    = length;
	my $suflen = length $suf;
	$maxlen    = $len    if $len    > $maxlen;
	$maxsuflen = $suflen if $suflen > $maxsuflen;
    }
    # + 3 : we want three dots between the test name and the "ok"
    my $width = $maxlen + 3 - $maxsuflen;
    foreach my $tfile (@tests) {
        my($leader, $ml) = _mk_leader($tfile, $width);
        print $leader;

        my $fh = _open_test($tfile);

        # state of the current test.
        my %test = (
                    ok          => 0,
                    'next'      => 0,
                    max         => 0,
                    failed      => [],
                    todo        => {},
                    bonus       => 0,
                    skipped     => 0,
                    skip_reason => undef,
                    ml          => $ml,
                   );

        my($seen_header, $tests_seen) = (0,0);
	while (<$fh>) {
            if( _parse_header($_, \%test, \%tot) ) {
                warn "Test header seen twice!\n" if $seen_header;

                $seen_header = 1;

                warn "1..M can only appear at the beginning or end of tests\n"
                  if $tests_seen && $test{max} < $tests_seen;
            }
            elsif( _parse_test_line($_, \%test, \%tot) ) {
                $tests_seen++;
            }
            # else, ignore it.
	}

        my($estatus, $wstatus) = _close_fh($fh);

        my $allok = $test{ok} == $test{max} && $test{'next'} == $test{max}+1;

	if ($wstatus) {
            $failedtests{$tfile} = _dubious_return(\%test, \%tot, 
                                                  $estatus, $wstatus);
            $failedtests{$tfile}{name} = $tfile;
	}
        elsif ($allok) {
	    if ($test{max} and $test{skipped} + $test{bonus}) {
		my @msg;
		push(@msg, "$test{skipped}/$test{max} skipped: $test{skip_reason}")
		    if $test{skipped};
		push(@msg, "$test{bonus}/$test{max} unexpectedly succeeded")
		    if $test{bonus};
		print "$test{ml}ok, ".join(', ', @msg)."\n";
	    } elsif ($test{max}) {
		print "$test{ml}ok\n";
	    } elsif (defined $test{skip_reason}) {
		print "skipped: $test{skip_reason}\n";
		$tot{skipped}++;
	    } else {
		print "skipped test on this platform\n";
		$tot{skipped}++;
	    }
	    $tot{good}++;
	}
        else {
            if ($test{max}) {
                if ($test{'next'} <= $test{max}) {
                    push @{$test{failed}}, $test{'next'}..$test{max};
                }
                if (@{$test{failed}}) {
                    my ($txt, $canon) = canonfailed($test{max},$test{skipped},
                                                    @{$test{failed}});
                    print "$test{ml}$txt";
                    $failedtests{$tfile} = { canon   => $canon,
                                             max     => $test{max},
                                             failed  => scalar @{$test{failed}},
                                             name    => $tfile, 
                                             percent => 100*(scalar @{$test{failed}})/$test{max},
                                             estat   => '',
                                             wstat   => '',
                                           };
                } else {
                    print "Don't know which tests failed: got $test{ok} ok, ".
                          "expected $test{max}\n";
                    $failedtests{$tfile} = { canon   => '??',
                                             max     => $test{max},
                                             failed  => '??',
                                             name    => $tfile, 
                                             percent => undef,
                                             estat   => '', 
                                             wstat   => '',
                                           };
                }
                $tot{bad}++;
            } elsif ($test{'next'} == 0) {
                print "FAILED before any test output arrived\n";
                $tot{bad}++;
                $failedtests{$tfile} = { canon       => '??',
                                         max         => '??',
                                         failed      => '??',
                                         name        => $tfile,
                                         percent     => undef,
                                         estat       => '', 
                                         wstat       => '',
                                       };
            }
        }

	$tot{sub_skipped} += $test{skipped};

	if (defined $Files_In_Dir) {
	    my @new_dir_files = _globdir $Files_In_Dir;
	    if (@new_dir_files != @dir_files) {
		my %f;
		@f{@new_dir_files} = (1) x @new_dir_files;
		delete @f{@dir_files};
		my @f = sort keys %f;
		print "LEAKED FILES: @f\n";
		@dir_files = @new_dir_files;
	    }
	}
    }
    $tot{bench} = timediff(new Benchmark, $t_start);

    if ($^O eq 'VMS') {
	if (defined $old5lib) {
	    $ENV{PERL5LIB} = $old5lib;
	} else {
	    delete $ENV{PERL5LIB};
	}
    }

    return(\%tot, \%failedtests);
}

=item B<_mk_leader>

  my($leader, $ml) = _mk_leader($test_file, $width);

Generates the 't/foo........' $leader for the given $test_file as well
as a similar version which will overwrite the current line (by use of
\r and such).  $ml may be empty if Test::Harness doesn't think you're
on TTY.  The width is the width of the "yada/blah..." string.

=cut

sub _mk_leader {
    my ($te, $width) = @_;

    $te =~ s/\.\w+$/./;

    if ($^O eq 'VMS') { $te =~ s/^.*\.t\./\[.t./s; }
    my $blank = (' ' x 77);
    my $leader = "$te" . '.' x ($width - length($te));
    my $ml = "";

    $ml = "\r$blank\r$leader"
      if -t STDOUT and not $ENV{HARNESS_NOTTY} and not $Verbose;

    return($leader, $ml);
}


sub _show_results {
    my($tot, $failedtests) = @_;

    my $pct;
    my $bonusmsg = _bonusmsg($tot);

    if ($tot->{bad} == 0 && $tot->{max}) {
	print "All tests successful$bonusmsg.\n";
    } elsif ($tot->{tests}==0){
	die "FAILED--no tests were run for some reason.\n";
    } elsif ($tot->{max} == 0) {
	my $blurb = $tot->{tests}==1 ? "script" : "scripts";
	die "FAILED--$tot->{tests} test $blurb could be run, ".
            "alas--no output ever seen\n";
    } else {
	$pct = sprintf("%.2f", $tot->{good} / $tot->{tests} * 100);
	my $subpct = sprintf " %d/%d subtests failed, %.2f%% okay.",
	                      $tot->{max} - $tot->{ok}, $tot->{max}, 
                              100*$tot->{ok}/$tot->{max};

        my($fmt_top, $fmt) = _create_fmts($failedtests);

	# Now write to formats
	for my $script (sort keys %$failedtests) {
	  $Curtest = $failedtests->{$script};
	  write;
	}
	if ($tot->{bad}) {
	    $bonusmsg =~ s/^,\s*//;
	    print "$bonusmsg.\n" if $bonusmsg;
	    die "Failed $tot->{bad}/$tot->{tests} test scripts, $pct% okay.".
                "$subpct\n";
	}
    }

    printf("Files=%d, Tests=%d, %s\n",
           $tot->{files}, $tot->{max}, timestr($tot->{bench}, 'nop'));
}


sub _parse_header {
    my($line, $test, $tot) = @_;

    my $is_header = 0;

    print $line if $Verbose;

    # 1..10 todo 4 7 10;
    if ($line =~ /^1\.\.([0-9]+) todo([\d\s]+);?/i) {
        $test->{max} = $1;
        for (split(/\s+/, $2)) { $test->{todo}{$_} = 1; }

        $tot->{max} += $test->{max};
        $tot->{files}++;

        $is_header = 1;
    }
    # 1..10
    # 1..0 # skip  Why?  Because I said so!
    elsif ($line =~ /^1\.\.([0-9]+)
                      (\s*\#\s*[Ss]kip\S*\s* (.+))?
                    /x
          )
    {
        $test->{max} = $1;
        $tot->{max} += $test->{max};
        $tot->{files}++;
        $test->{'next'} = 1 unless $test->{'next'};
        $test->{skip_reason} = $3 if not $test->{max} and defined $3;

        $is_header = 1;
    }
    else {
        $is_header = 0;
    }

    return $is_header;
}


sub _open_test {
    my($test) = shift;

    my $s = _set_switches($test);

    # XXX This is WAY too core specific!
    my $cmd = ($ENV{'HARNESS_COMPILE_TEST'})
                ? "./perl -I../lib ../utils/perlcc $test "
		  . "-r 2>> ./compilelog |" 
		: "$^X $s $test|";
    $cmd = "MCR $cmd" if $^O eq 'VMS';

    if( open(PERL, $cmd) ) {
        return \*PERL;
    }
    else {
        print "can't run $test. $!\n";
        return;
    }
}

sub _run_one_test {
    my($test) = @_;

    
}


sub _parse_test_line {
    my($line, $test, $tot) = @_;

    if ($line =~ /^(not\s+)?ok\b/i) {
        my $this = $test->{'next'} || 1;
        # "not ok 23"
        if ($line =~ /^(not )?ok\s*(\d*)(\s*#.*)?/) {
	    my($not, $tnum, $extra) = ($1, $2, $3);

	    $this = $tnum if $tnum;

	    my($type, $reason) = $extra =~ /^\s*#\s*([Ss]kip\S*|TODO)(\s+.+)?/
	      if defined $extra;

	    my($istodo, $isskip);
	    if( defined $type ) {
		$istodo = $type =~ /TODO/;
		$isskip = $type =~ /skip/i;
	    }

	    $test->{todo}{$tnum} = 1 if $istodo;

	    if( $not ) {
		print "$test->{ml}NOK $this" if $test->{ml};
		if (!$test->{todo}{$this}) {
		    push @{$test->{failed}}, $this;
		} else {
		    $test->{ok}++;
		    $tot->{ok}++;
		}
	    }
	    else {
		print "$test->{ml}ok $this/$test->{max}" if $test->{ml};
		$test->{ok}++;
		$tot->{ok}++;
		$test->{skipped}++ if $isskip;

		if (defined $reason and defined $test->{skip_reason}) {
		    # print "was: '$skip_reason' new '$reason'\n";
		    $test->{skip_reason} = 'various reasons'
		      if $test->{skip_reason} ne $reason;
		} elsif (defined $reason) {
		    $test->{skip_reason} = $reason;
		}

		$test->{bonus}++, $tot->{bonus}++ if $test->{todo}{$this};
	    }
        }
        # XXX ummm... dunno
        elsif ($line =~ /^ok\s*(\d*)\s*\#([^\r]*)$/) { # XXX multiline ok?
            $this = $1 if $1 > 0;
            print "$test->{ml}ok $this/$test->{max}" if $test->{ml};
            $test->{ok}++;
            $tot->{ok}++;
        }
        else {
            # an ok or not ok not matching the 3 cases above...
            # just ignore it for compatibility with TEST
            next;
        }

        if ($this > $test->{'next'}) {
            # print "Test output counter mismatch [test $this]\n";
            # no need to warn probably
            push @{$test->{failed}}, $test->{'next'}..$this-1;
        }
        elsif ($this < $test->{'next'}) {
            #we have seen more "ok" lines than the number suggests
            print "Confused test output: test $this answered after ".
                  "test ", $test->{'next'}-1, "\n";
            $test->{'next'} = $this;
        }
        $test->{'next'} = $this + 1;

    }
    elsif ($line =~ /^Bail out!\s*(.*)/i) { # magic words
        die "FAILED--Further testing stopped" .
            ($1 ? ": $1\n" : ".\n");
    }
}


sub _bonusmsg {
    my($tot) = @_;

    my $bonusmsg = '';
    $bonusmsg = (" ($tot->{bonus} subtest".($tot->{bonus} > 1 ? 's' : '').
	       " UNEXPECTEDLY SUCCEEDED)")
	if $tot->{bonus};

    if ($tot->{skipped}) {
	$bonusmsg .= ", $tot->{skipped} test"
                     . ($tot->{skipped} != 1 ? 's' : '');
	if ($tot->{sub_skipped}) {
	    $bonusmsg .= " and $tot->{sub_skipped} subtest"
			 . ($tot->{sub_skipped} != 1 ? 's' : '');
	}
	$bonusmsg .= ' skipped';
    }
    elsif ($tot->{sub_skipped}) {
	$bonusmsg .= ", $tot->{sub_skipped} subtest"
	             . ($tot->{sub_skipped} != 1 ? 's' : '')
		     . " skipped";
    }

    return $bonusmsg;
}

# VMS has some subtle nastiness with closing the test files.
sub _close_fh {
    my($fh) = shift;

    close($fh); # must close to reap child resource values

    my $wstatus = $Ignore_Exitcode ? 0 : $?;	# Can trust $? ?
    my $estatus;
    $estatus = ($^O eq 'VMS'
                  ? eval 'use vmsish "status"; $estatus = $?'
                  : $wstatus >> 8);

    return($estatus, $wstatus);
}


# Set up the command-line switches to run perl as.
sub _set_switches {
    my($test) = shift;

    local *TEST;
    open(TEST, $test) or print "can't open $test. $!\n";
    my $first = <TEST>;
    my $s = $Switches;
    $s .= " $ENV{'HARNESS_PERL_SWITCHES'}"
      if exists $ENV{'HARNESS_PERL_SWITCHES'};
    $s .= join " ", q[ "-T"], map {qq["-I$_"]} @INC
      if $first =~ /^#!.*\bperl.*-\w*T/;

    close(TEST) or print "can't close $test. $!\n";

    return $s;
}


# Test program go boom.
sub _dubious_return {
    my($test, $tot, $estatus, $wstatus) = @_;
    my ($failed, $canon, $percent) = ('??', '??');

    printf "$test->{ml}dubious\n\tTest returned status $estatus ".
           "(wstat %d, 0x%x)\n",
           $wstatus,$wstatus;
    print "\t\t(VMS status is $estatus)\n" if $^O eq 'VMS';

    if (corestatus($wstatus)) { # until we have a wait module
        if ($Have_Devel_Corestack) {
            Devel::CoreStack::stack($^X);
        } else {
            print "\ttest program seems to have generated a core\n";
        }
    }

    $tot->{bad}++;

    if ($test->{max}) {
        if ($test->{'next'} == $test->{max} + 1 and not @{$test->{failed}}) {
            print "\tafter all the subtests completed successfully\n";
            $percent = 0;
            $failed = 0;	# But we do not set $canon!
        }
        else {
            push @{$test->{failed}}, $test->{'next'}..$test->{max};
            $failed = @{$test->{failed}};
            (my $txt, $canon) = canonfailed($test->{max},$test->{skipped},@{$test->{failed}});
            $percent = 100*(scalar @{$test->{failed}})/$test->{max};
            print "DIED. ",$txt;
        }
    }

    return { canon => $canon,  max => $test->{max} || '??',
             failed => $failed, 
             percent => $percent,
             estat => $estatus, wstat => $wstatus,
           };
}


sub _garbled_output {
    my($gibberish) = shift;
    warn "Confusing test output:  '$gibberish'\n";
}


sub _create_fmts {
    my($failedtests) = @_;

    my $failed_str = "Failed Test";
    my $middle_str = " Stat Wstat Total Fail  Failed  ";
    my $list_str = "List of Failed";

    # Figure out our longest name string for formatting purposes.
    my $max_namelen = length($failed_str);
    foreach my $script (keys %$failedtests) {
        my $namelen = length $failedtests->{$script}->{name};
        $max_namelen = $namelen if $namelen > $max_namelen;
    }

    my $list_len = $Columns - length($middle_str) - $max_namelen;
    if ($list_len < length($list_str)) {
        $list_len = length($list_str);
        $max_namelen = $Columns - length($middle_str) - $list_len;
        if ($max_namelen < length($failed_str)) {
            $max_namelen = length($failed_str);
            $Columns = $max_namelen + length($middle_str) + $list_len;
        }
    }

    my $fmt_top = "format STDOUT_TOP =\n"
                  . sprintf("%-${max_namelen}s", $failed_str)
                  . $middle_str
		  . $list_str . "\n"
		  . "-" x $Columns
		  . "\n.\n";

    my $fmt = "format STDOUT =\n"
	      . "@" . "<" x ($max_namelen - 1)
              . "  @>> @>>>> @>>>> @>>> ^##.##%  "
	      . "^" . "<" x ($list_len - 1) . "\n"
	      . '{ $Curtest->{name}, $Curtest->{estat},'
	      . '  $Curtest->{wstat}, $Curtest->{max},'
	      . '  $Curtest->{failed}, $Curtest->{percent},'
	      . '  $Curtest->{canon}'
	      . "\n}\n"
	      . "~~" . " " x ($Columns - $list_len - 2) . "^"
	      . "<" x ($list_len - 1) . "\n"
	      . '$Curtest->{canon}'
	      . "\n.\n";

    eval $fmt_top;
    die $@ if $@;
    eval $fmt;
    die $@ if $@;

    return($fmt_top, $fmt);
}

{
    my $tried_devel_corestack;

    sub corestatus {
        my($st) = @_;

        eval {require 'wait.ph'};
        my $ret = defined &WCOREDUMP ? WCOREDUMP($st) : $st & 0200;

        eval { require Devel::CoreStack; $Have_Devel_Corestack++ } 
          unless $tried_devel_corestack++;

        $ret;
    }
}

sub canonfailed ($@) {
    my($max,$skipped,@failed) = @_;
    my %seen;
    @failed = sort {$a <=> $b} grep !$seen{$_}++, @failed;
    my $failed = @failed;
    my @result = ();
    my @canon = ();
    my $min;
    my $last = $min = shift @failed;
    my $canon;
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
	$canon = join ' ', @canon;
    } else {
	push @result, "FAILED test $last\n";
	$canon = $last;
    }

    push @result, "\tFailed $failed/$max tests, ";
    push @result, sprintf("%.2f",100*(1-$failed/$max)), "% okay";
    my $ender = 's' x ($skipped > 1);
    my $good = $max - $failed - $skipped;
    my $goodper = sprintf("%.2f",100*($good/$max));
    push @result, " (-$skipped skipped test$ender: $good okay, ".
                  "$goodper%)"
         if $skipped;
    push @result, "\n";
    my $txt = join "", @result;
    ($txt, $canon);
}

=end _private

=back

=cut


1;
__END__


=head1 EXPORT

C<&runtests> is exported by Test::Harness per default.

C<$verbose> and C<$switches> are exported upon request.


=head1 DIAGNOSTICS

=over 4

=item C<All tests successful.\nFiles=%d,  Tests=%d, %s>

If all tests are successful some statistics about the performance are
printed.

=item C<FAILED tests %s\n\tFailed %d/%d tests, %.2f%% okay.>

For any single script that has failing subtests statistics like the
above are printed.

=item C<Test returned status %d (wstat %d)>

Scripts that return a non-zero exit status, both C<$? E<gt>E<gt> 8>
and C<$?> are printed in a message similar to the above.

=item C<Failed 1 test, %.2f%% okay. %s>

=item C<Failed %d/%d tests, %.2f%% okay. %s>

If not all tests were successful, the script dies with one of the
above messages.

=item C<FAILED--Further testing stopped%s>

If a single subtest decides that further testing will not make sense,
the script dies with this message.

=back

=head1 ENVIRONMENT

=over 4

=item C<HARNESS_IGNORE_EXITCODE>

Makes harness ignore the exit status of child processes when defined.

=item C<HARNESS_NOTTY>

When set to a true value, forces it to behave as though STDOUT were
not a console.  You may need to set this if you don't want harness to
output more frequent progress messages using carriage returns.  Some
consoles may not handle carriage returns properly (which results in a
somewhat messy output).

=item C<HARNESS_COMPILE_TEST>

When true it will make harness attempt to compile the test using
C<perlcc> before running it.

B<NOTE> This currently only works when sitting in the perl source
directory!

=item C<HARNESS_FILELEAK_IN_DIR>

When set to the name of a directory, harness will check after each
test whether new files appeared in that directory, and report them as

  LEAKED FILES: scr.tmp 0 my.db

If relative, directory name is with respect to the current directory at
the moment runtests() was called.  Putting absolute path into 
C<HARNESS_FILELEAK_IN_DIR> may give more predicatable results.

=item C<HARNESS_PERL_SWITCHES>

Its value will be prepended to the switches used to invoke perl on
each test.  For example, setting C<HARNESS_PERL_SWITCHES> to C<-W> will
run all tests with all warnings enabled.

=item C<HARNESS_COLUMNS>

This value will be used for the width of the terminal. If it is not
set then it will default to C<COLUMNS>. If this is not set, it will
default to 80. Note that users of Bourne-sh based shells will need to
C<export COLUMNS> for this module to use that variable.

=item C<HARNESS_ACTIVE>

Harness sets this before executing the individual tests.  This allows
the tests to determine if they are being executed through the harness
or by any other means.

=back

=head1 EXAMPLE

Here's how Test::Harness tests itself

  $ cd ~/src/devel/Test-Harness
  $ perl -Mblib -e 'use Test::Harness qw(&runtests $verbose);
    $verbose=0; runtests @ARGV;' t/*.t
  Using /home/schwern/src/devel/Test-Harness/blib
  t/base..............ok
  t/nonumbers.........ok
  t/ok................ok
  t/test-harness......ok
  All tests successful.
  Files=4, Tests=24, 2 wallclock secs ( 0.61 cusr + 0.41 csys = 1.02 CPU)

=head1 SEE ALSO

L<Test> and L<Test::Simple> for writing test scripts, L<Benchmark> for
the underlying timing routines, L<Devel::CoreStack> to generate core
dumps from failed tests and L<Devel::Cover> for test coverage
analysis.

=head1 AUTHORS

Either Tim Bunce or Andreas Koenig, we don't know. What we know for
sure is, that it was inspired by Larry Wall's TEST script that came
with perl distributions for ages. Numerous anonymous contributors
exist.  Andreas Koenig held the torch for many years.

Current maintainer is Michael G Schwern E<lt>schwern@pobox.comE<gt>

=head1 TODO

Provide a way of running tests quietly (ie. no printing) for automated
validation of tests.  This will probably take the form of a version
of runtests() which rather than printing its output returns raw data
on the state of the tests.

Fix HARNESS_COMPILE_TEST without breaking its core usage.

Figure a way to report test names in the failure summary.

Rework the test summary so long test names are not truncated as badly.

Merge back into bleadperl.

Deal with VMS's "not \nok 4\n" mistake.

Add option for coverage analysis.

=for _private
Keeping whittling away at _run_all_tests()

=for _private
Clean up how the summary is printed.  Get rid of those damned formats.

=head1 BUGS

Test::Harness uses $^X to determine the perl binary to run the tests
with. Test scripts running via the shebang (C<#!>) line may not be
portable because $^X is not consistent for shebang scripts across
platforms. This is no problem when Test::Harness is run with an
absolute path to the perl binary or when $^X can be found in the path.

HARNESS_COMPILE_TEST currently assumes its run from the Perl source
directory.

=cut
