package Test::Builder::Formatter::TAP;
use strict;
use warnings;

use Test::Builder::Threads;
use Test::Builder::Util qw/accessors try protect new accessor/;
use Carp qw/croak confess/;

use base 'Test::Builder::Formatter';

accessors qw/No_Header No_Diag Depth Use_Numbers _the_plan/;

accessor io_sets => sub { {} };

use constant OUT  => 0;
use constant FAIL => 1;
use constant TODO => 2;

#######################
# {{{ INITIALIZATION
#######################

sub init {
    my $self = shift;

    $self->no_header(0);
    $self->use_numbers(1);

    $self->{number} = 0;

    $self->{lock} = 1;
    share($self->{lock});

    $self->init_legacy;

    return $self;
}

#######################
# }}} INITIALIZATION
#######################

#######################
# {{{ EVENT METHODS
#######################

for my $handler (qw/bail nest/) {
    my $sub = sub {
        my $self = shift;
        my ($item) = @_;
        $self->_print_to_fh($self->event_handle($item, OUT), $item->indent || "", $item->to_tap);
    };
    no strict 'refs';
    *$handler = $sub;
}

sub child {
    my $self = shift;
    my ($item) = @_;

    return unless $item->action eq 'push' && $item->is_subtest;

    my $name = $item->name;
    $self->_print_to_fh($self->event_handle($item, OUT), $item->indent || "", "# Subtest: $name\n");
}

sub finish {
    my $self = shift;
    my ($item) = @_;

    return if $self->no_header;
    return unless $item->tests_run;

    my $plan = $self->_the_plan;
    return unless $plan;

    if ($plan) {
        return unless $plan->directive;
        return unless $plan->directive eq 'NO_PLAN';
    }

    my $total = $item->tests_run;
    $self->_print_to_fh($self->event_handle($item, OUT), $item->indent || '', "1..$total\n");
}

sub plan {
    my $self = shift;
    my ($item) = @_;

    $self->_the_plan($item);

    return if $self->no_header;

    return if $item->directive && $item->directive eq 'NO_PLAN';

    my $out = $item->to_tap;
    return unless $out;

    my $handle = $self->event_handle($item, OUT);
    $self->_print_to_fh($handle, $item->indent || "", $out);
}

sub ok {
    my $self = shift;
    my ($item) = @_;

    $self->atomic_event(sub {
        my $num = $self->use_numbers ? ++($self->{number}) : undef;
        $self->_print_to_fh($self->event_handle($item, OUT), $item->indent || "", $item->to_tap($num));
    });
}

sub diag {
    my $self = shift;
    my ($item) = @_;

    return if $self->no_diag;

    # Prevent printing headers when compiling (i.e. -c)
    return if $^C;

    my $want_handle = $item->in_todo ? TODO : FAIL;
    my $handle = $self->event_handle($item, $want_handle);

    $self->_print_to_fh( $handle, $item->indent || "", $item->to_tap );
}

sub note {
    my $self = shift;
    my ($item) = @_;

    return if $self->no_diag;

    # Prevent printing headers when compiling (i.e. -c)
    return if $^C;

    $self->_print_to_fh( $self->event_handle($item, OUT), $item->indent || "", $item->to_tap );
}

#######################
# }}} EVENT METHODS
#######################

##############################
# {{{ IO accessors
##############################

sub io_set {
    my $self = shift;
    my ($name, @handles) = @_;

    if (@handles) {
        my ($out, $fail, $todo) = @handles;
        $out = $self->_new_fh($out);

        $fail = $fail ? $self->_new_fh($fail) : $out;
        $todo = $todo ? $self->_new_fh($todo) : $out;

        $self->io_sets->{$name} = [$out, $fail, $todo];
    }

    return $self->io_sets->{$name};
}

sub encoding_set {
    my $self = shift;
    my ($encoding) = @_;

    $self->io_sets->{$encoding} ||= do {
        my ($out, $fail) = $self->open_handles();
        my $todo = $out;

        binmode($out, ":encoding($encoding)");
        binmode($fail, ":encoding($encoding)");

        [$out, $fail, $todo];
    };

    return $self->io_sets->{$encoding};
}

sub event_handle {
    my $self = shift;
    my ($event, $index) = @_;

    my $rencoding = $event ? $event->encoding : undef;

    # Open handles in the encoding if one is set.
    $self->encoding_set($rencoding) if $rencoding && $rencoding ne 'legacy';

    for my $name ($rencoding, qw/utf8 legacy/) {
        next unless $name;
        my $handles = $self->io_set($name);
        return $handles->[$index] if $handles;
    }

    confess "This should not happen";
}

##############################
# }}} IO accessors
##############################

########################
# {{{ Legacy Support
########################

my $LEGACY;

sub full_reset { $LEGACY = undef }

