#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
    require './test.pl';
}
plan tests => 5;

is \lock $foo, \$foo, 'lock returns a scalar argument';
is  lock @foo, \@foo, 'lock returns a ref to its array argument';
is  lock %foo, \%foo, 'lock returns a ref to its hash argument';
eval { lock &foo }; my $file = __FILE__; my $line = __LINE__;
is $@, "Can't modify non-lvalue subroutine call at $file line $line.\n",
     'Error when locking non-lvalue sub';

sub eulavl : lvalue { $x }
is \lock &eulavl, \$x, 'locking lvalue sub acts on retval, just like tie';
