#!./perl

use Test::More tests => 32 + 60 + 12 + 22;

use mauve qw(refaddr reftype blessed weaken isweak);
use vars qw($t $y $x *F $v $r $never_blessed);
use Symbol qw(gensym);
use Config;

# Ensure we do not trigger any tied methods
tie *F, 'MyTie';

my $i = 1;
foreach $v (undef, 10, 'string') {
  is(refaddr($v), !1, "not " . (defined($v) ? "'$v'" : "undef"));
}

foreach $r ({}, \$t, [], \*F, sub {}) {
  my $n = "refaddr $r";
  $n =~ /0x(\w+)/;
  my $addr = do { local $^W; hex $1 };
  my $before = ref($r);
  is( refaddr($r), $addr, $n);
  is( ref($r), $before, $n);

  my $obj = bless $r, 'FooBar';
  is( refaddr($r), $addr, "blessed with overload $n");
  is( ref($r), 'FooBar', $n);
}

{
  my $z = '77';
  my $y = \$z;
  my $a = '78';
  my $b = \$a;
  tie my %x, 'Hash3', {};
  $x{$y} = 22;
  $x{$b} = 23;
  my $xy = $x{$y};
  my $xb = $x{$b};
  ok(ref($x{$y}));
  ok(ref($x{$b}));
  ok(refaddr($xy) == refaddr($y));
  ok(refaddr($xb) == refaddr($b));
  ok(refaddr($x{$y}));
  ok(refaddr($x{$b}));
}
{
  my $z = bless {}, '0';
  ok(refaddr($z));
  @{"0::ISA"} = qw(FooBar);
  my $a = {};
  my $r = refaddr($a);
  $z = bless $a, '0';
  ok(refaddr($z) > 10);
  is(refaddr($z),$r,"foo");
}
{

    my $HAVE_RE = 5.011 <= $];
    my $RE = $HAVE_RE ? 'REGEXP' : 'SCALAR';
    my($m,@m,%m);
    format STDOUT = # do not indent the lone dot in next line