sub init_legacy {
    my $self = shift;

    unless ($LEGACY) {
        my ($out, $err) = $self->open_handles();

        _copy_io_layers(\*STDOUT, $out);
        _copy_io_layers(\*STDERR, $err);

        _autoflush($out);
        _autoflush($err);

        # LEGACY, BAH!
        _autoflush(\*STDOUT);
        _autoflush(\*STDERR);

        $LEGACY = [$out, $err, $out];
    }

    $self->reset_outputs;
}

sub reset_outputs {
    my $self = shift;
    my ($out, $fail, $todo) = @$LEGACY;
    $self->io_sets->{legacy} = [$out, $fail, $todo];
}

sub reset {
    my $self = shift;
    $self->reset_outputs;
    $self->no_header(0);
    $self->use_numbers(1);
    lock $self->{lock};
    $self->{number} = 0;
    share( $self->{number} );

    1;
}

sub output {
    my $self = shift;
    my $handles = $self->io_set('legacy');
    ($handles->[OUT]) = $self->_new_fh($_[0]) if @_;
    return $handles->[OUT];
}

sub failure_output {
    my $self = shift;
    my $handles = $self->io_set('legacy');
    ($handles->[FAIL]) = $self->_new_fh($_[0]) if @_;
    return $handles->[FAIL];
}

sub todo_output {
    my $self = shift;
    my $handles = $self->io_set('legacy');
    ($handles->[TODO]) = $self->_new_fh($_[0]) if @_;
    return $handles->[TODO];
}

sub _diag_fh {
    my $self = shift;
    my ($in_todo) = @_;

    return $in_todo ? $self->todo_output : $self->failure_output;
}

sub _print {
    my $self = shift;
    my ($indent, @msgs) = @_;
    return $self->_print_to_fh( $self->output, $indent, @msgs );
}

sub current_test {
    my $self = shift;

    if (@_) {
        my ($new) = @_;
        $self->atomic_event(sub { $self->{number} = $new });
    }

    return $self->{number};
}

########################
# }}} Legacy Support
########################

###############
# {{{ UTILS
###############

sub _print_to_fh {
    my( $self, $fh, $indent, @msgs ) = @_;

    # Prevent printing headers when only compiling.  Mostly for when
    # tests are deparsed with B::Deparse
    return if $^C;

    my $msg = join '', @msgs;

    local( $\, $", $, ) = ( undef, ' ', '' );

    $msg =~ s/^/$indent/mg;

    return print $fh $msg;
}

sub open_handles {
    my $self = shift;

    open( my $out, ">&STDOUT" ) or die "Can't dup STDOUT:  $!";
    open( my $err, ">&STDERR" ) or die "Can't dup STDERR:  $!";

    _autoflush($out);
    _autoflush($err);

    return ($out, $err);
}

sub atomic_event {
    my $self = shift;
    my ($code) = @_;
    lock $self->{lock};
    $code->();
}

sub _autoflush {
    my($fh) = shift;
    my $old_fh = select $fh;
    $| = 1;
    select $old_fh;

    return;
}

sub _copy_io_layers {
    my($src, $dst) = @_;

    try {
        require PerlIO;
        my @src_layers = PerlIO::get_layers($src);
        _apply_layers($dst, @src_layers) if @src_layers;
    };

    return;
}

sub _new_fh {
    my $self = shift;
    my($file_or_fh) = shift;

    return $file_or_fh if $self->is_fh($file_or_fh);

    my $fh;
    if( ref $file_or_fh eq 'SCALAR' ) {
        open $fh, ">>", $file_or_fh
          or croak("Can't open scalar ref $file_or_fh: $!");
    }
    else {
        open $fh, ">", $file_or_fh
          or croak("Can't open test output log $file_or_fh: $!");
        _autoflush($fh);
    }

    return $fh;
}

sub is_fh {
    my $self     = shift;
    my $maybe_fh = shift;
    return 0 unless defined $maybe_fh;

    return 1 if ref $maybe_fh  eq 'GLOB';    # its a glob ref
    return 1 if ref \$maybe_fh eq 'GLOB';    # its a glob

    my $out;
    protect {
        $out = eval { $maybe_fh->isa("IO::Handle") }
            || eval { tied($maybe_fh)->can('TIEHANDLE') };
    };

    return $out;
}


###############
# }}} UTILS
###############

1;

__END__

=head1 NAME

Test::Builder::Formatter::TAP - TAP formatter.

=head1 TEST COMPONENT MAP

  [Test Script] > [Test Tool] > [Test::Builder] > [Test::Bulder::Stream] > [Event Formatter]
                                                                                   ^
                                                                             You are here

A test script uses a test tool such as L<Test::More>, which uses Test::Builder
to produce events. The events are sent to L<Test::Builder::Stream> which then
forwards them on to one or more formatters. The default formatter is
L<Test::Builder::Fromatter::TAP> which produces TAP output.

=head1 DESCRIPTION

This module is responsible for taking events from the stream and outputting
TAP. You probably should not directly interact with this.

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
