#!./perl

# This file tests the results of calling subroutines in the CORE::
# namespace with ampersand syntax.  In other words, it tests the bodies of
# the subroutines themselves, not the ops that they might inline themselves
# as when called as barewords.

# coreinline.t tests the inlining of these subs as ops.  Since it was
# convenient, I also put the prototype and undefinedness checking in that
# file, even though those have nothing to do with inlining.  (coreinline.t
# reads the list in keywords.pl, which is why it’s convenient.)

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
    require "test.pl";
    $^P |= 0x100;
}
# Since tests inside evals can too easily fail silently, we cannot rely
# on done_testing. It’s much easier to count the tests as we go than to
# declare the plan up front, so this script ends with a test that makes
# sure the right number of tests have happened.

sub lis($$;$) {
  &is(map(@$_ ? "[@{[map $_//'~~u~~', @$_]}]" : 'nought', @_[0,1]), $_[2]);
}

# This tests that the &{} syntax respects the number of arguments implied
# by the prototype.
sub test_proto {
  my($o) = shift;

  # Create an alias, for the caller’s convenience.
  *{"my$o"} = \&{"CORE::$o"};

  my $p = prototype "CORE::$o";

  if ($p eq '') {
    $tests ++;

    eval " &CORE::$o(1) ";
    like $@, qr/^Too many arguments for $o at /, "&$o with too many args";

  }

  else {
    die "Please add tests for the $p prototype";
  }
}

test_proto '__FILE__';
test_proto '__LINE__';
test_proto '__PACKAGE__';

is file(), 'frob'    , '__FILE__ does check its caller'   ; ++ $tests;
is line(),  5        , '__LINE__ does check its caller'   ; ++ $tests;
is pakg(), 'stribble', '__PACKAGE__ does check its caller'; ++ $tests;

test_proto 'continue';
$tests ++;
CORE::given(1) {
  CORE::when(1) {
    &mycontinue();
  }
  pass "&continue";
}

test_proto $_ for qw(
 endgrent endhostent endnetent endprotoent endpwent endservent
);

test_proto 'fork';

test_proto "get$_" for qw '
  grent hostent login
  netent ppid protoent
  pwent servent
';

test_proto "set$_" for qw '
  grent pwent
';

test_proto 'time';
$tests += 2;
like &mytime, '^\d+\z', '&time in scalar context';
like join('-', &mytime), '^\d+\z', '&time in list context';

test_proto 'times';
$tests += 2;
like &mytimes, '^[\d.]+\z', '&times in scalar context';
like join('-',&mytimes), '^[\d.]+-[\d.]+-[\d.]+-[\d.]+\z',
   '&times in list context';

test_proto 'wait';

test_proto 'wantarray';
$tests += 4;
my $context;
my $cx_sub = sub {
  $context = qw[void scalar list][&mywantarray + defined mywantarray()]
};
() = &$cx_sub;
is $context, 'list', '&wantarray with caller in list context';
scalar &$cx_sub;
is($context, 'scalar', '&wantarray with caller in scalar context');
&$cx_sub;
is($context, 'void', '&wantarray with caller in void context');
lis [&mywantarray],[wantarray], '&wantarray itself in list context';


# Add new tests above this line.

# ------------ END TESTING ----------- #

is curr_test, $tests+1, 'right number of tests';
done_testing;

#line 3 frob

sub file { &CORE::__FILE__ }
sub line { &CORE::__LINE__ } # 5
package stribble;
sub main::pakg { &CORE::__PACKAGE__ }

# Please do not add new tests here.