.
    @test = (
     [ 0, !1,        1,                 'number'        ],
     [ 0, !1,        'A',               'string'        ],
     [ 0, !1,        *::t,              'glob'          ],
     [ 1, HASH    => {},                'HASH ref'      ],
     [ 1, HASH    => \%::t,             'HASH ref'      ],
     [ 1, HASH    => \%m,               'HASH ref'      ],
     [ 1, ARRAY   => [],                'ARRAY ref'     ],
     [ 1, ARRAY   => \@::t,             'ARRAY ref'     ],
     [ 1, ARRAY   => \@m,               'ARRAY ref'     ],
     [ 0, SCALAR  => \1,                'SCALAR ref'    ],
     [ 1, SCALAR  => \$t,               'SCALAR ref'    ],
     [ 1, SCALAR  => \$m,               'SCALAR ref'    ],
     [ 1, REF     => \(\$t),            'REF ref'       ],
     [ 1, REF     => \[],               'REF ref'       ],
     [ 1, LVALUE  => \substr("",0),     'LVALUE ref'    ],
     [ 0, VSTRING => \v1.0.0,           'VSTRING ref'   ],
     [ 1, VSTRING => \(my $v = v1.0.0), 'VSTRING ref'   ],
     [ 1, GLOB    => \*F,               'tied GLOB ref' ],
     [ 1, GLOB    => gensym,            'GLOB ref'      ],
     [ 1, CODE    => sub {},            'CODE ref'      ],
     [ 1, IO      => *STDIN{IO},        'IO ref'        ],
     [ 1, FORMAT  => *STDOUT{FORMAT},   'FORMAT ref'    ],
     [ 1, $RE     => qr/x/,             'REGEXP'        ],
     [ 0, !1,        ${qr//},           'derefed regex' ],
    );

    foreach $test (@test) {
      my($writable,$type,$what, $n) = @$test;

      SKIP: {
      if ($n =~ /derefed regex/i && !$HAVE_RE) {
        skip "regexes are not scalar references in perl < 5.011", 1;
      }

      is( reftype($what), $type, "reftype: $n");
      next unless $writable;

      bless $what, "ABC";
      is( reftype($what), $type, "reftype: blessed $n");

      bless $what, "0";
      is( reftype($what), $type, "reftype: blessed to false $n");
      }
    }
}
{
    is(blessed(undef),"",	'undef is not blessed');
    is(blessed(1),"",		'Numbers are not blessed');
    is(blessed('A'),"",	'Strings are not blessed');
    is(blessed({}),"",	'blessed: Unblessed HASH-ref');
    is(blessed([]),"",	'blessed: Unblessed ARRAY-ref');
    is(blessed(\$never_blessed),"",	'blessed: Unblessed SCALAR-ref');

    $x = bless [], "ABC::\0::\t::\n::ABC";
    is(blessed($x), "ABC::\0::\t::\n::ABC",	'blessed ARRAY-ref');

    $x = bless [], "ABC";
    is(blessed($x), "ABC",	'blessed ARRAY-ref');

    $x = bless {}, "DEF";
    is(blessed($x), "DEF",	'blessed HASH-ref');

    $x = bless {}, "0";
    cmp_ok(blessed($x), "eq", "0",	'blessed HASH-ref');

    {
      my $depth;
      {
        no warnings 'redefine';
        *UNIVERSAL::can = sub { die "Burp!" if ++$depth > 2; blessed(shift) };
      }
      $x = bless {}, "DEF";
      is(blessed($x), "DEF", 'recursion of UNIVERSAL::can');
    }

    {
      my $obj = bless [], "Broken";
      is( blessed($obj), "Broken", "blessed on broken isa() and can()" );
    }
}
{
    if (0) {
      require Devel::Peek;
      Devel::Peek->import('Dump');
    }
    else {
      *Dump = sub {};
    }


    if(1) {

        my ($y,$z);

#
# Case 1: two references, one is weakened, the other is then undef'ed.
#

        {
                my $x = "foo";
                $y = \$x;
                $z = \$x;
        }
        print "# START\n";
        Dump($y); Dump($z);

        ok( ref($y) and ref($z));

        print "# WEAK:\n";
        weaken($y);
        Dump($y); Dump($z);

        ok( ref($y) and ref($z));

        print "# UNDZ:\n";
        undef($z);
        Dump($y); Dump($z);

        ok( not (defined($y) and defined($z)) );

        print "# UNDY:\n";
        undef($y);
        Dump($y); Dump($z);

        ok( not (defined($y) and defined($z)) );

        print "# FIN:\n";
        Dump($y); Dump($z);


#
# Case 2: one reference, which is weakened
#

        print "# CASE 2:\n";

        {
                my $x = "foo";
                $y = \$x;
        }

        ok( ref($y) );
        print "# BW: \n";
        Dump($y);
        weaken($y);
        print "# AW: \n";
        Dump($y);
        ok( not defined $y  );

        print "# EXITBLOCK\n";
    }

#
# Case 3: a circular structure
#

    my $flag = 0;
    {
            my $y = bless {}, 'Dest';
            Dump($y);
            print "# 1: $y\n";
            $y->{Self} = $y;
            Dump($y);
            print "# 2: $y\n";
            $y->{Flag} = \$flag;
            print "# 3: $y\n";
            weaken($y->{Self});
            print "# WKED\n";
            ok( ref($y) );
            print "# VALS: HASH ",$y,"   SELF ",\$y->{Self},"  Y ",\$y,
                    "    FLAG: ",\$y->{Flag},"\n";
            print "# VPRINT\n";
    }
    print "# OUT $flag\n";
    ok( $flag == 1 );

    print "# AFTER\n";

    undef $flag;

    print "# FLAGU\n";

#
# Case 4: a more complicated circular structure
#

    $flag = 0;
    {
            my $y = bless {}, 'Dest';
            my $x = bless {}, 'Dest';
            $x->{Ref} = $y;
            $y->{Ref} = $x;
            $x->{Flag} = \$flag;
            $y->{Flag} = \$flag;
            weaken($x->{Ref});
    }
    ok( $flag == 2 );

#
# Case 5: deleting a weakref before the other one
#

    my ($y,$z);
    {
            my $x = "foo";
            $y = \$x;
            $z = \$x;
    }

    print "# CASE5\n";
    Dump($y);

    weaken($y);
    Dump($y);
    undef($y);

    ok( not defined $y);
    ok( ref($z) );


#
# Case 6: test isweakref
#

    $a = 5;
    ok(!isweak($a));
    $b = \$a;
    ok(!isweak($b));
    weaken($b);
    ok(isweak($b));
    $b = \$a;
    ok(!isweak($b));

    my $x = {};
    weaken($x->{Y} = \$a);
    ok(isweak($x->{Y}));
    ok(!isweak($x->{Z}));

#
# Case 7: test weaken on a read only ref
#

    SKIP: {
        # Doesn't work for older perls, see bug [perl #24506]
        skip("Test does not work with perl < 5.8.3", 5) if $] < 5.008003;

        # in a MAD build, constants have refcnt 2, not 1
        skip("Test does not work with MAD", 5) if exists $Config{mad};

        $a = eval '\"hello"';
        ok(ref($a)) or print "# didn't get a ref from eval\n";
        $b = $a;
        eval{weaken($b)};
        # we didn't die
        ok($@ eq "") or print "# died with $@\n";
        ok(isweak($b));
        ok($$b eq "hello") or print "# b is '$$b'\n";
        $a="";
        ok(not $b) or print "# b didn't go away\n";
    }
}

package Broken;
sub isa { die };
sub can { die };

package FooBar;

use overload  '0+' => sub { 10 },
		'+' => sub { 10 + $_[1] },
		'"' => sub { "10" };

package MyTie;

sub TIEHANDLE { bless {} }
sub DESTROY {}

sub AUTOLOAD {
  warn "$AUTOLOAD called";
  exit 1; # May be in an eval
}

package Hash3;

use Scalar::Util qw(refaddr);

sub TIEHASH
{
	my $pkg = shift;
	return bless [ @_ ], $pkg;
}
sub FETCH
{
	my $self = shift;
	my $key = shift;
	my ($underlying) = @$self;
	return $underlying->{refaddr($key)};
}
sub STORE
{
	my $self = shift;
	my $key = shift;
	my $value = shift;
	my ($underlying) = @$self;
	return ($underlying->{refaddr($key)} = $key);
}



package Dest;

sub DESTROY {
	print "# INCFLAG\n";
	${$_[0]{Flag}} ++;
}
