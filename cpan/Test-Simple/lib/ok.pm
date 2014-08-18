package ok;
use strict;
use warnings;

use Test::More 1.301001 ();
use Carp qw/croak/;

our $VERSION = '1.301001_040';
$VERSION = eval $VERSION;    ## no critic (BuiltinFunctions::ProhibitStringyEval)

sub import {
    shift;

    if (@_) {
        croak "'use ok' called with an empty argument, did you try to use a package name from an uninitialized variable?"
            unless defined $_[0];

        goto &Test::More::pass if $_[0] eq 'ok';
        goto &Test::More::use_ok;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

ok - Alternative to Test::More::use_ok

=head1 SYNOPSIS

    use ok 'Some::Module';

=head1 DESCRIPTION

With this module, simply change all C<use_ok> in test scripts to C<use ok>,
and they will be executed at C<BEGIN> time.

Please see L<Test::use::ok> for the full description.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
