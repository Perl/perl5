package Text::Abbrev;
require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(abbrev);

# Usage:
#	&abbrev(*foo,LIST);
#	...
#	$long = $foo{$short};

sub abbrev {
    local(*domain) = shift;
    @cmp = @_;
    %domain = ();
    foreach $name (@_) {
	@extra = split(//,$name);
	$abbrev = shift(@extra);
	$len = 1;
	foreach $cmp (@cmp) {
	    next if $cmp eq $name;
	    while (substr($cmp,0,$len) eq $abbrev) {
		$abbrev .= shift(@extra);
		++$len;
	    }
	}
	$domain{$abbrev} = $name;
	while (@extra) {
	    $abbrev .= shift(@extra);
	    $domain{$abbrev} = $name;
	}
    }
}

1;

