=head1 NAME

Mac::DCon - Cache Computing's Debugging Console

=head1 SYNOPSIS


=head1 DESCRIPTION

Please refer to the DCon documentation, available from
http://www.cache-computing.com/products/dcon/, for instructions.
You may redistribute the MacPerl glue to DCon freely.

=cut

use strict;

package Mac::DCon;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		dopen
		dprintf
		dprintmem
		dfprintf
		dfprintmem
	);
}

bootstrap Mac::DCon;

=include DCon.xs

=item dprintf FORMAT [, ARG ...]

=item dprintmem ADDRESS, LENGTH

=item dprintf STREAM, FORMAT [, ARG ...]

=item dprintmem STREAM, ADDRESS, LENGTH

=cut
sub dprintf {
	my($a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $a10) = @_; 
	_dfprint("", sprintf($a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $a10));
}

sub dprintmem {
	my($addr, $len) = @_;
	
	_dfprintmem("", (ref($addr) eq "Ptr") ? $addr : bless(\$addr, "Ptr"), $len)
}

sub dfprintf {
	my($stream, $a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $a10) = @_;
	_dfprint($stream, sprintf($a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $a10));
}

sub dfprintmem {
	my($stream, $addr, $len) = @_;
	
	_dfprintmem($stream, (ref($addr) eq "Ptr") ? $addr : bless(\$addr, "Ptr"), $len)
}

=back

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

MacPerl DCon glue 			by Matthias Ulrich Neeracher <neeracher@mac.com> 

=cut

1;

__END__
