#!perl -w

use strict;
use Test::More;

BEGIN {use_ok('XS::APItest')};
my (%sigils);
BEGIN {
    %sigils = (
	       '$' => 'sv',
	       '@' => 'av',
	       '%' => 'hv',
	       '&' => 'cv',
	       '*' => 'gv'
	      );
}
my %types = map {$_, eval "&to_${_}_amg()"} values %sigils;

{
    package None;
}

{
    package Other;
    use overload 'eq' => sub {no overloading; $_[0] == $_[1]},
	'""' =>  sub {no overloading; "$_[0]"},
	'~' => sub {return "Perl rules"};
}

{
    package Same;
    use overload 'eq' => sub {no overloading; $_[0] == $_[1]},
	'""' =>  sub {no overloading; "$_[0]"},
	map {$_ . '{}', sub {return $_[0]}} keys %sigils;
}

{
    package Chain;
    use overload 'eq' => sub {no overloading; $_[0] == $_[1]},
	'""' =>  sub {no overloading; "$_[0]"},
	map {$_ . '{}', sub {no overloading; return $_[0][0]}} keys %sigils;
}

my @non_ref = (['undef', undef],
		 ['number', 42],
		 ['string', 'Pie'],
		);

my @ref = (['unblessed SV', do {\my $whap}],
	   ['unblessed AV', []],
	   ['unblessed HV', {}],
	   ['unblessed CV', sub {}],
	   ['unblessed GV', \*STDOUT],
	   ['no overloading', bless {}, 'None'],
	   ['other overloading', bless {}, 'Other'],
	   ['same overloading', bless {}, 'Same'],
	  );

while (my ($type, $enum) = each %types) {
    foreach (@non_ref, @ref,
	    ) {
	my ($desc, $input) = @$_;
	my $got = tryAMAGICunDEREF_var($input, $enum);
	is($got, $input, "Expect no change for to_$type $desc");
    }
    foreach (@non_ref) {
	my ($desc, $sucker) = @$_;
	my $input = bless [$sucker], 'Chain';
	is(eval {tryAMAGICunDEREF_var($input, $enum)}, undef,
	     "Chain to $desc for to_$type");
	like($@, qr/Overloaded dereference did not return a reference/,
	    'expected error');
    }
    foreach (@ref,
	    ) {
	my ($desc, $sucker) = @$_;
	my $input = bless [$sucker], 'Chain';
	my $got = tryAMAGICunDEREF_var($input, $enum);
	is($got, $sucker, "Chain to $desc for to_$type");
	$input = bless [bless [$sucker], 'Chain'], 'Chain';
	my $got = tryAMAGICunDEREF_var($input, $enum);
	is($got, $sucker, "Chain to chain to $desc for to_$type");
    }
}

done_testing;
