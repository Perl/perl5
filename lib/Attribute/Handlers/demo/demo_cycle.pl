package Selfish;

sub TIESCALAR {
	use Data::Dumper 'Dumper';
	print Dumper [ \@_ ];
	bless {}, $_[0];
}

package main;

use Attribute::Handlers autotieref => { Selfish => Selfish };

my $next : Selfish("me");

print "$next\n";
