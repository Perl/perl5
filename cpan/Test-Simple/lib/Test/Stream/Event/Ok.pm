package Test::Stream::Event::Ok;
use strict;
use warnings;

use Scalar::Util qw/blessed/;
use Test::Stream::Util qw/unoverload_str/;
use Test::Stream::Carp qw/confess/;

use Test::Stream::Event(
    accessors  => [qw/real_bool name diag bool level/],
    ctx_method => '_ok',
);

sub skip { $_[0]->[CONTEXT]->skip }
sub todo { $_[0]->[CONTEXT]->todo }

sub init {
    my $self = shift;

    $self->SUPER::init();

    # Do not store objects here, only true/false/undef
    if ($self->[REAL_BOOL]) {
        $self->[REAL_BOOL] = 1;
    }
    elsif(defined $self->[REAL_BOOL]) {
        $self->[REAL_BOOL] = 0;
    }
    $self->[LEVEL] = $Test::Builder::Level;

    my $ctx  = $self->[CONTEXT];
    my $rb   = $self->[REAL_BOOL];
    my $todo = $ctx->in_todo;
    my $skip = defined $ctx->skip;
    my $b    = $rb || $todo || $skip || 0;
    my $diag = delete $self->[DIAG];
    my $name = $self->[NAME];

    $self->[BOOL] = $b ? 1 : 0;

    unless ($rb || ($todo && $skip)) {
        my $msg = $todo ? "Failed (TODO)" : "Failed";
        my $prefix = $ENV{HARNESS_ACTIVE} ? "\n" : "";

        my ($pkg, $file, $line) = $ctx->call;

        if (defined $name) {
            $msg = qq[$prefix  $msg test '$name'\n  at $file line $line.];
        }
        else {
            $msg = qq[$prefix  $msg test at $file line $line.];
        }

        $self->add_diag($msg);
    }

    $self->add_diag("    You named your test '$name'.  You shouldn't use numbers for your test names.\n    Very confusing.")
        if $name && $name =~ m/^[\d\s]+$/;

    $self->add_diag(@$diag) if $diag && @$diag;
}

sub to_tap {
    my $self = shift;
    my ($num) = @_;

    my $name    = $self->[NAME];
    my $context = $self->[CONTEXT];
    my $skip    = $context->skip;
    my $todo    = $context->todo;

    my @out;
    push @out => "not" unless $self->[REAL_BOOL];
    push @out => "ok";
    push @out => $num if defined $num;

    unoverload_str \$name if defined $name;

    if ($name) {
        $name =~ s|#|\\#|g; # # in a name can confuse Test::Harness.
        push @out => ("-", $name);
    }

    if (defined $skip && defined $todo) {
        push @out => "# TODO & SKIP";
        push @out => $todo if length $todo;
    }
    elsif ($context->in_todo) {
        push @out => "# TODO";
        push @out => $todo if length $todo;
    }
    elsif (defined $skip) {
        push @out => "# skip";
        push @out => $skip if length $skip;
    }

    my $out = join " " => @out;
    $out =~ s/\n/\n# /g;

    return [OUT_STD, "$out\n"] unless $self->[DIAG];

    return (
        [OUT_STD, "$out\n"],
        map {$_->to_tap($num)} @{$self->[DIAG]},
    );
}

sub add_diag {
    my $self = shift;

    my $context = $self->[CONTEXT];
    my $created = $self->[CREATED];

    for my $item (@_) {
        next unless $item;

        if (ref $item) {
            confess("Only diag objects can be linked to events.")
                unless blessed($item) && $item->isa('Test::Stream::Event::Diag');

            $item->link($self);
        }
        else {
            $item = Test::Stream::Event::Diag->new($context, $created, $self->[IN_SUBTEST], $item, $self);
        }

        push @{$self->[DIAG]} => $item;
    }
}

{
    # Yes, we do want to override the imported one.
    no warnings 'redefine';
    sub clear_diag {
        my $self = shift;
        return unless $self->[DIAG];
        my $out = $self->[DIAG];
        $self->[DIAG] = undef;
        $_->set_linked(undef) for @$out;
        return $out;
    }
}

sub subevents { @{$_[0]->[DIAG] || []} }

sub to_legacy {
    my $self = shift;

    my $result = {};
    $result->{ok}        = $self->bool ? 1 : 0;
    $result->{actual_ok} = $self->real_bool;
    $result->{name}      = $self->name;

    my $ctx = $self->context;

    if($self->skip && ($ctx->in_todo || $ctx->todo)) {
        $result->{type} = 'todo_skip',
        $result->{reason} = $ctx->skip || $ctx->todo;
    }
    elsif($ctx->in_todo || $ctx->todo) {
        $result->{reason} = $ctx->todo;
        $result->{type}   = 'todo';
    }
    elsif($ctx->skip) {
        $result->{reason} = $ctx->skip;
        $result->{type}   = 'skip';
    }
    else {
        $result->{reason} = '';
        $result->{type}   = '';
    }

    if ($result->{reason} eq 'incrementing test number') {
        $result->{type} = 'unknown';
    }

    return $result;
}

sub extra_details {
    my $self = shift;

    require Test::Stream::Tester::Events;

    my $diag = join "\n", map {
        my $msg = $_->message;
        chomp($msg);
        split /[\n\r]+/, $msg;
    } @{$self->diag || []};

    return (
        diag      => $diag            || '',
        bool      => $self->bool      || 0,
        name      => $self->name      || undef,
        real_bool => $self->real_bool || 0
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Event::Ok - Ok event type

=head1 DESCRIPTION

Ok events are generated whenever you run a test that produces a result.
Examples are C<ok()>, and C<is()>.

=head1 SYNOPSYS

    use Test::Stream::Context qw/context/;
    use Test::Stream::Event::Ok;

    my $ctx = context();
    my $event = $ctx->ok($bool, $name, \@diag);

=head1 ACCESSORS

=over 4

=item $rb = $e->real_bool

This is the true/false value of the test after TODO, SKIP, and similar
modifiers are taken into account.

=item $name = $e->name

Name of the test.

=item $diag = $e->diag

An arrayref with all the L<Test::Stream::Event::Diag> events reduced down to
just the messages. Some coaxing has beeen done to combine all the messages into
a single string.

=item $b = $e->bool

The original true/false value of whatever was passed into the event (but
reduced down to 1 or 0).

=item $l = $e->level

For legacy L<Test::Builder> support. Do not use this, it can go away, or change
behavior at any time.

=back

=head1 METHODS

=over 4

=item $le = $e->to_legacy

Returns a hashref that matches some legacy details about ok's. You should
probably not use this for anything new.

=item $e->add_diag($diag_event, "diag message" ...)

Add a diag to the event. The diag may be a diag event, or a simple string.

=item $diag = $e->clear_diag

Remove all diag events, then return them in an arrayref.

=back

=head1 SUMMARY FIELDS

=over 4

=item diag

A single string with all the messages from the diags linked to the event.

=item bool

True/False passed into the test.

=item name

Name of the test.

=item real_bool

True/False value accounting for TODO and SKIP.

=back

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
