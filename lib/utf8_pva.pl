package utf8;

##
## Store the alias definitions for later use.
##

my $dir;
for (@INC) {
  $dir = $_, last if -e "$_/unicore/PropertyAliases.txt";
}

use Carp 'confess';

local $_;

    open PA, "< $dir/unicore/PropertyAliases.txt"
	or confess "Can't open PropertyAliases.txt: $!";
    while (<PA>) {
	s/#.*//;
	s/\s+$//;
	next if /^$/;

	my ($abbrev, $name) = split /\s*;\s*/;
        next if $abbrev eq "n/a";
	tr/ _-//d for $abbrev, $name;
	$PropertyAlias{lc $abbrev} = $name;
        $PA_reverse{lc $name} = $abbrev;
    }
    close PA;

    open PVA, "< $dir/unicore/PropValueAliases.txt"
	or confess "Can't open PropValueAliases.txt: $!";
    while (<PVA>) {
	s/#.*//;
	s/\s+$//;
	next if /^$/;

	my ($prop, @data) = split /\s*;\s*/;
	shift @data if $prop eq 'ccc';
        next if $data[0] eq "n/a";

	$data[1] =~ tr/ _-//d;
	$PropValueAlias{$prop}{lc $data[0]} = $data[1];
        $PVA_reverse{$prop}{lc $data[1]} = $data[0];

	my $abbr_class = ($prop eq 'gc' or $prop eq 'sc') ? 'gc_sc' : $prop;
	$PVA_abbr_map{$abbr_class}{lc $data[0]} = $data[0];
    }
    close PVA;

    # backwards compatibility for L& -> LC
    $PropValueAlias{gc}{'l&'} = $PropValueAlias{gc}{lc};
    $PVA_abbr_map{gc_sc}{'l&'} = $PVA_abbr_map{gc_sc}{lc};

1;
