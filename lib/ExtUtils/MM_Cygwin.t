#!./perl

BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
}

use Test::More;

BEGIN {
	if ($^O =~ /cygwin/i) {
		plan tests => 17;
	} else {
		plan skip_all => "This is not $^O";
	}
}

use Config;
use File::Spec;

# MM package faked up by messy MI entanglement
@MM::ISA = qw( ExtUtils::MM_Unix ExtUtils::Liblist::Kid ExtUtils::MakeMaker );

use_ok( 'ExtUtils::MM_Cygwin' );

# test canonpath
my $path = File::Spec->canonpath('/a/../../c');
is( MM->canonpath('/a/../../c'), $path,
	'canonpath() method should work just like the one in File::Spec' );

# test cflags, with the fake package below
my $args = bless({
	CFLAGS	=> 'fakeflags',
	CCFLAGS	=> '',
}, MM);

# with CFLAGS set, it should be returned
is( $args->cflags(), 'fakeflags',
	'cflags() should return CFLAGS member data, if set' );

delete $args->{CFLAGS};

# ExtUtils::MM_Cygwin::cflags() calls this, fake the output
*ExtUtils::MM_Unix::cflags = sub { return $_[1] };

# respects the config setting, should ignore whitespace around equal sign
my $ccflags = $Config{useshrplib} eq 'true' ? ' -DUSEIMPORTLIB' : '';
$args->cflags(<<FLAGS);
OPTIMIZE = opt
PERLTYPE  =pt
LARGE= lg
SPLIT=split
FLAGS

like( $args->{CFLAGS}, qr/OPTIMIZE = opt/, '... should set OPTIMIZE' );
like( $args->{CFLAGS}, qr/PERLTYPE = pt/, '... should set PERLTYPE' );
like( $args->{CFLAGS}, qr/LARGE = lg/, '... should set LARGE' );
like( $args->{CFLAGS}, qr/SPLIT = split/, '... should set SPLIT' );
like( $args->{CFLAGS}, qr/CCFLAGS = $ccflags/, '... should set CCFLAGS' );

# test manifypods
$args = bless({
	NOECHO => 'noecho',
	MAN3PODS => {},
	MAN1PODS => {},
}, 'MM');
like( $args->manifypods(), qr/pure_all\n\tnoecho/,
	'manifypods() should return without PODS values set' );

$args->{MAN3PODS} = { foo => 1 };
my $out = tie *STDOUT, 'FakeOut';
my $res = $args->manifypods();
like( $$out, qr/could not locate your pod2man/,
	'... should warn if pod2man cannot be located' );
like( $res, qr/POD2MAN_EXE = -S pod2man/,
	'... should use default pod2man target' );
like( $res, qr/pure_all.+foo/, '... should add MAN3PODS targets' );

$args->{PERL_SRC} = File::Spec->updir;
$args->{MAN1PODS} = { bar => 1 };
$$out = '';
$res = $args->manifypods();
is( $$out, '', '... should not warn if PERL_SRC provided' );
like( $res, qr/bar \\\n\t1 \\\n\tfoo/, '... should join MAN1PODS and MAN3PODS');

# test perl_archive
my $libperl = $Config{libperl} || 'libperl.a';
is( $args->perl_archive(), "\$(PERL_INC)/$libperl",
	'perl_archive() should respect libperl setting' );

# test import of $Verbose and &neatvalue
can_ok( 'ExtUtils::MM_Cygwin', 'neatvalue' );
is( $ExtUtils::MM_Cygwin::Verbose, $ExtUtils::MakeMaker::Verbose, 
	'ExtUtils::MM_Cygwin should import $Verbose from ExtUtils::MakeMaker' );

package FakeOut;

sub TIEHANDLE {
	bless(\(my $scalar), $_[0]);
}

sub PRINT {
	my $self = shift;
	$$self .= shift;
}
