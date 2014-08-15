package Test::Builder::ExitMagic;
use strict;
use warnings;

use Test::Builder::Util qw/new accessors/;
require Test::Builder::Result::Finish;

accessors qw/stream tb ended pid/;

sub init {
    my $self = shift;
    $self->pid($$);
}

sub do_magic {
    my $self = shift;

    return if $self->ended; $self->ended(1);

    # Don't bother with an ending if this is a forked copy.  Only the parent
    # should do the ending.
    return unless $self->pid == $$;

    my $stream = $self->stream || (Test::Builder::Stream->root ? Test::Builder::Stream->shared : undef);
    return unless $stream; # No stream? no point!
    my $tb = $self->tb;

    return if $stream->no_ending;

    my $real_exit_code = $?;

    my $plan  = $stream->plan;
    my $total = $stream->tests_run;
    my $fails = $stream->tests_failed;

    $stream->send(
        Test::Builder::Result::Finish->new(
            tests_run    => $total,
            tests_failed => $fails,
            depth        => $tb->depth,
            source       => $tb->name,
        )
    );

    # Ran tests but never declared a plan or hit done_testing
    return $self->no_plan_magic($stream, $tb, $total, $fails, $real_exit_code)
        if $total && !$plan;

    # Exit if plan() was never called.  This is so "require Test::Simple"
    # doesn't puke.
    return unless $plan;

    # Don't do an ending if we bailed out.
    if( $stream->bailed_out ) {
        $stream->is_passing(0);
        return;
    }

    # Figure out if we passed or failed and print helpful messages.
    return $self->be_helpful_magic($stream, $tb, $total, $fails, $plan, $real_exit_code)
        if $total && $plan;

    if ($plan->directive && $plan->directive eq 'SKIP') {
        $? = 0;
        return;
    }

    if($real_exit_code) {
        $tb->diag("Looks like your test exited with $real_exit_code before it could output anything.\n");
        $stream->is_passing(0);
        $? = $real_exit_code;
        return;
    }

    unless ($total) {
        $tb->diag("No tests run!\n");
        $tb->is_passing(0);
        $? = 255;
        return;
    }

    $tb->is_passing(0);
    $tb->_whoa( 1, "We fell off the end of _ending()" );

    1;
}

sub no_plan_magic {
    my $self = shift;
    my ($stream, $tb, $total, $fails, $real_exit_code) = @_;

    $stream->is_passing(0);
    $tb->diag("Tests were run but no plan was declared and done_testing() was not seen.");

    if($real_exit_code) {
        $tb->diag("Looks like your test exited with $real_exit_code just after $total.\n");
        $? = $real_exit_code;
        return;
    }

    # But if the tests ran, handle exit code.
    if ($total && $fails) {
        my $exit_code = $fails <= 254 ? $fails : 254;
        $? = $exit_code;
        return;
    }

    $? = 254;
    return;
}

sub be_helpful_magic {
    my $self = shift;
    my ($stream, $tb, $total, $fails, $plan, $real_exit_code) = @_;

    my $planned   = $plan->max;
    my $num_extra = $plan->directive && $plan->directive eq 'NO_PLAN' ? 0 : $total - $planned;

    if ($num_extra != 0) {
        my $s = $planned == 1 ? '' : 's';
        $tb->diag("Looks like you planned $planned test$s but ran $total.\n");
        $tb->is_passing(0);
    }

    if($fails) {
        my $s = $fails == 1 ? '' : 's';
        my $qualifier = $num_extra == 0 ? '' : ' run';
        $tb->diag("Looks like you failed $fails test$s of ${total}${qualifier}.\n");
        $tb->is_passing(0);
    }

    if($real_exit_code) {
        $tb->diag("Looks like your test exited with $real_exit_code just after $total.\n");
        $tb->is_passing(0);
        $? = $real_exit_code;
        return;
    }

    my $exit_code;
    if($fails) {
        $exit_code = $fails <= 254 ? $fails : 254;
    }
    elsif($num_extra != 0) {
        $exit_code = 255;
    }
    else {
        $exit_code = 0;
    }

    $? = $exit_code;
    return;
}

1;

__END__

=head1 NAME

Test::Builder::ExitMagic - Encapsulate the magic exit logic used by
Test::Builder.

=head1 DESCRIPTION

It's magic! well kinda..

=head1 SYNOPSYS

Don't use this yourself, let L<Test::Builder> handle it.

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
