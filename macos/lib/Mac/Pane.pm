=head1 NAME

Pane.pm - Panes in windows

=head1 SYNOPSIS

	package XXX;
	use Mac::Pane;
	@ISA = qw(Mac::Pane);
	
=head1 DESCRIPTION

The MacWindow class dispatches the events it gets to a number of panes. Panes are
typically one of

=over 4

=item Individual panes

in which an instance of a pane object is allocated for each element (e.g. a movie
controller).

=item Collective panes

in which a single instance controls all elements of a type (e.g., a control).

=back

=head2 Member functions

=over 4

All member functions take as their first two arguments the pane object and the
window object. The latter makes it possible to implement flyweight panes.

=cut	
package Mac::Pane;

=item new(WINDOW)

Creates a new pane and attachs it to a MacWindow if one is given.

=cut
sub new {
	my($class, $window) = @_;
	my($me) = bless {}, $class;
	
	$window->add_pane($me) if $window;
	
	$me;
}

=item attach(WINDOW)

Called by MacWindow to indicate that the pane has just been attached.

=cut
sub attach {
}

=item detach(WINDOW)

Called by MacWindow to indicate that the pane has just been detached.

=cut
sub detach {
}

=item activate(WINDOW, ACTIVE, SUSPEND)

Handle activate/suspend events.

=cut
sub activate {
}

=item focus(WINDOW, FOCUS)

Called by MacWindow to indicate that the pane has acquired (1) or lost (0) the 
focus.

=cut
sub focus {
}

=item redraw(WINDOW)

Redraw the contents of the pane.

=cut
sub redraw {
}

=item key(WINDOW, KEY)

Handle a key stroke.

=cut
sub key {
	0;
}

=item click(WINDOW, PT)

Handle a click.

=cut
sub click {
	0;
}

=item cursor(WINDOW, PT)

Adjust the cursor if appropriate.

=cut
sub cursor {
	0;
}

=item idle(WINDOW)

Perform regular tasks (like blinking an insertion point). Must be enabled with
C<add_idle>.

=cut
sub idle {
}

1;
