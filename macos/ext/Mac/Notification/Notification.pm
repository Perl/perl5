=head1 NAME

Mac::Notification - Macintosh Toolbox Interface to Notification Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Notification;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		NMInstall
		NMRemove
	);
}

bootstrap Mac::Notification;

package NMRec;

sub new {
	my($package) = shift @_;
	my($nm) = NMRec::_new($package);
	while (scalar(@_)) {
		my($field) = shift @_;
		my($value) = shift @_;
		
		$nm->$field($value);
	}
	$nm;
}

=include Notification.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

1;

__END__
