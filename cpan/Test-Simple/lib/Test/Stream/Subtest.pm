package Test::Stream::Subtest;
use strict;
use warnings;

use Test::Stream::Exporter;
default_exports qw/subtest/;
Test::Stream::Exporter->cleanup;

use Test::Stream::Context qw/context/;
use Scalar::Util qw/reftype blessed/;
use Test::Stream::Util qw/try/;
use Test::Stream::Carp qw/confess/;

use Test::Stream::Block;

sub subtest {
    my ($name, $code, @args) = @_;

    my $ctx = context();

    $ctx->throw("subtest()'s second argument must be a code ref")
        unless $code && 'CODE' eq reftype($code);

    my $block = Test::Stream::Block->new(
        $name, $code, undef, [caller(0)],
    );

    $ctx->note("Subtest: $name")
        if $ctx->stream->subtest_tap_instant;

    my $st = $ctx->subtest_start($name);

    my $pid = $$;
    my ($succ, $err) = try {
        TEST_STREAM_SUBTEST: {
            no warnings 'once';
            local $Test::Builder::Level = 1;
            $block->run(@args);
        }

        return if $st->{early_return};

        $ctx->set;
        my $stream = $ctx->stream;
        $ctx->done_testing unless $stream->plan || $stream->ended;

        require Test::Stream::ExitMagic;
        {
            local $? = 0;
            Test::Stream::ExitMagic->new->do_magic($stream, $ctx->snapshot);
        }
    };

    my $er = $st->{early_return};
    if (!$succ) {
        # Early return is not a *real* exception.
        if ($er && $er == $err) {
            $succ = 1;
            $err = undef;
        }
        else {
            $st->{exception} = $err;
        }
    }

    if ($$ != $pid) {
        warn <<"        EOT" unless $ctx->stream->_use_fork;
Subtest finished with a new PID ($$ vs $pid) while forking support was turned off!
This is almost certainly not what you wanted. Did you fork and forget to exit?
        EOT

        # Did the forked process try to exit via die?
        # If a subtest forked, then threw an exception, we need to propogate that right away.
        die $err unless $succ;
    }

    my $st_check = $ctx->subtest_stop($name);
    confess "Subtest mismatch!" unless $st == $st_check;

    $ctx->bail($st->{early_return}->reason) if $er && $er->isa('Test::Stream::Event::Bail');

    my $e = $ctx->subtest(
        # Stuff from ok (most of this gets initialized inside)
        undef, # real_bool, gets set properly by initializer
        $st->{name}, # name
        undef, # diag
        undef, # bool
        undef, # level

        # Subtest specific stuff
        $st->{state},
        $st->{events},
        $st->{exception},
        $st->{early_return},
        $st->{delayed},
        $st->{instant},
    );

    die $err unless $succ;

    return $e->bool;
}

1;

__END__

=pod

=encoding UTF-8

=head1 Name

Test::Stream::Subtest - Encapsulate subtest start, run, and finish.

=head1 Synopsys

    use Test::Stream::Subtest;

    subtest $name => sub { ... };

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

The following people have all contributed to the Test-More dist (sorted using
VIM's sort function).

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Fergal Daly E<lt>fergal@esatclear.ie>E<gt>

=item Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

=item Michael G Schwern E<lt>schwern@pobox.comE<gt>

=item 唐鳳

=back

=head1 COPYRIGHT

There has been a lot of code migration between modules,
here are all the original copyrights together:

=over 4

=item Test::Stream

=item Test::Stream::Tester

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::Simple

=item Test::More

=item Test::Builder

Originally authored by Michael G Schwern E<lt>schwern@pobox.comE<gt> with much
inspiration from Joshua Pritikin's Test module and lots of help from Barrie
Slaymaker, Tony Bowden, blackstar.co.uk, chromatic, Fergal Daly and the perl-qa
gang.

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::use::ok

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=item Test::Tester

This module is copyright 2005 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=item Test::Builder::Tester

Copyright Mark Fowler E<lt>mark@twoshortplanks.comE<gt> 2002, 2004.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=back
