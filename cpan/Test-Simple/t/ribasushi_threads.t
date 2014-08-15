use Config;

BEGIN {
    if ($] == 5.010000) {
        print "1..0 # Threads are broken on 5.10.0\n";
        exit 0;
    }

    my $works = 1;
    $works &&= $] >= 5.008001;
    $works &&= $Config{'useithreads'};
    $works &&= eval { require threads; 'threads'->import; 1 };

    unless ($works) {
        print "1..0 # Skip no working threads\n";
        exit 0;
    }

    unless ( $ENV{AUTHOR_TESTING} ) {
        print "1..0 # Skip many perls have broken threads.  Enable with AUTHOR_TESTING.\n";
        exit 0;
    }

    if ($INC{'Devel/Cover.pm'}) {
        print "1..0 # SKIP Devel::Cover does not work with threads yet\n";
        exit 0;
    }
}

use threads;

use strict;
use warnings;

use Test::More;

# basic tests
{
  pass('Test starts');
  my $ct_num = Test::More->builder->current_test;

  my $newthread = async {
    my $out = '';

    #simulate a  subtest to not confuse the parent TAP emission
    my $tb = Test::More->builder;
    $tb->reset;
    Test::More->builder->current_test(0);
    for (qw/output failure_output todo_output/) {
      close $tb->$_;
      open ($tb->$_, '>', \$out);
    }

    pass("In-thread ok") for (1,2,3);

    done_testing;

    close $tb->$_ for (qw/output failure_output todo_output/);
    sleep(1); # tasty crashes without this

    $out;
  };
  die "Thread creation failed: $! $@" if !defined $newthread;

  my $out = $newthread->join;
  $out =~ s/^/   /gm;
  print $out;

  # workaround for older Test::More confusing the plan under threads
  Test::More->builder->current_test($ct_num);

  pass("Made it to the end");
}

done_testing;
