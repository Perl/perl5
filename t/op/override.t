#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

#
# This file tries to test builtin override using CORE::GLOBAL and
# importation.
#

# Test that every keyword is overridable under the overrides feature.

use File::Spec::Functions;
use subs ();

my $keywords_file = catfile(updir,'regen','keywords.pl');
open my $kh, $keywords_file
   or die "$0 cannot open $keywords_file: $!";

my $keyword_count;

while($_ = CORE::readline $kh) {
  if (m?__END__?..${\0} and /^\+/) {
    chomp(my $word = $');
    next if $word =~ /^(?:require|glob|do)/; # tested separately
    $keyword_count++;
    my $rand = rand;
    my $args;
    use feature sprintf(":%vd", $^V), # need to use the latest, to make
               'overrides';           # sure we test all keywords properly
    local *$word = sub { $args = @_; $rand };
    subs->import($word);
    local $_; # to avoid strange side effects when tests fail
    is eval qq{$word {}}, $rand, "$word under 'overrides' feature";
    no feature 'overrides';
    undef $args;
    {
      local(*STDOUT, *STDERR); # suppress print output
      eval qq{$word {}};
    }
    is $args, undef, "$word outside of 'overrides' feature";
  }
}

close $kh or die "$0 cannot close $keywords_file: $!";


my $more_tests = 38;

my $dirsep = "/";

BEGIN { package Foo; *main::getlogin = sub { "kilroy"; } }

is( getlogin, "kilroy" );

my $t = 42;
BEGIN { *CORE::GLOBAL::time = sub () { $t; } }

is( 45, time + 3 );

#
# require has special behaviour
#
my $r;
BEGIN { *CORE::GLOBAL::require = sub { $r = shift; 1; } }

require Foo;
is( $r, "Foo.pm" );

require Foo::Bar;
is( $r, join($dirsep, "Foo", "Bar.pm") );

require 'Foo';
is( $r, "Foo" );

undef $r;
require 5.006;
is( $r, undef );

require v5.6;
is( $r, undef );

eval "use 5.006";
is( $r, undef );

eval "use Foo";
is( $r, "Foo.pm" );

eval "use Foo::Bar";
is( $r, join($dirsep, "Foo", "Bar.pm") );

{
    local *CORE::GLOBAL::require = do {
	use feature "overrides";
	sub { $r = shift; 1; };
    };

    eval q{
	require 5.006;
	is( $r, "5.006" );

	require v5.6;
	is( $r, "\x05\x06" );

	require frimpulator;
	is( $r, "frimpulator" );
    }
}

{
    local $_ = 'foo.pm';
    require;
    is( $r, 'foo.pm' );
}

{
    my $_ = 'bar.pm';
    require;
    is( $r, 'bar.pm' );
}

# localizing *CORE::GLOBAL::foo should revert to finding CORE::foo
{
    local(*CORE::GLOBAL::require);
    $r = '';
    eval "require NoNeXiSt;";
    ok( ! ( $r or $@ !~ /^Can't locate NoNeXiSt/i ) );
}

#
# readline() has special behaviour too
#

$r = 11;
BEGIN { *CORE::GLOBAL::readline = sub (;*) { ++$r }; }
is( <FH>	, 12 );
is( <$fh>	, 13 );
my $pad_fh;
is( <$pad_fh>	, 14 );

# Non-global readline() override
BEGIN { *Rgs::readline = sub (;*) { --$r }; }
{
    package Rgs;
    ::is( <FH>	, 13 );
    ::is( <$fh>	, 12 );
    ::is( <$pad_fh>	, 11 );
}

# Global readpipe() override
BEGIN { *CORE::GLOBAL::readpipe = sub ($) { "$_[0] " . --$r }; }
is( `rm`,	    "rm 10", '``' );
is( qx/cp/,	    "cp 9", 'qx' );

# Non-global readpipe() override
BEGIN { *Rgs::readpipe = sub ($) { ++$r . " $_[0]" }; }
{
    package Rgs;
    ::is( `rm`,		  "10 rm", '``' );
    ::is( qx/cp/,	  "11 cp", 'qx' );
}

# Verify that the parsing of overridden keywords isn't messed up
# by the indirect object notation
{
    local $SIG{__WARN__} = sub {
	::like( $_[0], qr/^ok overriden at/ );
    };
    BEGIN { *OverridenWarn::warn = sub { CORE::warn "@_ overriden"; }; }
    package OverridenWarn;
    sub foo { "ok" }
    warn( OverridenWarn->foo() );
    warn OverridenWarn->foo();
}
BEGIN { *OverridenPop::pop = sub { ::is( $_[0][0], "ok" ) }; }
{
    package OverridenPop;
    sub foo { [ "ok" ] }
    pop( OverridenPop->foo() );
    pop OverridenPop->foo();
}

{
    eval {
        local *CORE::GLOBAL::require = sub {
            CORE::require($_[0]);
        };
        require 5;
        require Text::ParseWords;
    };
    is $@, '';
}

# glob

{
    my $args;
    local *CORE::GLOBAL::glob = sub { $args = @_ };
    eval '</>';
    is $args, 1, 'glob callback called by <...>';
    undef $args;
    eval 'glob "foo"';
    is $args, 1, 'glob callback called by glob';
    undef $args;
    ok !eval 'glob "foo", "bar"; 1', 'glob prototype is immutable';
    {
	use feature 'overrides';
	undef *CORE::GLOBAL::glob;
	*CORE::GLOBAL::glob = sub { $args = @_ }
    }
    undef $args;
    eval 'glob "foo", "bar"';
    is $args, 2, 'glob prototype is overridable under overrides feature';
}

# do

{
    my($args, @args);
    local *CORE::GLOBAL::do = sub { $args = @args = @_ };
    eval 'do "foo"';
    is $args, 1, 'do callback called by do';
    undef $args;
    eval 'do {}';
    is $args, undef, 'do-BLOCK ignores callback';
    {
	use feature 'overrides';
	*CORE::GLOBAL::do = sub { $args = @args = @_ }
    }
    undef @args;
    eval 'do {}';
    is ref $args[0], 'HASH',
	'do override handles do-BLOCK (or hash) under overrides feature';
}

done_testing $more_tests+$keyword_count*2;
