package Exporter;

require 5.000;

sub import {
    my ($callpack, $callfile, $callline) = caller($ExportLevel);
    my $pack = shift;
    my @imports = @_;
    *exports = \@{"${pack}::EXPORT"};
    if (@imports) {
	my $oops;
	my $type;
	*exports = \%{"${pack}::EXPORT"};
	if (!%exports) {
	    grep(s/^&//, @exports);
	    @exports{@exports} = (1) x  @exports;
	}
	foreach $sym (@imports) {
	    if (!$exports{$sym}) {
		if ($sym !~ s/^&// || !$exports{$sym}) {
		    warn "$sym is not exported by the $pack module ",
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

1;
