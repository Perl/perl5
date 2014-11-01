#!perl

# Test the various op trees that turn sub () { ... } into a constant, and
# some variants that don’t.

BEGIN {
    chdir 't';
    require './test.pl';
    @INC = '../lib';
}
plan 6;

# [perl #63540] Don’t treat sub { if(){.....}; "constant" } as a constant

BEGIN {
  my $x = 7;
  *baz = sub() { if($x){ () = "tralala"; blonk() }; 0 }
}
{
  my $blonk_was_called;
  *blonk = sub { ++$blonk_was_called };
  my $ret = baz();
  is($ret, 0, 'RT #63540');
  is($blonk_was_called, 1, 'RT #63540');
}

# [perl #79908]
{
    my $x = 5;
    *_79908 = sub (){$x};
    $x = 7;
    TODO: {
        local $TODO = "Should be fixed with a deprecation cycle, see 'How about having a recommended way to add constant subs dynamically?' on p5p";
        is eval "_79908", 7, 'sub(){$x} does not break closures';
    }
    isnt eval '\_79908', \$x, 'sub(){$x} returns a copy';
    ok eval '\_79908 != \_79908', 'sub(){$x} returns a copy each time';

    # Test another thing that was broken by $x inlinement
    my $y;
    local *time = sub():method{$y};
    my $w;
    local $SIG{__WARN__} = sub { $w .= shift };
    eval "()=time";
    is $w, undef,
          '*keyword = sub():method{$y} does not cause ambiguity warnings';
}

