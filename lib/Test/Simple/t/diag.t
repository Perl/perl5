#!perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;

use Test::More tests => 5;

my $Test = Test::More->builder;

# now make a filehandle where we can send data
my $output;
tie *FAKEOUT, 'FakeOut', \$output;

# force diagnostic output to a filehandle, glad I added this to Test::Builder :)
my @lines;
{
    local $TODO = 1;
    $Test->todo_output(\*FAKEOUT);

    diag("a single line");

    push @lines, $output;
    $output = '';

    diag("multiple\n", "lines");
    push @lines, split(/\n/, $output);
}

is( @lines, 3,              'diag() should send messages to its filehandle' );
like( $lines[0], '/^#\s+/', '    should add comment mark to all lines' );
is( $lines[0], "# a single line\n",   '    should send exact message' );
is( $output, "# multiple\n# lines\n", '    should append multi messages');

{
    local $TODO = 1;
    $output = '';
    diag("# foo");
}
is( $output, "# # foo\n",   "diag() adds a # even if there's one already" );


package FakeOut;

sub TIEHANDLE {
	bless( $_[1], $_[0] );
}

sub PRINT {
	my $self = shift;
	$$self .= join('', @_);
}
#!perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;

use Test::More tests => 5;

my $Test = Test::More->builder;

# now make a filehandle where we can send data
my $output;
tie *FAKEOUT, 'FakeOut', \$output;

# force diagnostic output to a filehandle, glad I added this to Test::Builder :)
my @lines;
{
    local $TODO = 1;
    $Test->todo_output(\*FAKEOUT);

    diag("a single line");

    push @lines, $output;
    $output = '';

    diag("multiple\n", "lines");
    push @lines, split(/\n/, $output);
}

is( @lines, 3,              'diag() should send messages to its filehandle' );
like( $lines[0], '/^#\s+/', '    should add comment mark to all lines' );
is( $lines[0], "# a single line\n",   '    should send exact message' );
is( $output, "# multiple\n# lines\n", '    should append multi messages');

{
    local $TODO = 1;
    $output = '';
    diag("# foo");
}
is( $output, "# # foo\n",   "diag() adds a # even if there's one already" );


package FakeOut;

sub TIEHANDLE {
	bless( $_[1], $_[0] );
}

sub PRINT {
	my $self = shift;
	$$self .= join('', @_);
}
