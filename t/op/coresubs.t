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

my %op_desc = (
 readpipe => 'quoted execution (``, qx)',
 ref      => 'reference-type operator',
);
sub op_desc($) {
  return $op_desc{$_[0]} || $_[0];
}


# This tests that the &{} syntax respects the number of arguments implied
# by the prototype, plus some extra tests for the (_) prototype.
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
  elsif ($p eq '_') {
    $tests ++;

    eval " &CORE::$o(1,2) ";
    my $desc = quotemeta op_desc($o);
    like $@, qr/^Too many arguments for $desc at /,
      "&$o with too many args";

    if (!@_) { return }

    $tests += 6;

    my($in,$out) = @_; # for testing implied $_

    # Since we have $in and $out values, we might as well test basic amper-
    # sand calls, too.

    is &{"CORE::$o"}($in), $out, "&$o";
    lis [&{"CORE::$o"}($in)], [$out], "&$o in list context";

    $_ = $in;
    is &{"CORE::$o"}(), $out, "&$o with no args";

    # Since there is special code to deal with lexical $_, make sure it
    # works in all cases.
    undef $_;
    {
      my $_ = $in;
      is &{"CORE::$o"}(), $out, "&$o with no args uses lexical \$_";
    }
    # Make sure we get the right pad under recursion
    my $r;
    $r = sub {
      if($_[0]) {
        my $_ = $in;
        is &{"CORE::$o"}(), $out,
           "&$o with no args uses the right lexical \$_ under recursion";
      }
      else {
        &$r(1)
      }
    };
    &$r(0);
    my $_ = $in;
    eval {
       is "CORE::$o"->(), $out, "&$o with the right lexical \$_ in an eval"
    };   
  }
  elsif ($p =~ '^([$*]+);?\z') { # Fixed-length $$$ or ***
    my $args = length $1;
    $tests += 2;    
    eval " &CORE::$o((1)x($args-1)) ";
    like $@, qr/^Not enough arguments for $o at /, "&$o with too few args";
    eval " &CORE::$o((1)x($args+1)) ";
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

test_proto 'abs', -5, 5;
test_proto 'alarm';
test_proto 'atan2';

test_proto 'break';
{ $tests ++;
  my $tmp;
  CORE::given(1) {
    CORE::when(1) {
      &mybreak;
      $tmp = 'bad';
    }
  }
  is $tmp, undef, '&break';
}

test_proto 'chr', 5, "\5";
test_proto 'chroot';
test_proto 'continue';
$tests ++;
CORE::given(1) {
  CORE::when(1) {
    &mycontinue();
  }
  pass "&continue";
}

test_proto 'cos';
test_proto 'crypt';

test_proto $_ for qw(
 endgrent endhostent endnetent endprotoent endpwent endservent
);

test_proto 'fork';
test_proto 'exp';

test_proto "get$_" for qw '
  grent grgid grnam hostbyaddr hostbyname hostent login netbyaddr netbyname
  netent ppid priority protobyname protobynumber protoent
  pwent pwnam pwuid servbyname servbyport servent
';

test_proto 'hex', ff=>255;
test_proto 'int', 1.5=>1;
test_proto 'lc', 'A', 'a';
test_proto 'lcfirst', 'AA', 'aA';
test_proto 'length', 'aaa', 3;
test_proto 'link';
test_proto 'log';
test_proto "msg$_" for qw( ctl get rcv snd );

test_proto 'not';
$tests += 2;
is &mynot(1), !1, '&not';
lis [&mynot(0)], [!0], '&not in list context';

test_proto 'oct', '666', 438;
test_proto 'ord', chr(64), 64;
test_proto 'quotemeta', '$', '\$';
test_proto 'readlink';
test_proto 'readpipe';

use if !is_miniperl, File::Spec::Functions, qw "catfile";
use if !is_miniperl, File::Temp, 'tempdir';

test_proto 'rename';
{
    last if is_miniperl;
    $tests ++;
    my $dir = tempdir(uc cleanup => 1);
    my $tmpfilenam = catfile $dir, 'aaa';
    open my $fh, ">", $tmpfilenam or die "cannot open $tmpfilenam: $!";
    close $fh or die "cannot close $tmpfilenam: $!";
    &myrename("$tmpfilenam", $tmpfilenam = catfile $dir,'bbb');
    ok open(my $fh, '>', $tmpfilenam), '&rename';
}

test_proto 'ref', [], 'ARRAY';
test_proto 'rmdir';
test_proto "sem$_" for qw "ctl get op";

test_proto "set$_" for qw '
  grent hostent netent priority protoent pwent servent
';

test_proto "shm$_" for qw "ctl get read write";
test_proto 'sin';
test_proto 'sqrt', 4, 2;
test_proto 'symlink';

test_proto 'time';
$tests += 2;
like &mytime, '^\d+\z', '&time in scalar context';
like join('-', &mytime), '^\d+\z', '&time in list context';

test_proto 'times';
$tests += 2;
like &mytimes, '^[\d.]+\z', '&times in scalar context';
like join('-',&mytimes), '^[\d.]+-[\d.]+-[\d.]+-[\d.]+\z',
   '&times in list context';

test_proto 'uc', 'aa', 'AA';
test_proto 'ucfirst', 'aa', "Aa";

test_proto 'vec';
$tests += 3;
is &myvec("foo", 0, 4), 6, '&vec';
lis [&myvec("foo", 0, 4)], [6], '&vec in list context';
$tmp = "foo";
++&myvec($tmp,0,4);
is $tmp, "goo", 'lvalue &vec';

test_proto 'wait';
test_proto 'waitpid';

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
