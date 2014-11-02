#!perl

# Test the various op trees that turn sub () { ... } into a constant, and
# some variants that don’t.

BEGIN {
    chdir 't';
    require './test.pl';
    @INC = '../lib';
}
plan 56;

# @tests is an array of hash refs, each of which can have various keys:
#
#   nickname    - name of the sub to use in test names
#   generator   - a sub returning a code ref to test
#   finally     - sub to run after the tests
#
# Each of the following gives expected test results.  If the key is
# omitted, the test is skipped:
#
#   retval      - the returned code ref’s return value
#   same_retval - whether the same scalar is returned each time
#   inlinable   - whether the sub is inlinable
#   deprecated  - whether the sub returning a code ref will emit a depreca-
#                 tion warning when called
#   method      - whether the sub has the :method attribute

# [perl #63540] Don’t treat sub { if(){.....}; "constant" } as a constant
sub blonk { ++$blonk_was_called }
push @tests, {
  nickname    => 'sub with null+kids (if-block), then constant',
  generator   => sub {
    # This used to turn into a constant with the value of $x
    my $x = 7;
    sub() { if($x){ () = "tralala"; blonk() }; 0 }
  },
  retval      => 0,
  same_retval => 0,
  inlinable   => 0,
  deprecated  => 0,
  method      => 0,
  finally     => sub { ok($blonk_was_called, 'RT #63540'); },
};

# [perl #79908]
push @tests, {
  nickname    => 'sub with simple lexical modified elsewhere',
  generator   => sub { my $x = 5; my $ret = sub(){$x}; $x = 7; $ret },
  retval      => 5, # change to 7 when the deprecation cycle is over
  same_retval => 0,
  inlinable   => 1,
  deprecated  => 1,
  method      => 0,
};

push @tests, {
  nickname    => 'sub with simple lexical unmodified elsewhere',
  generator   => sub { my $x = 5; sub(){$x} },
  retval      => 5,
  same_retval => 0,
  inlinable   => 1,
  deprecated  => 0,
  method      => 0,
};

push @tests, {
  nickname    => 'return $variable modified elsewhere',
  generator   => sub { my $x=5; my $ret = sub(){return $x}; $x = 7; $ret },
  retval      => 7,
  same_retval => 0,
  inlinable   => 0,
  deprecated  => 0,
  method      => 0,
};

push @tests, {
  nickname    => 'return $variable unmodified elsewhere',
  generator   => sub { my $x = 5; sub(){return $x} },
  retval      => 5,
  same_retval => 0,
  inlinable   => 0,
  deprecated  => 0,
  method      => 0,
};

push @tests, {
  nickname    => 'sub () { 0; $x } with $x modified elsewhere',
  generator   => sub { my $x = 5; my $ret = sub(){0;$x}; $x = 8; $ret },
  retval      => 8,
  same_retval => 0,
  inlinable   => 0,
  deprecated  => 0,
  method      => 0,
};

push @tests, {
  nickname    => 'sub () { 0; $x } with $x unmodified elsewhere',
  generator   => sub { my $x = 5; my $y = $x; sub(){0;$x} },
  retval      => 5,
  same_retval => 0,
  inlinable   => 1,
  deprecated  => 0,
  method      => 0,
};

# Explicit return after optimised statement, not at end of sub
push @tests, {
  nickname    => 'sub () { 0; return $x; ... }',
  generator   => sub { my $x = 5; sub () { 0; return $x; ... } },
  retval      => 5,
  same_retval => 0,
  inlinable   => 0,
  deprecated  => 0,
  method      => 0,
};

# Explicit return after optimised statement, at end of sub [perl #123092]
push @tests, {
  nickname    => 'sub () { 0; return $x }',
  generator   => sub { my $x = 5; sub () { 0; return $x } },
  retval      => 5,
  same_retval => 0,
  inlinable   => 0,
  deprecated  => 0,
  method      => 0,
};

use feature 'state', 'lexical_subs';
no warnings 'experimental::lexical_subs';

push @tests, {
  nickname    => 'sub () { my $x; state sub z { $x } $outer }',
  generator   => sub {
    my $outer = 43;
    sub () { my $x; state sub z { $x } $outer }
  },
  retval      => 43,
  same_retval => 0,
  inlinable   => 0,
  deprecated  => 0,
  method      => 0,
};

push @tests, {
  nickname    => 'sub:method with simple lexical',
  generator   => sub { my $y; sub():method{$y} },
  retval      => undef,
  same_retval => 0,
  inlinable   => 1,
  deprecated  => 0,
  method      => 1,
};


use feature 'refaliasing';
no warnings 'experimental::refaliasing';
for \%_ (@tests) {
    my $nickname = $_{nickname};
    my $w;
    local $SIG{__WARN__} = sub { $w = shift };
    my $sub = &{$_{generator}};
    if (exists $_{deprecated}) {
        if ($_{deprecated}) {
            like $w, qr/^Constants from lexical variables potentially (?x:
                       )modified elsewhere are deprecated at /,
                "$nickname is deprecated";
        }
        else {
            is $w, undef, "$nickname is not deprecated";
        }
    }
    if (exists $_{retval}) {
        is &$sub, $_{retval}, "retval of $nickname";
    }
    if (exists $_{same_retval}) {
        my $same = $_{same_retval} ? "same" : "different";
        &{$_{same_retval} ? \&is : \&isnt}(
            \scalar &$sub(), \scalar &$sub(),
            "$nickname gives $same retval each call"
        );
    }
    if (exists $_{inlinable}) {
        local *temp_inlinability_test = $sub;
        $w = undef;
        use warnings 'redefine';
        *temp_inlinability_test = sub (){};
	my $S = $_{inlinable} ? "Constant s" : "S";
        my $not = " not" x! $_{inlinable};
        like $w, qr/^${S}ubroutine .* redefined at /,
                "$nickname is$not inlinable";
    }
    if (exists $_{method}) {
        local *time = $sub;
        $w = undef;
        use warnings 'ambiguous';
        eval "()=time";
        if ($_{method}) {
            is $w, undef, "$nickname has :method attribute";
        }
        else {
            like $w, qr/^Ambiguous call resolved as CORE::time\(\), (?x:
                        )qualify as such or use & at /,
                "$nickname has no :method attribute";
        }
    }

    &{$_{finally} or next}
}
