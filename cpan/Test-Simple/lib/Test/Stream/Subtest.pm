package Test::Stream::Subtest;
use strict;
use warnings;

use Test::Stream::Exporter;
default_exports qw/subtest/;
Test::Stream::Exporter->cleanup;

use Test::Stream::Context qw/context/;
use Scalar::Util qw/reftype blessed/;
use Test::Stream::Util qw/try/;

sub subtest {
    my ($name, $code, @args) = @_;

    my $ctx = context();

    $ctx->throw("subtest()'s second argument must be a code ref")
        unless $code && 'CODE' eq reftype($code);

    $ctx->child('push', $name);
    $ctx->clear;
    my $todo = $ctx->hide_todo;

    my $pid = $$;

    my ($succ, $err) = try {
        my $early_return = 1;

        TEST_STREAM_SUBTEST: {
            no warnings 'once';
            local $Test::Builder::Level = 1;
            $code->(@args);
            $early_return = 0;
        }

        die $ctx->stream->subtest_exception->[-1] if $early_return;

        $ctx->set;
        my $stream = $ctx->stream;
        $ctx->done_testing unless $stream->plan || $stream->ended;

        require Test::Stream::ExitMagic;
        {
            local $? = 0;
            Test::Stream::ExitMagic->new->do_magic($stream, $ctx->snapshot);
        }
    };

    if ($$ != $pid && !$ctx->stream->_use_fork) {
        warn <<"        EOT";
Subtest finished with a new PID ($$ vs $pid) while forking support was turned off!
This is almost certainly not what you wanted. Did you fork and forget to exit?
        EOT

        # Did the forked process try to exit via die?
        die $err unless $succ;
    }

    # If a subtest forked, then threw an exception, we need to propogate that right away.
    die $err unless $succ || $$ == $pid || $err->isa('Test::Stream::Event');

    $ctx->set;
    $ctx->restore_todo($todo);
    $ctx->stream->subtest_exception->[-1] = $err unless $succ;

    # This sends the subtest event
    my $st = $ctx->child('pop', $name);

    unless ($succ) {
        die $err unless blessed($err) && $err->isa('Test::Stream::Event');
        $ctx->bail($err->reason) if $err->isa('Test::Stream::Event::Bail');
    }

    return $st->bool;
}

1;

__END__

=head1 Name

Test::Stream::Subtest - Encapsulate subtest start, run, and finish.

=head1 Synopsys

    use Test::Stream::Subtest;

    subtest $name => sub { ... };

=encoding utf8

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
