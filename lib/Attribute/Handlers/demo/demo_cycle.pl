use Attribute::Handlers autotie => { Cycle => Tie::Cycle };

my $next : Cycle(['A'..'Z']);

print tied $next, "\n";

while (<>) {
	print $next, "\n";
}
