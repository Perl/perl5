package Test::Stream::ForceExit;
use strict;
use warnings;

sub new {
    my $class = shift;

    my $done = 0;
    my $self = \$done;

    return bless $self, $class;
}

sub done {
    my $self = shift;
    ($$self) = @_ if @_;
    return $$self;
}

sub DESTROY {
    my $self = shift;
    return if $self->done;

    warn "Something prevented child process $$ from exiting when it should have, Forcing exit now!\n";
    $self->done(1); # Prevent duplicate message during global destruction
    exit 255;
}

1;

__END__

=head1 NAME

Test::ForceExit - Ensure C<exit()> is called by the end of a scope, force the issue.

=head1 DESCRIPTION

Sometimes you need to fork. Sometimes the forked process can throw an exception
to exit. If you forked below an eval the exception will be cought and you
suddenly have an unexpected process running amok. This module can be used to
protect you from such issues.

=head1 SYNOPSYS

    eval {
        ...

        my $pid = fork;

        unless($pid) {
            require Test::Stream::ForceExit;
            my $force_exit = Test::Stream::ForceExit->new;

            thing_that_can_die();

            # We did not die, turn off the forced exit.
            $force_exit->done(1);

            # Do the exit we intend.
            exit 0;
        }

        ...
    }

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
