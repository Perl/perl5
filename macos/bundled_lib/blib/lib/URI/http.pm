package URI::http;

require URI::_server;
@ISA=qw(URI::_server);

use strict;
use vars qw(%unreserved_escape);

sub default_port { 80 }

sub canonical
{
    my $self = shift;
    my $other = $self->SUPER::canonical;

    my $slash_path = defined($other->authority) &&
        !length($other->path) && !defined($other->query);

    if ($slash_path || $$other =~ /%/) {
	$other = $other->clone if $other == $self;
	unless (%unreserved_escape) {
	    for ("A" .. "Z", "a" .. "z", "0" .."9",
		 "-", "_", ".", "!", "~", "*", "'", "(", ")"
		) {
		$unreserved_escape{sprintf "%%%02X", ord($_)} = $_;
	    }
	}
	$$other =~ s/(%[0-9A-F]{2})/$unreserved_escape{$1} || $1/ge;
	$other->path("/") if $slash_path;
    }
    $other;
}

1;
