package attrs;

use vars qw($VERSION);
$VERSION = "0.1";

1;

=head1 NAME

attrs - set/get attributes of a subroutine

=head1 SYNOPSIS

    sub foo {
        use attrs qw(locked method);
        ...
    }

    @a = attrs::get(\&foo);

=head1 DESCRIPTION

This module lets you set and get attributes for subroutines.

For 5.004_xx this is an empty stub provided for backwards
compatibility for scripts and modules written for 5.005.

=cut
