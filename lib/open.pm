package open;

=head1 NAME

open - perl pragma to set default disciplines for input and output

=head1 SYNOPSIS

    use open IN => ":any", OUT => ":utf8";	# unimplemented

=head1 DESCRIPTION

NOTE: This pragma is not yet implemented.

The open pragma is used to declare one or more default disciplines for
I/O operations.  Any constructors for file, socket, pipe, or directory
handles found within the lexical scope of this pragma will use the
declared default.

Handle constructors that are called with an explicit set of disciplines
are not influenced by the declared defaults.

The default disciplines so declared are available by the special
discipline name ":def", and can be used within handle constructors
that allow disciplines to be specified.  This makes it possible to
stack new disciplines over the default ones.

    open FH, "<:para :def", $file or die "can't open $file: $!";

=head1 SEE ALSO

L<perlunicode>, L<perlfunc/"open">

=cut

1;
