#!./perl

BEGIN {
	chdir 't' unless -d 't';
	@INC = '../lib';
}

use warnings;
use Test::More tests => 8;
use vars qw( $Term::Complete::complete $complete );

SKIP: {
    skip('PERL_SKIP_TTY_TEST', 8) if $ENV{PERL_SKIP_TTY_TEST};
    
    my $TTY;
    if ($^O eq 'rhapsody' && -c "/dev/ttyp0") { $TTY = "/dev/ttyp0" }
    elsif (-c "/dev/tty")                     { $TTY = "/dev/tty"   }
    if (defined $TTY) {
	open(TTY, $TTY)               or die "open $TTY failed: $!";
	skip("$TTY not a tty", 8)     if defined $TTY && ! -t TTY;
    }

use_ok( 'Term::Complete' );

*complete = \$Term::Complete::complete;

my $in = tie *STDIN, 'FakeIn', "fro\t";
my $out = tie *STDOUT, 'FakeOut';
my @words = ( 'frobnitz', 'frobozz', 'frostychocolatemilkshakes' );

Complete('', \@words);
my $data = get_expected('fro', @words);

# there should be an \a after our word
like( $$out, qr/fro\a/, 'found bell character' );

# now remove the \a -- there should be only one
is( $out->scrub(), 1, '(single) bell removed');

# 'fro' should match all three words
like( $$out, qr/$data/, 'all three words possible' );
$out->clear();

# should only find 'frobnitz' and 'frobozz'
$in->add('frob');
Complete('', @words);
$out->scrub();
is( $$out, get_expected('frob', 'frobnitz', 'frobozz'), 'expected frob*' );
$out->clear();

# should only do 'frobozz'
$in->add('frobo');
Complete('', @words);
$out->scrub();
is( $$out, get_expected( 'frobo', 'frobozz' ), 'only frobozz possible' );
$out->clear();

# change the completion character
$complete = "!";
$in->add('frobn');
Complete('prompt:', @words);
$out->scrub();
like( $$out, qr/prompt:frobn/, 'prompt is okay' );

# now remove the prompt and we should be okay
$$out =~ s/prompt://g;
is( $$out, get_expected('frobn', 'frobnitz' ), 'works with new $complete' );

# easier than matching space characters
sub get_expected {
	my $word = shift;
	return join('.', $word, @_, $word, '.');
}

package FakeIn;

sub TIEHANDLE {
	my ($class, $text) = @_;
	$text .= "$main::complete\025";
	bless(\$text, $class);
}

sub add {
	my ($self, $text) = @_;
	$$self = $text . "$main::complete\025";
}

sub GETC {
	my $self = shift;
	return length $$self ? substr($$self, 0, 1, '') : "\r";
}

package FakeOut;

sub TIEHANDLE {
	bless(\(my $text), $_[0]);
}

sub clear {
	${ $_[0] } = '';
}

# remove the bell character
sub scrub {
	${ $_[0] } =~ tr/\a//d;
}

# must shift off self
sub PRINT {
	my $self = shift;
	($$self .= join('', @_)) =~ s/\s+/./gm;
}

} # end of SKIP, end of tests

