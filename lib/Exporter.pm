package Exporter;

require 5.000;

$ExportLevel = 0;

sub export {
    my $pack = shift;
    my $callpack = shift;
    my @imports = @_;
    *exports = \@{"${pack}::EXPORT"};
    if (@imports) {
	my $oops;
	my $type;
	*exports = \%{"${pack}::EXPORT"};
	if (!%exports) {
	    grep(s/^&//, @exports);
	    @exports{@exports} = (1) x  @exports;
	    foreach $extra (@{"${pack}::EXPORT_OK"}) {
		$exports{$extra} = 1;
	    }
	}
	foreach $sym (@imports) {
	    if (!$exports{$sym}) {
		if ($sym !~ s/^&// || !$exports{$sym}) {
		    warn qq["$sym" is not exported by the $pack module ],
			    "at $callfile line $callline\n";
		    $oops++;
		    next;
		}
	    }
	}
	die "Can't continue with import errors.\n" if $oops;
    }
    else {
	@imports = @exports;
    }
    foreach $sym (@imports) {
	$type = '&';
	$type = $1 if $sym =~ s/^(\W)//;
	*{"${callpack}::$sym"} =
	    $type eq '&' ? \&{"${pack}::$sym"} :
	    $type eq '$' ? \${"${pack}::$sym"} :
	    $type eq '@' ? \@{"${pack}::$sym"} :
	    $type eq '%' ? \%{"${pack}::$sym"} :
	    $type eq '*' ?  *{"${pack}::$sym"} :
		    warn "Can't export symbol: $type$sym\n";
    }
};

sub import {
    local ($callpack, $callfile, $callline) = caller($ExportLevel);
    my $pack = shift;
    export $pack, $callpack, @_;
}

1;
