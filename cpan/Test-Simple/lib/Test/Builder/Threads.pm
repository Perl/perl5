package Test::Builder::Threads;
use strict;
use warnings;

# Make Test::Builder thread-safe for ithreads.
BEGIN {
    use Config;
    # Load threads::shared when threads are turned on.
    if( $Config{useithreads} && $INC{'threads.pm'} ) {
        require threads::shared;

        # Hack around YET ANOTHER threads::shared bug.  It would
        # occasionally forget the contents of the variable when sharing it.
        # So we first copy the data, then share, then put our copy back.
        *share = sub (\[$@%]) {
            my $type = ref $_[0];
            my $data;

            if( $type eq 'HASH' ) {
                %$data = %{ $_[0] };
            }
            elsif( $type eq 'ARRAY' ) {
                @$data = @{ $_[0] };
            }
            elsif( $type eq 'SCALAR' ) {
                $$data = ${ $_[0] };
            }
            else {
                die( "Unknown type: " . $type );
            }

            $_[0] = &threads::shared::share( $_[0] );

            if( $type eq 'HASH' ) {
            }
            elsif( $type eq 'ARRAY' ) {
                @{ $_[0] } = @$data;
            }
            elsif( $type eq 'SCALAR' ) {
                ${ $_[0] } = $$data;
            }
            else {
                die( "Unknown type: " . $type );
            }

            return $_[0];
        };
    }
    else {
        *share = sub { return $_[0] };
        *lock  = sub { 0 };
    }
}

sub import {
    my $class = shift;
    my $caller = caller;

    no strict 'refs';
    *{"$caller\::share"} = $class->can('share') if $class->can('share');
    *{"$caller\::lock"}  = $class->can('lock')  if $class->can('lock');
}

1;

__END__

=head1 NAME

Test::Builder::Threads - Helper Test::Builder uses when threaded.

=head1 DESCRIPTION

Helper Test::Builder uses when threaded.

=head1 SYNOPSYS

    use threads;
    use Test::Builder::Threads;

    share(...);
    lock(...);

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

Most of this code was pulled out ot L<Test::Builder>, written by Schwern and
others.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
