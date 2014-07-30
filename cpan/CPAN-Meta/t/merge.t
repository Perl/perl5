#! perl

use strict;
use warnings;

use Test::More;
use CPAN::Meta::Merge;

my %base = (
	abstract => 'This is a test',
	author => ['A.U. Thor'],
	generated_by => 'Myself',
	license => [ 'perl_5' ],
	resources => {
		license => [ 'http://dev.perl.org/licenses/' ],
	},
	prereqs => {
		runtime => {
			requires => {
				Foo => '0',
			},
		},
	},
	dynamic_config => 0,
	provides => {
		Baz => {
			file => 'lib/Baz.pm',
		},
	},
	'meta-spec' => {
		url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
		version => 2,
	},
);

my %first = (
	author => [ 'I.M. Poster' ],
	generated_by => 'Some other guy',
	license => [ 'bsd' ],
	resources => {
		license => [ 'http://opensource.org/licenses/bsd-license.php' ],
	},
	prereqs => {
		runtime => {
			requires => {
				Foo => '< 1',
			},
			recommends => {
				Bar => '3.14',
			},
		},
		test => {
			requires => {
				'Test::Bar' => 0,
			},
		},
	},
	dynamic_config => 1,
	provides => {
		Quz => {
			file => 'lib/Quz.pm',
		},
	},
);
my %first_expected = (
	abstract => 'This is a test',
	author => [ 'A.U. Thor', 'I.M. Poster' ],
	generated_by => 'Myself, Some other guy',
	license => [ 'perl_5', 'bsd' ],
	resources => {
		license => [ 'http://dev.perl.org/licenses/', 'http://opensource.org/licenses/bsd-license.php' ],
	},
	prereqs => {
		runtime => {
			requires => {
				Foo => '>= 0, < 1',
			},
			recommends => {
				Bar => '3.14',
			},
		},
		test => {
			requires => {
				'Test::Bar' => 0,
			},
		},
	},
	provides => {
		Baz => {
			file => 'lib/Baz.pm',
		},
		Quz => {
			file => 'lib/Quz.pm',
		},
	},
	dynamic_config => 1,
	'meta-spec' => {
		url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
		version => 2,
	},
);

my $merger = CPAN::Meta::Merge->new(default_version => '2');

my $first_result = $merger->merge(\%base, \%first);

is_deeply($first_result, \%first_expected, 'First result is as expected');

is_deeply($merger->merge(\%base, { abstract => 'This is a test' }), \%base, 'Can merge in identical abstract');
my $failure = eval { $merger->merge(\%base, { abstract => 'And now for something else' }) };
is($failure, undef, 'Trying to merge different author gives an exception');
like $@, qr/^Can't merge attribute abstract /, 'Exception looks right';

my $failure2 = eval { $merger->merge(\%base, { provides => { Baz => { file => 'Baz.pm' } } }) };
is($failure2, undef, 'Trying to merge different author gives an exception');
like $@, qr/^Duplication of element provides\.Baz /, 'Exception looks right';

done_testing();
